<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsActionDownloadAll"
%><%@page import="bogus.NewsActionLoadHeaders"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsActionSave"
%><%@page import="bogus.NewsActionSeekBunch"
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
%><%@page import="org.workcast.streams.HTMLWriter"
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

    String command   = UtilityMethods.reqParam(request, "Batch Operations Page", "command");
    String go        = UtilityMethods.defParam(request, "go", "news.jsp");
    String filter    = UtilityMethods.defParam(request, "filter", "");

    String sort = UtilityMethods.defParam(request, "sort", "patt");

    if (!command.startsWith("Batch Operation")) {
        throw new Exception("ONLY WORKS ON BATCH operations");
    }

    String batchop = UtilityMethods.reqParam(request, "Batch Operations Page", "batchop");
    boolean isHide = ("hide".equals(batchop));
    boolean isComplete = ("complete".equals(batchop));
    boolean isSeek = ("seek".equals(batchop));
    boolean isDownload = ("download".equals(batchop));
    boolean isStore = ("store".equals(batchop));
    boolean isNothing = ("nothing".equals(batchop));
    boolean isError = false;

    if (filter.length()==0) {
        throw new Exception("You have to have a filter value ste ... for safety");
    }
    String filePath = UtilityMethods.reqParam(request, "Batch Operations Page", "filePath");
    String checkSize = UtilityMethods.reqParam(request, "Batch Operations Page", "checkSize");
    List<NewsBunch> filteredBunches = filterTheseNoSort(newsGroup, filter);
    if (filteredBunches.size() != Integer.parseInt(checkSize)) {
        isError = true;
    }
%>

<html>
<body>
    <h3>Batch Operation <%=filteredBunches.size()%> records</h3>
    <p><a href="news.jsp">News</a></p>
<%
    try {
        for (NewsBunch npatt : filteredBunches) {

            out.write("\n<br/>");
            out.flush();
            String tokPattern = npatt.tokenFill();
            HTMLWriter.writeHtml(out,tokPattern);
            out.write(" - ");
            if (isError) {
                out.write(" ERROR "+checkSize+" does not equal "+filteredBunches.size());
            }
            else if (isNothing) {
                out.write(" NOTHING ");
            }
            else if (isHide) {
                npatt.pState = NewsBunch.STATE_HIDDEN;
                out.write(" HIDE ");
            }
            else if (isComplete) {
                npatt.pState = NewsBunch.STATE_COMPLETE;
                out.write(" COMPLETE ");
            }
            else if (isSeek) {
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
            else if (isDownload) {
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
            else if (isStore) {
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
<%!//replace with NewsFilter.filterThese when compiled
    public List<NewsBunch> filterTheseNoSort(NewsGroup newsGroup, String filter) throws Exception{
        List<NewsBunch> filteredPatterns = newsGroup.getFilteredBunches(filter);
        return filteredPatterns;
    }

%>

