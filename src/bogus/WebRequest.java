package bogus;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.Writer;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.Date;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.json.JSONTokener;
import com.purplehillsbooks.streams.StreamHelper;

public class WebRequest {
    public HttpServletRequest  request;
    public HttpServletResponse response;
    public HttpSession         session;
    public OutputStream        outStream;
    public Writer              w;
    public String              requestURL;
    private ArrayList<String>  path;
    private int pathPos = 0;

    public WebRequest (HttpServletRequest _req, HttpServletResponse _resp) throws Exception {
        request = _req;
        response = _resp;
        session = request.getSession();
        setUpForCrossBrowser();
        parsePath();
        outStream = response.getOutputStream();
        w = new OutputStreamWriter(outStream, "UTF-8");
    }

    private void setUpForCrossBrowser() {
        //this is an API to be read by others, so you have to set the CORS to
        //allow scripts to read this data from a browser.
        String origin = request.getHeader("Origin");
        if (origin==null || origin.length()==0) {
            //this does not always work, but what else can we do?
            origin="*";
        }
        response.setHeader("Access-Control-Allow-Origin",      origin);
        response.setHeader("Access-Control-Allow-Credentials", "true");
        response.setHeader("Access-Control-Allow-Methods",     "GET, POST, OPTIONS");
        response.setHeader("Access-Control-Allow-Headers",     "Origin, X-Requested-With, Content-Type, Accept, Authorization");
        response.setHeader("Access-Control-Max-Age",           "1");
        response.setHeader("Vary",                             "*");

        //default content type is JSON  set it otherwise if you need something different
        response.setContentType("application/json; charset=utf-8");
    }

    /**
     * This is the base URL for the application, which means it has
     * the protocol, server, port, and application name in the path.
     * Everything up to the root of where the application is.
     */
    public String appBaseUrl() {
        int amtToTrim = request.getServletPath().length() + request.getPathInfo().length();
        String appBase = requestURL.substring(0, requestURL.length()-amtToTrim);
        return appBase;
    }

    private void parsePath() throws Exception {
        String ctxtroot = request.getContextPath();
        requestURL = request.getRequestURL().toString();
        int indx = requestURL.indexOf(ctxtroot);
        int start = indx + ctxtroot.length() + 1;

        ArrayList<String> decoded = new ArrayList<String>();
        int pos = requestURL.indexOf("/", start);
        while (pos>=start) {
            addIfNotNull(decoded, requestURL, start, pos);
            start = pos + 1;
            pos = requestURL.indexOf("/", start);
        }
        addIfNotNull(decoded, requestURL, start, requestURL.length());
        path = decoded;
    }

    public String consumePathToken() {
        return path.get(pathPos++);
    }
    public boolean pathFinished() {
        return pathPos >= path.size();
    }

    private void addIfNotNull(ArrayList<String> dest, String source, int start, int pos) throws Exception {
        if (pos<=start) {
            return;
        }
        String token = source.substring(start, pos).trim();
        if (token.length()>0) {
            dest.add(URLDecoder.decode(token, "UTF-8"));
        }
    }

    public boolean isGet() {
        return "get".equalsIgnoreCase(request.getMethod());
    }
    public boolean isPost() {
        return "post".equalsIgnoreCase(request.getMethod());
    }
    public boolean isPut() {
        return "put".equalsIgnoreCase(request.getMethod());
    }
    public boolean isDelete() {
        return "delete".equalsIgnoreCase(request.getMethod());
    }
    public boolean isOptions() {
        return "options".equalsIgnoreCase(request.getMethod());
    }

    public JSONObject getPostedObject() throws Exception {
        InputStream is = request.getInputStream();
        JSONTokener jt = new JSONTokener(is);
        JSONObject objIn = new JSONObject(jt);
        is.close();
        return objIn;
    }

    /**
     * Reads the uploaded PUT body, and stores it to the specified
     * file (using a temp name, and deleting whatever file migth
     * have been there before.)
     */
    public void storeContentsToFile(File destination) throws Exception {
        InputStream is = request.getInputStream();
        StreamHelper.copyStreamToFile(is, destination);
    }

    public void streamJSON(JSONObject jo) throws Exception {
        jo.write(w,2,0);
        w.flush();
    }

    public void streamException(Exception e) {
        try {
            streamException(e, request, response, w);
        }
        catch (Exception xxx) {
            System.out.println("FATAL EXCEPTION WHILE STRAMING EXCEPTION: "+xxx);
            //we don't really care if we get an exception while writing an exception
        }
    }
    public static void streamException(Exception e, HttpServletRequest request,
            HttpServletResponse response, Writer w) {
        try {

            System.out.println((new Date()).toString());
            System.out.println("BPM_API_ERROR: "+e.toString());
            System.out.println("         PATH: "+request.getRequestURI());
            PrintWriter pw = new PrintWriter(System.out);
            e.printStackTrace(pw);
            pw.flush();

            if (w==null) {
                System.out.println("PROGRAM LOGIC ERROR: a null writer object was passed into streamException!!!!");
                throw new Exception("a null writer object was passed into streamException");
            }

            JSONObject responseBody = JSONException.convertToJSON(e, request.getRequestURI());
            response.setContentType("application/json");
            response.setStatus(400);
            responseBody.write(w, 2, 0);
            w.flush();
        } catch (Exception eeeee) {
            // nothing we can do here...
            System.out.println("EXCEPTION_WITHIN_EXCEPTION: "+eeeee);
            eeeee.printStackTrace();
        }
    }

}
