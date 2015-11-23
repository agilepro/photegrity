<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" session="true"
%><%@page errorPage="Exception.jsp"
%><%@page import="java.io.File"
%><%@page import="java.util.List"
%><%@page import="java.util.Properties"
%><%@page import="bogus.LoginAttemptRecord"
%><%@page import="bogus.UtilityMethods"
%><%
    request.setCharacterEncoding("UTF-8");

    session.setAttribute("userName", null);
    session.setAttribute("password", null);
    response.sendRedirect("main.jsp");

%>
