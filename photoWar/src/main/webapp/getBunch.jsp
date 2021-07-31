<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsFile"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsAction"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.PosPat"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.Stats"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="java.util.Stack"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/plain;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "getBunch.jsp";

    try {
        if (session.getAttribute("userName") == null) {
            throw new Exception("not logged in");
        }

        NewsGroup newsGroup = NewsGroup.getCurrentGroup();
        if (newsGroup==null) {
            throw new Exception("newsgroup is not loaded for some unknown reason.");
        }

        String dig  = UtilityMethods.reqParam(request, "News Detail Action", "dig");
        String f  = UtilityMethods.reqParam(request, "News Detail Action", "f");
        NewsBunch bunch = newsGroup.getBunch(dig.trim(), f);
        if (bunch==null) {
            throw new Exception("Can't find a bunch for digest ("+dig+")");
        }

        JSONObject bunchJson = bunch.getJSON();
        bunchJson.put("seekExtent", bunch.seekExtent);
        //now, write all the records out to the stream
        bunchJson.write(out,2,0);
    }
    catch (Exception e) {
        response.setStatus(401);
        JSONObject jo = JSONException.convertToJSON(e, "listBunces"); 
        jo.write(out,2,2);
    }
%>