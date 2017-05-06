<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsActionDownloadAll"
%><%@page import="bogus.NewsActionLoadHeaders"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsActionSave"
%><%@page import="bogus.NewsActionSeekBunch"
%><%@page import="bogus.NewsActionDiscard"
%><%@page import="bogus.NewsActionSpectrum"
%><%@page import="bogus.NewsActionFillGaps"
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
%><%@page import="org.workcast.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession newsSession = newsGroup.session;

    String command   = UtilityMethods.reqParam(request, "News Fetch Page", "command");
    String go   = UtilityMethods.defParam(request, "go", "news.jsp");
    String filter = (String) session.getAttribute("filter");
    String sort = UtilityMethods.defParam(request, "sort", "patt");

    if ("SetFilter".equals(command)) {
        String newFilter   = UtilityMethods.defParam(request, "filter", "").trim();
        session.setAttribute("oldFilter", newFilter);
        session.setAttribute("filter", newFilter);
        response.sendRedirect(go);
        return;
    }
    else if ("UnsetFilter".equals(command)) {
        session.setAttribute("filter", "");
        response.sendRedirect(go);
        return;
    }
    else if ("Set Window Size".equals(command)) {
        String newMax   = UtilityMethods.defParam(request, "window", "100000");
        long newWindowSize = UtilityMethods.safeConvertLong(newMax);
        if (newWindowSize<10000) {
            newWindowSize = 10000;
        }
        if (newWindowSize>1000000) {
            newWindowSize = 1000000;
        }
        newsGroup.displayWindow = newWindowSize;
        response.sendRedirect(go);
        return;
    }
    else if ("Close".equals(command)) {
        newsGroup.closeNewsGroupFile();
        response.sendRedirect(go);
        return;
    }
    else if ("Save".equals(command)) {
        newsGroup.saveCache();
        response.sendRedirect(go);
        return;
    }
    else if ("Scheduled Save".equals(command)) {
        NewsActionSave nas = new NewsActionSave();
        nas.addToFrontOfHigh();
        out.write("OK, save command will be completed momentarily");
        return;
    }
    else if ("Load".equals(command)) {
        Vector<File> files = DiskMgr.getNewsFiles();
        File firstFile = files.get(0);
        String newsFile = UtilityMethods.reqParam(request, "News Fetch Page", "newsFile");
        boolean connect = UtilityMethods.defParam(request, "connect", null)!=null;
        File parentFile = new File(newsFile);
        if (!parentFile.exists()) {
            throw new Exception("The news file path is not valid!:  "+parentFile);
        }
        File aFile = new File(parentFile, "news.properties");
        if (!aFile.exists()) {
            throw new Exception("The news properties file does not exist!:  "+aFile);
        }

        newsGroup.openNewsGroupFile(aFile, connect);
        response.sendRedirect(go);
        return;
    }
    else if ("Recalc Stats".equals(command)) {
        newsGroup.recalcStats();
        int count = 0;
        for (NewsBunch tPatt: NewsBunch.filterThese(newsGroup.getBunchesInRange(), filter)) {
            if (tPatt.hasTemplate()) {
                tPatt.getFiles();
            }
            if (count++ > 300) {
                break;
            }
        }
        out.write("OK, recalculating stats for the visible range");
        return;
    }
    else if ("Discard Articles".equals(command)) {
        int earlyLimit = UtilityMethods.defParamInt(request,  "earlyLimit", 0);
        NewsActionDiscard nad = new NewsActionDiscard(0,earlyLimit);
        nad.addToFrontOfLow();
        response.sendRedirect(go);
        return;
    }
    else if ("Refetch".equals(command)) {
        int startInt = UtilityMethods.defParamInt(request, "start", -1000);
        int countInt = UtilityMethods.defParamInt(request,  "count", 100);
        int stepInt = UtilityMethods.defParamInt(request,  "step", 1);
        NewsActionLoadHeaders nadh = new NewsActionLoadHeaders(startInt, countInt, stepInt);
        nadh.addToFrontOfMid();
        out.write("OK, got a request to fetch "+countInt+" more records starting at "+startInt+" and stepping by "+stepInt);
        out.flush();
        //response.sendRedirect(go);
        return;
    }
    else if ("FillGaps".equals(command)) {
        long start = UtilityMethods.defParamLong(request, "start", -1000);
        long end = UtilityMethods.defParamLong(request,  "end", 100);
        int gap = UtilityMethods.defParamInt(request,  "gap", 1);
        NewsActionFillGaps nadh = new NewsActionFillGaps(start, end, gap);
        nadh.addToFrontOfMid();
        out.write("OK, got a request to fill gaps larger than "+gap+" starting at "+start+" and endind by "+end);
        out.flush();
        //response.sendRedirect(go);
        return;
    }
    else if ("UnError".equals(command)) {
        int startInt = UtilityMethods.defParamInt(request, "start", -1000);
        int countInt = UtilityMethods.defParamInt(request,  "count", 100);
        int stepInt = UtilityMethods.defParamInt(request,  "step", 1);
        int endInt = startInt + (countInt*stepInt);
        NewsActionLoadHeaders nadh = new NewsActionLoadHeaders(startInt, countInt, stepInt);
        while (startInt<=endInt) {
            newsGroup.clearError(startInt);
            startInt += stepInt;
        }
        nadh.addToFrontOfMid();
        response.sendRedirect(go);
        return;
    }%>

