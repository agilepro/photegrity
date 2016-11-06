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

import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;

/**
 * This servlet serves up pages using the following URL format:
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
@SuppressWarnings("serial")
public class APIServlet extends javax.servlet.http.HttpServlet {

	
    @Override
    public void service(HttpServletRequest req, HttpServletResponse resp) {
        System.out.println("API: ("+req.getMethod()+") "+req.getRequestURL());
        Writer w = null;
        try {
            w = resp.getWriter();
        	setHeaders(req,resp);
        	
	    	//first establish whether there is a login session in force
	    	HttpSession session = req.getSession();
	    	String userName = (String) session.getAttribute("userName");
	        if (userName == null) {
	        	//we just throw up hands ... no provision to log in in the API level
	            JSONObject errorResp = new JSONObject();
	            errorResp.put("msg",  "User not logged in");
	            resp.setStatus(401);
	            errorResp.write(resp.getWriter());
	            return;
	        }
	        
            DiskMgr.assertInitialized();

            APIHandler hand = new APIHandler(req, resp, userName);
            JSONObject data = hand.handleRequest();
            
            data.write(w, 2, 0);
            w.flush();
            w.close();
            System.out.println("     ("+req.getMethod()+") COMPLETED "+req.getRequestURL());
        }
        catch (Exception e) {
            System.out.println("     ("+req.getMethod()+") ERROR "+req.getRequestURL());
            if (w!=null) {
                WebRequest.streamException(e, req, resp, w);
            }
        }
        finally {
            //cleanup if needed
        }
    }



    @Override
    public void init(ServletConfig config) throws ServletException {
        //don't initialize here.  Instead, initialize in SpringServlet!
    }

    
    private void setHeaders(HttpServletRequest req, HttpServletResponse resp) {
    	resp.setCharacterEncoding("UTF-8");
    	resp.setContentType("application/json");
    	
        //this is an API to be read by others, so you have to set the CORS to
        //allow scripts to read this data from a browser.
        String origin = req.getHeader("Origin");
        if (origin==null || origin.length()==0) {
            System.out.println("COG-LAuth: got a null origin header???");
            //this does not always work, but what else can we do?
            origin="*";
        }
        resp.setHeader("Access-Control-Allow-Origin",      origin);
        resp.setHeader("Access-Control-Allow-Credentials", "true");
        resp.setHeader("Access-Control-Allow-Methods",     "GET, POST, OPTIONS");
        resp.setHeader("Access-Control-Allow-Headers",     "Origin, X-Requested-With, Content-Type, Accept, Authorization");
        resp.setHeader("Access-Control-Max-Age",           "1");
        resp.setHeader("Vary",                             "*");
    	
    }
    
    private void streamException(Exception e, HttpServletRequest req, HttpServletResponse resp) {
        try {
            //all exceptions are delayed by 3 seconds to avoid attempts to
            //mine for valid license numbers
            Thread.sleep(3000);

            System.out.println("API_ERROR: "+req.getRequestURL());

            e.printStackTrace();

            JSONObject errorResponse = new JSONObject();
            errorResponse.put("responseCode", 500);
            JSONObject exception = new JSONObject();
            errorResponse.put("exception", exception);

            JSONArray msgs = new JSONArray();
            Throwable runner = e;
            while (runner!=null) {
                System.out.println("    ERROR: "+runner.toString());
                msgs.put(runner.toString());
                runner = runner.getCause();
            }
            exception.put("msgs", msgs);

            StringWriter sw = new StringWriter();
            e.printStackTrace(new PrintWriter(sw));
            exception.put("stack", sw.toString());

            resp.setContentType("application/json");
            resp.setStatus(500);
            Writer w = resp.getWriter();
            errorResponse.write(w, 2, 0);
            w.flush();
            w.close();
        } catch (Exception eeeee) {
            // nothing we can do here...
        	System.out.print("\nCRITIAL ERROR WHILE HANDLING AN EXCEPTION - stack trace below\n");
        	eeeee.printStackTrace();
        }
    }

}
