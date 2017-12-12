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

    String pageName = "nntp.jsp";

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
        String filter    = UtilityMethods.reqParam(request, "Batch Operations Page", "filter");

        String sort = UtilityMethods.defParam(request, "sort", "patt");

        String batchop = UtilityMethods.reqParam(request, "Batch Operations Page", "batchop");

        String filePath = UtilityMethods.reqParam(request, "Batch Operations Page", "filePath");
        List<NewsBunch> filteredBunches = newsGroup.getFilteredBunches(filter);
        
        for (NewsBunch oneBunch : filteredBunches) {

            String tokPattern = oneBunch.tokenFill();
            if ("clear".equals(batchop)) {
                oneBunch.pState = NewsBunch.STATE_INITIAL;
                rows.put(tokPattern+" cleared");
            }
            else if (oneBunch.pState == NewsBunch.STATE_HIDDEN) {
                rows.put(tokPattern+" is HIDDEN - can not do "+batchop);
            }
            else if ("nothing".equals(batchop)) {
                rows.put(tokPattern+" NOTHING ");
            }
            else if ("hide".equals(batchop)) {
                oneBunch.pState = NewsBunch.STATE_HIDDEN;
                rows.put(tokPattern+" hidden");
            }
            else if ("complete".equals(batchop)) {
                oneBunch.pState = NewsBunch.STATE_COMPLETE;
                rows.put(tokPattern+" completed");
            }
            else if (oneBunch.pState == NewsBunch.STATE_COMPLETE) {
                rows.put(tokPattern+" is COMPLETED - can not do "+batchop);
            }
            else if ("default".equals(batchop)) {
                if (oneBunch.hasFolder()) {
                    rows.put(tokPattern+" skipped");
                }
                else {
                    oneBunch.changeFolder(filePath, true);
                    rows.put(tokPattern+" set path");
                }
                String temp = oneBunch.getTemplate();
                oneBunch.changeTemplate(temp,false);
                if (true) {
                    rows.put(tokPattern+" set name");
                }
                else {
                    rows.put(tokPattern+" could not find name");
                }
            }
            else if ("store".equals(batchop)) {
                if (filePath.equals(oneBunch.getFolderLoc())) {
                    rows.put(tokPattern+" skipped");
                }
                else {
                    oneBunch.changeFolder(filePath, true);
                    rows.put(tokPattern+" set path");
                }
                String temp = oneBunch.getTemplate();
                oneBunch.changeTemplate(temp,false);
                if (true) {
                    rows.put(tokPattern+" set name");
                }
                else {
                    rows.put(tokPattern+" could not find name");
                }
            }
            else if (oneBunch.pState == NewsBunch.STATE_DOWNLOAD_DONE) {
                rows.put(tokPattern+" is DOWNLOADED - can not do "+batchop);
            }
            else if (oneBunch.pState == NewsBunch.STATE_DOWNLOAD) {
                rows.put(tokPattern+" is DOWNLOADING - can not do "+batchop);
            }
            else if ("download".equals(batchop)) {
                oneBunch.pState = NewsBunch.STATE_DOWNLOAD;
                NewsActionDownloadAll nasp = new NewsActionDownloadAll(oneBunch);
                nasp.addToFrontOfLow();
                rows.put(tokPattern+" downloading");
            }
            else if ("seek".equals(batchop)) {
                if (oneBunch.pState != NewsBunch.STATE_SEEK_DONE &&
                    oneBunch.pState != NewsBunch.STATE_SEEK  &&
                    oneBunch.pState != NewsBunch.STATE_DOWNLOAD_DONE  &&
                    oneBunch.pState != NewsBunch.STATE_DOWNLOAD) {
                    oneBunch.pState = NewsBunch.STATE_SEEK;
                    NewsActionSeekBunch nasp = new NewsActionSeekBunch(oneBunch);
                    nasp.addToFrontOfMid();
                    rows.put(tokPattern+" seeking");
                }
                else {
                    rows.put(tokPattern+" skipped");
                }
            }
            else if ("bit".equals(batchop)) {
                if (oneBunch.pState != NewsBunch.STATE_DOWNLOAD_DONE  &&
                    oneBunch.pState != NewsBunch.STATE_DOWNLOAD) {
                    oneBunch.pState = NewsBunch.STATE_GETABIT;
                    NewsActionSeekABit nasp = new NewsActionSeekABit(oneBunch);
                    nasp.addToFrontOfMid();
                    rows.put(tokPattern+" get a bit");
                }
                else {
                    rows.put(tokPattern+" skipped");
                }
            }
            else {
                throw new Exception("Don't understand the operation: "+batchop);
            }
        }
    }
    catch (Exception e) {
        response.setStatus(500);
        JSONObject jo = JSONException.convertToJSON(e, "listBunces");
        jo.write(out,2,2);
    }
    results.write(out, 2, 0);
%>