<html>
<body>
<%
    try {
        if (command.startsWith("Batch Operation")) {
%>
    <h3>Batch Operation</h3>
    <p><a href="news.jsp">News</a></p>
    <%
        String batchop = UtilityMethods.reqParam(request, "News Fetch Page", "batchop");
        boolean isHide = ("hide".equals(batchop));
        boolean isComplete = ("complete".equals(batchop));
        boolean isSeek = ("seek".equals(batchop));
        boolean isDownload = ("download".equals(batchop));
        boolean isStore = ("store".equals(batchop));
        String filePath = UtilityMethods.reqParam(request, "News Fetch Page", "filePath");
        List<NewsBunch> allPatts = NewsGroup.getUnhiddenBunches();
        if (filter!=null && filter.length()>0) {
            List<NewsBunch> filteredPatterns = new Vector<NewsBunch>();
            for (NewsBunch tpatt : allPatts) {
                if (tpatt.minId>newsGroup.lowestToDisplay+newsGroup.displayWindow) {
                    continue;
                }
                if (tpatt.digest.indexOf(filter)>=0) {
                    filteredPatterns.add(tpatt);
                }
            }
            if (filteredPatterns.size()>0) {
                allPatts = filteredPatterns;
            }
        }
        for (NewsBunch npatt : allPatts) {

            out.write("\n<br/>");
            out.flush();
            String tokPattern = npatt.tokenFill();
            HTMLWriter.writeHtml(out,tokPattern);
            out.write(" - ");
            if (isHide) {
                npatt.pState = NewsBunch.STATE_HIDDEN;
                out.write(" HIDE ");
            }
            if (isComplete) {
                npatt.pState = NewsBunch.STATE_COMPLETE;
                out.write(" COMPLETE ");
            }
            if (isSeek) {
                if (npatt.pState != NewsBunch.STATE_SEEK_DONE &&
                    npatt.pState != NewsBunch.STATE_SEEK  &&
                    npatt.pState != NewsBunch.STATE_DOWNLOAD) {
                    npatt.pState = NewsBunch.STATE_SEEK;
                    NewsActionSeekBunch nasp = new NewsActionSeekBunch(npatt);
                    nasp.addToFrontOfMid();
                    out.write(" SEEK ");
                }
                else {
                    out.write(" already seeked ");
                }
            }
            if (isDownload) {
                if (npatt.pState != NewsBunch.STATE_DOWNLOAD_DONE &&
                    npatt.pState != NewsBunch.STATE_DOWNLOAD) {
                    npatt.pState = NewsBunch.STATE_DOWNLOAD;
                    NewsActionDownloadAll nasp = new NewsActionDownloadAll(npatt);
                    nasp.addToFrontOfLow();
                    out.write(" DOWNLOAD ");
                }
                else {
                    out.write(" already downloading ");
                }
            }
            if (isStore) {
                if (filePath.equals(npatt.getFolderLoc())) {
                    out.write(" skipped (already there) ");
                }
                else {
                    npatt.changeFolder(filePath, true);
                    out.write(" path saved: "+filePath);
                }
                String temp = npatt.getTemplate();
                npatt.changeTemplate(temp,false);
                if (true) {
                    out.write(" NAME SET ");
                }
                else {
                    out.write(" can't find name");
                }
            }
        }

    }
    else {
    %>Unknown command <%=command%><%
        }
    }
    catch (Exception e) {
%>
<H1>Error</H1>
<h2>
Exception: <% HTMLWriter.writeHtml(out,e.toString()); %>
</h2>
<hr>
<a href="main.jsp"><img src="home.gif"></a>
<a href="config.jsp">Config</a>
<pre>
<% out.flush(); %>
<% e.printStackTrace(new PrintWriter(out)); %>
</pre>
<%

    }
%>
<hr/>
<p><a href="news.jsp">News</a></p>
</body>
</html>


