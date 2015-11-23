<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsActionDownloadOne"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();


    String artno     = UtilityMethods.reqParam(request, "News One Page", "artno");
    String go        = UtilityMethods.defParam(request, "go", "newsOne.jsp?artno="+artno);

    long artnoLong = Long.parseLong(artno);
    NewsArticle art = (NewsArticle) newsGroup.getArticleOrNull(artnoLong);

    if (art==null) {
        throw new Exception("newsOneAction can't find the article ("+artno+")?  Or somthing else is wrong.");
    }

    NewsActionDownloadOne nado = new NewsActionDownloadOne(art);
    nado.addToFrontOfHigh();
    response.sendRedirect(go);%>
