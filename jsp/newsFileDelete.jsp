<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsActionDownloadAll"
%><%@page import="bogus.NewsActionDownloadFile"
%><%@page import="bogus.NewsActionSeekBunch"
%><%@page import="bogus.NewsActionSeekABit"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String fn       = UtilityMethods.reqParam(request, "News File Delete", "fn");
    String dig      = UtilityMethods.reqParam(request, "News File Delete", "dig");
    String go       = UtilityMethods.reqParam(request, "News File Delete", "go");

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsBunch bunch = newsGroup.getBunch(dig);
    String folder = bunch.getFolderLoc();
    boolean folderExists = bunch.hasFolder();
    File   folderPath = bunch.getFolderPath();
    if (folderExists) {
        File filePath = new File(folderPath, fn);
        if (filePath.exists()) {
            filePath.delete();
        }
    }

%>
<html><body>
<p>Now ....  return (or click <a href="<%=go%>">here</a>)</p>
<script>
    setTimeout(goFarFarAway, 0010);

    function goFarFarAway() {
        window.location.assign("<%=go%>");
    }
</script>
</body></html>
