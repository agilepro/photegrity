/*
 * Copyright 2015 Keith D Swenson
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package bogus;

import java.io.InputStream;
import java.net.URLDecoder;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;


/**
 * This servlet serves up resources using the following URL format:
 *
 * http://{machine:port}/{application}/api/{space}/{resource params}
 *
 * http://{machine:port}/{application} is whatever you install the application to on
 * Tomcat could be multiple levels deep.
 *
 * "api" is fixed. This is the indicator within the system that says
 * this servlet will be invoked.
 * 
 * Specific spaces:
 * 
 * http://{machine:port}/{application}/api/session/
 * This is a persistent set of values that control what the user is 
 * seeing and working on.  It persists with the login session, and is 
 * discarded on logout.  Session values can be retrieved 
 * with a GET, and updated with a POST.
 *
 */
public class APIHandler {
	private HttpServletRequest req;
	@SuppressWarnings("unused")
	private HttpServletResponse resp;
	HttpSession session;
	String userName;
	private String method;
	private String[] path;
	JSONObject objIn;
	boolean isPost = false;
	
	public APIHandler(HttpServletRequest _req, HttpServletResponse _resp, String _userName) {
		req = _req;
		resp = _resp;
		userName = _userName;
		method = req.getMethod();
		session = req.getSession();
	}
	
	public JSONObject handleRequest() throws Exception {
		try {
			path = parseFullUrl(req);
			
		    //debug
		    StringBuffer debugValue = new StringBuffer();
		    for (String pv : path) {
		    	debugValue.append("\"" + pv + "\", ");
		    }
		    System.out.println("receivedPath   = "+debugValue.toString());
		    System.out.println("getContextPath = "+req.getContextPath());
		    System.out.println("getQueryString = "+req.getQueryString());
		    System.out.println("getRequestURI  = "+req.getRequestURI() );
		    System.out.println("getRequestURL  = "+req.getRequestURL() );
		    System.out.println("getServletPath = "+req.getServletPath());
			
		    isPost = "POST".equalsIgnoreCase(method);
		    if (isPost) {
		        InputStream is = req.getInputStream();
		        JSONTokener jt = new JSONTokener(is);
		        objIn = new JSONObject(jt);
		        is.close();
		    }
			if (path.length < 1) {
				throw new Exception("can not understand that request ... path not long enough.");
			}
			String mainGroup = path[0];
			
			if ("session".equals(mainGroup)) {
				if (!isPost) {
					return getSessionJSON(req);
				}
				else {
					return setSessionFromJSON();
				}
			}
			if (mainGroup.startsWith("b=")) {
				return handleBunches(mainGroup.substring(2));
			}
			throw new Exception("Don't understand GET request for "+mainGroup);
		}
		catch (Exception e) {
			throw new Exception("Unable to handle request for "+req.getRequestURL(), e);
		}
	}
	
		
	//does not include
	public static String getFullURL(HttpServletRequest request) {
	    String requestURL = request.getServletPath();
	    String queryString = request.getQueryString();

	    if (queryString == null) {
	        return requestURL;
	    } else {
	        return requestURL+"?"+queryString;
	    }
	}
	
	/**
	 * The point of this is to parse the request URL into an array of strings
	 * that can then be tested.  Given an URL like:
	 * 
	 *   /foo/bar/page.htm?g=good&b=bad
	 *   
	 * You will get the following array:
	 * 
	 *   { "foo", "bar", "page.htm", "g=good", "b=bad" }
	 *   
	 * What those mean is up to the logic of the resource identifier
	 */
	public static String[] parseFullUrl(HttpServletRequest req) throws Exception {
		String contextPath = req.getContextPath();
		String servletPath = req.getServletPath();
		String requestURI = req.getRequestURI();

		//some internal consistency checks
		if (!requestURI.startsWith(contextPath)) {
			throw new Exception("For some reason the requestURI ("+requestURI+") does not start with the contextPath ("+contextPath+")");
		}
		int pos = requestURI.indexOf(servletPath);
		if (pos!=contextPath.length()) {
			throw new Exception("For some reason the servletPath ("+servletPath+") does not appear in the requestURI ("+requestURI+") in the right place");
		}
		String pathAfterContext = requestURI.substring(contextPath.length() + servletPath.length() + 1);
		
		Vector<String> res = new Vector<String>();
		for (String val : pathAfterContext.split("/")) {
			res.add(URLDecoder.decode(val, "UTF-8"));
		}
		String qString = req.getQueryString();
		if (qString != null) {
			for (String val : qString.split("&")) {
				res.add(URLDecoder.decode(val, "UTF-8"));
			}
		}
		
		return res.toArray(new String[0]);
	}
	
