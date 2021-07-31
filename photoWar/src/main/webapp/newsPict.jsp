<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.OutputStreamWriter"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("image/jpeg");
    long starttime = System.currentTimeMillis();
    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    MemFile mf = new MemFile();

    OutputStream os = mf.getOutputStream();
    //OutputStream os = response.getOutputStream();
    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession ns = newsGroup.session;

    String artno     = UtilityMethods.reqParam(request, "News One Page", "artno");

    long artnoInt = Long.parseLong(artno);
    NewsArticle art = (NewsArticle) newsGroup.getArticleOrNull(artnoInt);
    if (art!=null)
    {
        art.streamDecodedContent(os);

        //if we make it here, then no exceptions to report, NOW stream the real file out
        OutputStream os2 = response.getOutputStream();
        mf.outToOutputStream(os2);
    }
%>
