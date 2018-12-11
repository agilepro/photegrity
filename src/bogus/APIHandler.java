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

import java.io.File;
import java.io.InputStream;
import java.net.URLDecoder;
import java.util.Vector;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.purplehillsbooks.json.JSONArray;
import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;


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
            if ("batchUpdate".equals(mainGroup)) {
                return doBatchUpdate(objIn);
            }
			if (mainGroup.startsWith("b=")) {
				return handleBunches(mainGroup.substring(2));
			}
			throw new JSONException("Don't understand GET request for %s", mainGroup);
		}
		catch (Exception e) {
			throw new JSONException("Unable to handle request for %s", e, req.getRequestURL().toString());
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
			throw new JSONException("For some reason the requestURI (%s) does not start with the contextPath (%s)",requestURI,contextPath);
		}
		int pos = requestURI.indexOf(servletPath);
		if (pos!=contextPath.length()) {
			throw new JSONException("For some reason the servletPath (%s) does not appear in the requestURI (%s) in the right place", servletPath, requestURI);
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
	    	throw new JSONException("Unable to find a news bunch with the key: %s",bunchKey);
	    }
	    
	    if (isPost) {
	    	bunch.updateFromJSON(objIn);
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
	
	public JSONObject doBatchUpdate(JSONObject objIn) throws Exception {
	    JSONObject res = new JSONObject();
	    JSONArray listIn = objIn.getJSONArray("list");
	    JSONArray outList = new JSONArray();
	    res.put("list",outList);
	    File sourceToClean = null;
        File destToClean = null;
        DiskMgr sourceDM = null;
        DiskMgr destDM = null;
        int counter = 1;
	    
	    for (int i=0; i<listIn.length();i++) {
	        JSONObject op = listIn.getJSONObject(i);
	        JSONObject resInts = new JSONObject();
	        resInts.put("num", i);
	        resInts.put("src", op);
	        try {
    	        String cmd   = op.getString("cmd");
    	        String disk  = op.getString("disk");
    	        String path  = op.getString("path");
    	        String fn    = op.getString("fn");
    	        DiskMgr dm = DiskMgr.getDiskMgr(disk);
	            File sourceFolder = dm.getFilePath(path);
    	        if ("del".equals(cmd)) {
    	            dm.suppressFile(sourceFolder, fn);
    	            resInts.put("del", "success");
    	            sourceToClean = sourceFolder;
    	            sourceDM = dm;
    	            System.out.println("BATCH: deleted "+fn);
    	        }
    	        else if ("move".equals(cmd)) {
    	            File sourceFilePath = new File(sourceFolder, fn);
    	            if (!sourceFilePath.exists()) {
    	                throw new JSONException ("Source file does not exist at %s", sourceFilePath.toString());
    	            }
    	            String tempFileName = "TMP"+System.currentTimeMillis()+"-"+(counter++)+".jpg";
                    String disk2  = op.getString("disk2");
                    DiskMgr dm2 = DiskMgr.getDiskMgr(disk2);
                    
    	            ImageInfo ii = new ImageInfo(sourceFilePath, dm);
    	            
                    String path2  = op.getString("path2");
                    String fn2    = op.getString("fn2");
    	            File destFolder = dm.getFilePath(path2);
    	            File destFilePath = new File(destFolder, fn2);
                    if (destFilePath.exists()) {
                        throw new JSONException ("Dest file exists before move %s",destFilePath.toString());
                    }
                    if (!destFolder.equals(sourceFolder)) {
                        ii.renameFile(tempFileName);
                        ii.moveImage(dm2, destFolder);
                    }
    	            ii.renameFile(fn2);
                    if (!destFilePath.exists()) {
                        throw new JSONException ("Dest file does NOT exist after move %s", destFilePath.toString());
                    }
    	            resInts.put("move", "success");

                    sourceToClean = sourceFolder;
                    sourceDM = dm;
    	            destToClean = destFolder;
    	            destDM = dm2;
                    System.out.println("BATCH: moved "+fn+ " to " + fn2);
    	        }
    	        else {
    	            throw new JSONException("Do not understand operation: %s",cmd);
    	        }
	        }
	        catch (Exception e) {
	            resInts.put("error", JSONException.convertToJSON(e, "can't process "+i));
	            System.out.println("BATCH: error "+e.toString());
	        }
	        outList.put(resInts);
	    }
	    
	    if (sourceToClean!=null && sourceDM!=null) {
	        sourceDM.refreshDiskFolder(sourceToClean);
	        res.put("clean1", sourceToClean.toString());
	    }
        if (destToClean!=null && destDM!=null) {
            destDM.refreshDiskFolder(destToClean);
            res.put("clean2", destToClean.toString());
        }
	    return res;
	}
}
