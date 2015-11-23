package bogus;

import java.util.Vector;
import java.util.ResourceBundle;
import java.util.Locale;
import java.util.Arrays;

/**
 * TException is a base exception that that implements language independence as
 * well as parameters and chaining.
 */
public class TException extends Exception {

    private static final long serialVersionUID = 1L;

    /**
     * The property key used to access the Resource bundle to get the human
     * readable articulation of this exception.
     */
    protected String propertyKey;

    /**
     * The name of the resource bundle. The resource bundle "scopes" the
     * property key: all property keys need to be unique within a bundle, but
     * different bundles are independent. If the program / development situation
     * is such that you can use a single bundle then this name will be
     * sufficient. If you need multiple resource bundles, then make a subclass
     * that sets this bundle name.
     */
    protected String bundleName = "ErrorMessages";

    /**
     * List of parameters that will be included in the error message
     */
    protected Vector<String> params = new Vector<String>();

    /**
     * Constructs a TException for the given property key.
     *
     * @param propertyKey
     *            The property key to get the human readable text from the
     *            resource bundle.
     */
    public TException(String key, Throwable cause, String[] paramArray) {
        super(cause);
        propertyKey = key;
        params.addAll(Arrays.asList(paramArray));
    }

    /******************************************************************
     * + Access to the fields and properties of a ModelException
     *****************************************************************/
    /**
     * The property key is a unique identifier for this exception. It is used to
     * locate the corresponding template value in the resource bundle.
     *
     * @return The resource key
     */
    public String getPropertyKey() {
        return propertyKey;
    }

    /**
     * Returns all the parameter values.
     *
     * @return The list of parameters associated with this exception.
     * @publish internal
     */
    public Vector<String> getParams() {
        return params;
    }

    /**
     * Sets the message parameter that is indicated by 'index' to be the value
     * of the string 'data'.
     *
     * @param index
     *            The number of the message parameter to set. This value can be
     *            any positive integer, but remember that large values will
     *            cause the string array to be large, so typically this will be
     *            from 0 to 5 or 6.
     * @param data
     *            The string data that will be substituted into the message
     */
    public void setParam(int index, String data) {
        params.set(index, data);
    }

    /**
     * Sets the message parameters.
     *
     * @param newParams
     *            The vector of parameters that will be used within the error
     *            message.
     * @publish internal
     */
    public void setParams(Vector<String> newParams) {
        params = newParams;
    }

    /**
     * Returns the parameter value specified.
     *
     * @param index
     *            The index of the parameter to be returned.
     * @return The parameter indicated by the given index.
     * @publish internal
     */
    public String getParam(int index) {
        return params.get(index);
    }

    /**
     * Return a string representation of this exception in the default locale of
     * the environment where this is running.
     *
     * @return The exception information.
     */
    public String toString() {
        return toString(Locale.getDefault());
    }

    /**
     * Return the human readable representation of this exception. This is the
     * preferred way.
     *
     * @param locale
     *            The Locale to be used for getting the human readable message.
     * @return
     * @publish internal
     */
    public String toString(Locale locale) {
        return fillTemplate(getTemplate(locale), locale);
    }

    /**
     * Returns the human readable text for the property key (or error code) of
     * this exception object.
     *
     * @param locale
     *            The locale to be used to get the human readable text.
     * @return The String representation of the property key
     * @publish internal
     */
    public String getTemplate(Locale locale) {
        ResourceBundle bundle = ResourceBundle.getBundle(bundleName, locale);
        return bundle.getString(propertyKey);
    }

    /**
     * Core of getMessage(). Returns the text form of the message, substituting
     * in the data parameter values into the appropriate places in the specified
     * template. Can be called from subclasses which may provide the template
     * from a source other than the resource bundle.
     *
     * Templates have tokens which are replaced by values. <$0> will be replaced
     * by parameter 0. <$e> will be replaced by the causing exception.
     *
     * @param template
     *            The error message to be displayed that can containe
     *            placeholders for the parameters or causing exception.
     * @param locale
     *            The locale that was used to get the template.
     * @return The String generated from the given template and the parameters
     *         associated with this exception.
     * @publish internal
     */
    protected String fillTemplate(String template, Locale locale) {
        StringBuffer res = new StringBuffer();
        boolean used[] = null;
        if (params != null) {
            used = new boolean[params.size()];
        }
        boolean usedCause = false;

        // Add the template to the result string.
        if (template != null && template.length() > 0) {
            int pos = 0;
            while (pos < template.length()) {
                int newPos = template.indexOf("<$", pos);

                if (newPos < 0) {
                    break;
                }

                res.append(template.substring(pos, newPos));
                pos = newPos + 2;

                newPos = template.indexOf(">", pos);
                if (newPos < 0) {
                    // If this occurs, it is actually a mal-formed
                    // template but in an error message routine, we
                    // need to be fault tolerant, so ignore it.
                    break;
                }

                String token = template.substring(pos, newPos);
                pos = newPos + 1;

                // handle the <$e> token
                if (token.equals("e")) {
                    res.append(getCauseVal(locale));
                    usedCause = true;

                }
                else {
                    int i = Integer.parseInt(token);
                    String paramVal = getParam(i);
                    if (paramVal != null && paramVal.length() > 0) {
                        res.append(paramVal);
                        used[i] = true;

                    }
                    else {
                        res.append("(!)");
                    }
                }
            }

            // bring the 'rest' of the template along
            res.append(template.substring(pos));
        }

        // now check to make sure that all the params are present
        // in the displayed message. Add them to the end if not.
        // Only first 16 are significant.
        if (params != null) {
            int size = params.size();
            for (int i = 0; i < size; i++) {
                if (used[i] == false && getParam(i) != null) {
                    res.append(" (");
                    res.append(getParam(i));
                    res.append(")");
                }
            }
        }

        // check that the <$e> was present if needed, otherwise
        // add the causing message on the end.
        // use curley braces so that this does not get confused with
        // the parentheses used for substitution parameters.
        if (!usedCause && getCause() != null) {
            res.append(" {");
            res.append(getCauseVal(locale));
            res.append("}");
        }

        return res.toString();
    }

    /**
     * TODO: THIS LOOKS BROKEN...no parameters!
     * Gets the cause value as best possible, or return the string "(???)" if it
     * can not be found or cause doesn't exist.
     */
    private String getCauseVal(Locale locale) {
        Throwable cause = getCause();
        if (cause != null) {
            String causeVal = null;
            if (cause instanceof TException) {
                causeVal = ((TException) cause).toString(locale);
            }
            else {
                causeVal = cause.toString();
            }
            if (causeVal != null && causeVal.length() > 0) {
                return causeVal;
            }
        }
        return "(???)";
    }
}
