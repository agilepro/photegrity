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
        %>You must logged in to delete a file<%
        return;
    }

    String fn       = UtilityMethods.defParam(request, "fn", null);
    if (fn==null) {
        %>Need a file name passed as a parameter named 'fn'<%
        return;
    }
    String dig      = UtilityMethods.defParam(request, "dig", null);
    if (dig==null) {
        %>Need a digest passed as a parameter named 'dig'<%
        return;
    }
    String f      = UtilityMethods.defParam(request, "f", null);
    if (f==null) {
        %>Need a from address passed as a parameter named 'f'<%
        return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsBunch bunch = newsGroup.getBunch(dig, f);
    if (bunch==null) {
        %>Unable to find a bunch with that digest value<%
        return;
    }
    NewsFile nf = bunch.getFileByName(fn);
    if (nf==null) {
        %>Unable to find a file with that name in the bunch<%
        return;
    }

    NewsActionDownloadFile nadf = new NewsActionDownloadFile(nf, false);
    nadf.addToFrontOfHigh();

%>
OK, file download requested.
