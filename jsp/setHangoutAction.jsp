<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.NewsBunch"
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

    String go        = UtilityMethods.defParam(request, "go", "");

    session.setAttribute("hangOut", go);
    response.sendRedirect(go);
%>
