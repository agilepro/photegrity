package com.purplehillsbooks.photegrity;

import java.io.Writer;
import java.net.URLEncoder;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;

import org.w3c.dom.Document;
import org.w3c.dom.Element;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.streams.HTMLWriter;

/**
* This is a base class for an object which could be a wikitable row
* It is a flexivle self describing object which can be easily used
* to mae a web interface.
*/
public class WebObject
{
    public WebTable table;

    Hashtable<String, String> fields = new Hashtable<String, String>();

    String key = null;

    public WebObject(WebTable tableDef) {
        table = tableDef;
    }

    /**
    * Implemented by subclasses to create the XML serialization
    */
    public void makeXML(Document d, Element parent)
    {
    }

    /**
    * Implemented by subclasses to parse the XML serialization
    */
    public static WebObject parseXML_WO(Element ele)
        throws Exception
    {
        return null;
    }

    public String getFieldValue(String fieldName)
    {
        return fields.get(fieldName);
    }


    public String getKeyValue()
    {
        return key;
    }

    public void generateKeyValue()
    {
        String newVal = null;
        for (WebColumn wc : table.getSchema()) {
            if (wc.isKey) {
                if (newVal==null) {
                    newVal = getFieldValue(wc.colName);
                }
                else {
                    newVal = newVal + ":" + getFieldValue(wc.colName);
                }
            }
        }
        key = newVal;
    }

    public void setFieldValue(String fieldName, String value)
    {
        if (value==null) {
            fields.remove(fieldName);
        }
        else {

            fields.put(fieldName, table.compressString(value));
        }
        generateKeyValue();
    }


    // removes the value from the oldName, and sets the value
    // to the new name.  If both fields already existed, then
    // the value from the old field overwrites the value that
    // was there before.
    public void changeColumnName(String oldName, WebColumn newName)
    {
        String val = getFieldValue(oldName);
        setFieldValue(oldName, null);
        setFieldValue(newName.colName, val);
    }


    public void setFieldFromXML(Element parent, String fieldName)
    {
        String val = DOMUtils.textValueOf(parent, fieldName, false);
        if (val!=null) {
            setFieldValue(fieldName, val);
        }
    }

    public void setAllFieldsFromXML(Element parent)
    {
        for (WebColumn wc : table.colOrder) {
            setFieldFromXML(parent, wc.colName);
        }
    }


    public void createXMLFromField(Document d, Element parent, String fieldName) throws Exception {
        try {
            String val = getFieldValue(fieldName);
            if (val!=null) {
                DOMUtils.createChildElement(d, parent, fieldName, val);
            }
        }
        catch (Exception e) {
            throw new JSONException("Unable to create XPL for the field '{0}' on object with key={1}", e, fieldName, key);
        }
    }

    public void createXMLAllFields(Document d, Element parent) throws Exception {
        for (WebColumn wc : table.colOrder) {
            createXMLFromField(d, parent, wc.colName);
        }
    }


    //--------------

    //try not to use this
    public void writeHTML(Writer out, String fieldName)
        throws Exception
    {
        WebColumn wc = table.getColumn(fieldName);

        //column does not exist, so just return null
        if (wc==null) {
            return;
        }
        writeHTML(out,wc);
    }

    //this is preferred one
    public void writeHTML(Writer out, WebColumn wc)
        throws Exception
    {
        String val = getFieldValue(wc.colName);
        if (val==null) {
            return;
        }
        HTMLWriter.writeHtmlWithLines(out, val);
    }

    public void writeURLEncoded(Writer out, String fieldName)
        throws Exception
    {
        String val = getFieldValue(fieldName);
        if (val!=null) {
            HTMLWriter.writeHtml(out, URLEncoder.encode(val, "UTF-8"));
        }
    }


    //-------


    public boolean keyEquals(String compValue)
        throws Exception
    {
        if (compValue==null) {
            throw new JSONException("Program logic error.  Attempt to find an object with a null key value.");
        }
        if (key==null) {
            return false;  //there is no key
        }
        return compValue.equalsIgnoreCase(key);
    }

    public boolean fieldEquals(String fieldName, String compValue)
        throws Exception
    {
        if (compValue==null) {
            throw new JSONException("Program logic error.  Attempt to compare field {0} with a null value.", fieldName);
        }
        return compValue.equalsIgnoreCase(getFieldValue(fieldName));
    }

    public int fieldCompare(String fieldName, String compValue)
        throws Exception
    {
        if (compValue==null) {
            throw new JSONException("Program logic error.  Attempt to compare field {0} with a null value.", fieldName);
        }
        return compValue.compareToIgnoreCase(getFieldValue(fieldName));
    }

    static class OrderByField implements Comparator<WebObject>
    {
        String sortField;

        public OrderByField(String fieldName) {
            sortField = fieldName;
        }

        public int compare(WebObject o1, WebObject o2)
        {
            String val1 = o1.getFieldValue(sortField);
            String val2 = o2.getFieldValue(sortField);
            if (val1==null) {
                if (val2==null) {
                    return 0;
                }
                else {
                    return -1;
                }
            }
            return val1.compareToIgnoreCase(val2);
        }
    }

}
