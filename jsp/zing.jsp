<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.GridData"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();


    String pat = request.getParameter("pat");
    session.setAttribute("zingpat", pat);
    String go = request.getParameter("go");

    response.sendRedirect(go);

%>
