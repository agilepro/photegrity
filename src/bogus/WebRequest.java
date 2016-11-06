package bogus;

import java.io.File;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.PrintWriter;
import java.io.StringWriter;
import java.io.Writer;
import java.net.URLDecoder;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.json.JSONTokener;
import org.workcast.streams.StreamHelper;

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

            JSONObject responseBody = convertExceptionToJSON(e);
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





    public static JSONObject convertExceptionToJSON(Exception e) throws Exception {
        JSONObject responseBody = new JSONObject();
        JSONObject errorTag = new JSONObject();
        responseBody.put("error", errorTag);

        errorTag.put("code", 400);

        JSONArray detailList = new JSONArray();
        errorTag.put("details", detailList);

        String lastMessage = "";
        Throwable runner = e;
        while (runner!=null) {
            String className =  runner.getClass().getName();
            String msg =  runner.toString();

            //iflow has this annoying habit of including all the later causes in the response
            //surrounded by braces.  This strips them off because we are going to iterate down
            //to those causes anyway.
            boolean isIFlow = className.indexOf("iflow")>0;
            if (isIFlow) {
                int bracePos = msg.indexOf('{');
                if (bracePos>0) {
                    msg = msg.substring(0,bracePos);
                }
            }

            if (msg.startsWith(className)) {
                int skipTo = className.length();
                while (skipTo<msg.length()) {
                    char ch = msg.charAt(skipTo);
                    if (ch != ':' && ch != ' ') {
                        break;
                    }
                    skipTo++;
                }
                msg = msg.substring(skipTo);
            }

            runner = runner.getCause();
            if (lastMessage.equals(msg)) {
                //model api has an incredibly stupid pattern of catching an exception, and then throwing a
                //new exception with the exact same message.  This ends up in three or four duplicate messages.
                //Check here for that problem, and eliminate duplicate messages by skipping rest of loop.
                continue;
            }
            lastMessage = msg;

            JSONObject detailObj = new JSONObject();
            detailObj.put("message",msg);
            int dotPos = className.lastIndexOf(".");
            if (dotPos>0) {
                className = className.substring(dotPos+1);
            }
            detailObj.put("code",className);
            System.out.println("          ERR: "+msg);
            detailList.put(detailObj);
        }

        JSONObject innerError = new JSONObject();
        errorTag.put("innerError", innerError);

        JSONArray stackList = new JSONArray();
        runner = e;
        while (runner != null) {
            for (StackTraceElement ste : runner.getStackTrace()) {
                String line = ste.getFileName() + ":" + ste.getMethodName() + ":" + ste.getLineNumber();
                stackList.put(line);
            }
            stackList.put("----------------");
            runner = runner.getCause();
        }
        errorTag.put("stack", stackList);

        StringWriter sw = new StringWriter();
        e.printStackTrace(new PrintWriter(sw));
        List<String> nicerStack = prettifyStack(sw.toString());
        for (String onePart : nicerStack) {
            stackList.put(onePart);
        }
        return responseBody;
    }

    private static List<String> prettifyStack(String input) {
        ArrayList<String> res = new ArrayList<String>();
        int start = 0;
        int pos = input.indexOf('\r');
        while (pos>0) {
            String line = input.substring(start, pos).trim();
            int parenPos = line.indexOf('(');
            if (parenPos>0 && parenPos<line.length()) {
                String fullMethod = line.substring(0,parenPos);
                int methodPoint = fullMethod.lastIndexOf('.');
                if (methodPoint>0 && methodPoint<fullMethod.length()) {
                    res.add(fullMethod.substring(methodPoint+1)+line.substring(parenPos));
                }
                else {
                    res.add(line);
                }
            }
            else {
                res.add(line);
            }
            start = pos+1;
            pos = input.indexOf('\r', start);
        }
        return res;
    }

}
