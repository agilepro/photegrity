<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsActionDownloadAll"
%><%@page import="bogus.NewsActionLoadHeaders"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsActionSave"
%><%@page import="bogus.NewsActionSeekBunch"
%><%@page import="bogus.NewsActionSeekABit"
%><%@page import="bogus.NewsActionSpectrum"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBackground"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.Stats"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONException"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String command = UtilityMethods.reqParam(request, "Batch Operations Page", "command");

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession newsSession = newsGroup.session;

    JSONObject results = new JSONObject();
    JSONArray rows = new JSONArray();
    results.put("rows", rows);
    try {
        if ("toggleCompress".equals(command)) {
            newsGroup.defaultUncompressed = !newsGroup.defaultUncompressed;
        }
        else if ("togglePartial".equals(command)) {
            newsGroup.downloadPartialFiles = !newsGroup.downloadPartialFiles;
        }
        else {
            throw new Exception("don't undersatnd command: "+command);
        }
        results = newsGroup.newsInfoJSON();
    }
    catch (Exception e) {
        response.setStatus(500);
        results = JSONException.convertToJSON(e, "listBunces"); 
    }
    results.write(out, 2, 0);
%>