<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.Stats"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
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
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/plain;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    JSONObject data = new JSONObject();

    if (session.getAttribute("userName") == null) {
        throw new Exception("not logged in");
    }

    JSONArray vecs = new JSONArray();
    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
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
    }
    data.put("zingPat", zingPat);

    String filter = (String) session.getAttribute("filter");
    data.put("filter", filter);

    String oldFilter = (String) session.getAttribute("oldFilter");
    data.put("oldFilter", oldFilter);

    //now, write all the records out to the stream
    data.write(out,2,0);
%>
