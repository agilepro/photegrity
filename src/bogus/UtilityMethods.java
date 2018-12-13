package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.Writer;
import java.net.URLEncoder;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import com.purplehillsbooks.json.JSONException;

public class UtilityMethods {

	public static String subString(String s, int pos, int len) throws Exception {
		try {
			return s.substring(pos, len);
		}
		catch (Exception e) {
			throw new JSONException("Substring exception: [{0}] (len {1}) at {2} for len {3}", e, s, s.length(), pos, len);
		}
	}

	static public String[] splitOnDelimiter(String str, char delim) throws Exception {
		try {
			Vector<String> vec = new Vector<String>();
			int pos = 0;
			int last = str.length();
			while (pos < last) {
				int nextpos = str.indexOf(delim, pos);
				if (nextpos >= pos) {
					vec.add(str.substring(pos, nextpos));
				}
				else {
					vec.add(str.substring(pos));
					break;
				}
				pos = nextpos + 1;
			}
			String[] result = new String[vec.size()];
			for (int i = 0; i < vec.size(); i++) {
				result[i] = vec.elementAt(i);
			}
			return result;
		}
		catch (Exception e) {
			throw new JSONException("Error in splitOnDelimiter", e);
		}
	}

	static public void writeURLEncoded(Writer out, String input) throws Exception {
		out.write(URLEncode(input));
	}

	
	static public String URLEncode(String input) throws Exception {
		String encodedPath = URLEncoder.encode(input, "UTF-8");
		// there appears to be a bug in TomCat that a plus symbol,
		// which is supposed to represent a space character, is not
		// handled correctly, so need to get rid of them.
		// TEMPORARY: until I write a faster conversion that does the whole
		// thing
		// directly to UTF-8
		int plusPos = encodedPath.indexOf("+");
		while (plusPos >= 0) {
			encodedPath = encodedPath.substring(0, plusPos) + "%20"
					+ encodedPath.substring(plusPos + 1);
			plusPos = encodedPath.indexOf("+");
		}
		return encodedPath;
	}

	
	
	public static String goToLogin(HttpServletRequest request) throws Exception {
		StringBuffer s1 = request.getRequestURL();
		s1.append("?");
		s1.append(request.getQueryString());

		String loginUrl = "PasswordPrompt.jsp?go=" + URLEncoder.encode(s1.toString(), "UTF-8");

		return loginUrl;
	}

	public static String reqParam(HttpServletRequest request, String pageName, String paramName)
			throws Exception {
		String val = defParam(request, paramName, null);
		if (val == null || val.length() == 0) {
			throw new JSONException("Page {0} requires a parameter named '{1}'", pageName, paramName);
		}
		return val.trim();
	}

	public static String defParam(HttpServletRequest request, String paramName, String defaultValue)
			throws Exception {
		String val = request.getParameter(paramName);
		if (val == null) {
			return defaultValue;
		}
		// this next line should not be needed, but I have seen this hack
		// recommended
		// in many forums.
		//String modVal = new String(val.getBytes("iso-8859-1"), "UTF-8");
		return val;
	}

	public static int defParamInt(HttpServletRequest request, String paramName, int defaultValue)
			throws Exception {
		String val = defParam(request, paramName, null);
		if (val == null) {
			return defaultValue;
		}
		try {
			return safeConvertInt(val);
		}
		catch (Exception e) {
			return defaultValue;
		}
	}

    public static long defParamLong(HttpServletRequest request, String paramName, long defaultValue)
            throws Exception {
        String val = defParam(request, paramName, null);
        if (val == null) {
            return defaultValue;
        }
        try {
            return safeConvertLong(val);
        }
        catch (Exception e) {
            return defaultValue;
        }
    }

	public static String getSessionString(HttpSession session, String paramName, String defaultValue) {
		String val = (String) session.getAttribute(paramName);
		if (val == null) {
			session.setAttribute(paramName, defaultValue);
			return defaultValue;
		}
		return val;
	}

	public static int getSessionInt(HttpSession session, String paramName, int defaultValue) {
		Integer val = (Integer) session.getAttribute(paramName);
		if (val == null) {
			session.setAttribute(paramName, new Integer(defaultValue));
			return defaultValue;
		}
		return val.intValue();
	}

	public static void setSessionInt(HttpSession session, String paramName, int val) {
		session.setAttribute(paramName, new Integer(val));
	}

	static public int safeConvertInt(String val) {
		int ret = 0;
		boolean isNegative = false;
		for (int i = 0; i < val.length(); i++) {
			char ch = val.charAt(i);
			if (ch >= '0' && ch <= '9') {
				ret = ret * 10 + ch - '0';
			}
			else if (ch == '-') {
				isNegative = true;
			}
		}
		if (isNegative) {
			return -1 * ret;
		}
		else {
			return ret;
		}
	}

    static public long safeConvertLong(String val) {
        long ret = 0;
        boolean isNegative = false;
        for (int i = 0; i < val.length(); i++) {
            char ch = val.charAt(i);
            if (ch >= '0' && ch <= '9') {
                ret = ret * 10 + ch - '0';
            }
            else if (ch == '-') {
                isNegative = true;
            }
        }
        if (isNegative) {
            return -1 * ret;
        }
        else {
            return ret;
        }
    }
    
    public static String getErrorString(Throwable e) {
    	Throwable t = e.getCause();
    	if (t==null) {
    		return e.toString();
    	}
    	StringBuffer sb = new StringBuffer(e.toString());
    	while (t!=null) {
    		sb.append(" | ");
    		sb.append(t.toString());
    		t = t.getCause();
    	}
    	return sb.toString();
    }
    
    /**
     * Copy the file contents from a file (that must exist) to a new
     * file path (that must not previously exist).
     */
    public static void copyFileContents(File oldFilePath, File newFilePath) throws Exception {
    	try {
	    	if (!oldFilePath.exists()) {
	    		throw new JSONException("The source file does not exist: {0}",oldFilePath);
	    	}
	    	if (newFilePath.exists()) {
	    		throw new JSONException("The destination file already exists: {0}",newFilePath);
	    	}
	        FileInputStream fis = new FileInputStream(oldFilePath);
	        FileOutputStream fos = new FileOutputStream(newFilePath);
	        byte[] buff = new byte[8192];
	        int amt = fis.read(buff);
	        while (amt > 0) {
	            fos.write(buff, 0, amt);
	            amt = fis.read(buff);
	        }
	        fis.close();
	        fos.close();
    	}
    	catch (Exception e) {
    		throw new JSONException("Can not copy file {0} to {1}", e, oldFilePath, newFilePath);
    	}
    }
    
}