	public static String[] parseNameValue(String qParam) throws Exception {
		int pos = qParam.indexOf("=");
		if (pos<=0) {
			throw new Exception("name value seems to be improperly formed, no equals symbol between name and value");			
		}
		String[] ret = new String[2];
		ret[0] = qParam.substring(0,pos);
		ret[1] = qParam.substring(pos+1);
		return ret;
	}
	
	
	public static JSONObject getSessionJSON(HttpServletRequest req) throws Exception {
		HttpSession session = req.getSession();
		JSONObject data = new JSONObject();

	    JSONArray vecs = new JSONArray();
	    @SuppressWarnings("unchecked")
		Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
	    if (destVec==null) {
	    	destVec = new Vector<String>();
	    	session.setAttribute("destVec", destVec);
	    }
	    for (String vec : destVec) {
	        vecs.put(vec);
	    }
	    data.put("destVec", vecs);

	    String zingFolder = "";
	    if (destVec!=null && destVec.size()>0) {
	        zingFolder = destVec.get(0);
	    }
	    data.put("zingFolder", zingFolder);

	    String zingPat = (String) session.getAttribute("zingpat");
	    if (zingPat==null) {
	        zingPat="";
	        session.setAttribute("zingpat", zingPat);
	    }
	    data.put("zingPat", zingPat);

	    String filter = (String) session.getAttribute("filter");
	    if (filter==null) {
	    	filter="";
	        session.setAttribute("filter", filter);
	    }
	    data.put("filter", filter);

	    String oldFilter = (String) session.getAttribute("oldFilter");
	    if (oldFilter==null) {
	    	oldFilter="";
	        session.setAttribute("oldFilter", oldFilter);
	    }
	    data.put("oldFilter", oldFilter);

	    String maxFlag = (String) session.getAttribute("maxFlag");
	    if (maxFlag==null || maxFlag.length()==0) {
	        maxFlag = "no";
	        session.setAttribute("maxFlag", "no");
	    }
	    boolean useMax = ("yes".equals(maxFlag));
	    data.put("useMax", useMax);
	    
	    data.put("userName", session.getAttribute("userName"));
	    data.put("actionCount", NewsAction.getActionCount());
	    return data;
	}
	
	private JSONObject setSessionFromJSON() throws Exception {

		@SuppressWarnings("unchecked")
		Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
	    if (destVec==null) {
	    	destVec = new Vector<String>();
	    	session.setAttribute("destVec", destVec);
	    }
	    
	    String zingFolder = objIn.optString("zingFolder");
	    if (zingFolder!=null) {
	    	System.out.println("Got a zingFolder value: "+zingFolder);
	    	//first remove the folder if it exists later in the vector
	    	for (int i=0; i<destVec.size(); i++) {
	    		if (destVec.elementAt(i).equals(zingFolder)) {
	    			destVec.remove(i);
	    			break;
	    		}
	    	}
	    	destVec.add(0, zingFolder);
	    }

	    String zingPat = objIn.optString("zingPat");
	    if (zingPat!=null) {
	    	System.out.println("Got a zingPat value: "+zingPat);
	        session.setAttribute("zingpat", zingPat);
	    }

	    String filter = objIn.optString("filter");
	    if (filter!=null) {
	        session.setAttribute("filter", filter);
	    }

	    String oldFilter = objIn.optString("oldFilter");
	    if (oldFilter!=null) {
	        session.setAttribute("oldFilter", oldFilter);
	    }

	    if (objIn.has("maxFlag")) {
	    	//ask for the boolean only when something exists to check
	    	if (objIn.getBoolean("maxFlag")) {
	    		session.setAttribute("maxFlag", "yes");
	    	}
	    	else {
	    		session.setAttribute("maxFlag", "no");
	    	}
	    }
	    
	    return getSessionJSON(req);
	}
	
	private JSONObject handleBunches(String bunchKey) throws Exception {
	    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
	    NewsBunch bunch = newsGroup.findBunchByKey(Long.parseLong(bunchKey));
	    
	    if (bunch==null) {
	    	throw new Exception("Unable to find a news bunch with the key: "+bunchKey);
	    }
	    
	    if (isPost) {
	    	int newState = objIn.getInt("state");
	    	bunch.changeState(newState);
	    }
	    return bunch.getJSON();
	}
	
	public static String hexDecoder(String val) {
		StringBuffer sb = new StringBuffer(val.length()/2);
		for (int i=0; i<val.length(); i++) {
			int ch1 = (int) val.charAt(i) - 'A';
			i++;
			int ch2 = (int) val.charAt(i) - 'A';
			sb.append( (char)( ch1*16  + ch2 ) );
		}
		return sb.toString();
	}
}
