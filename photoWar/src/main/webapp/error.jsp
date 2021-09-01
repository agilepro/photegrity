<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" 
%><%@page isErrorPage="true" 
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.PrintWriter"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONException"
%>

<%
    request.setCharacterEncoding("UTF-8");

    if (exception == null) {
        exception = new Exception("<<Unknown exception arrived at the error page ... this should never happen. The exception variable was null.>>");
    }
    String msg = exception.toString();
    JSONObject jo = JSONException.convertToJSON(exception, "Error JSP");
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>JSP Test</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Error</H1>
<h2>
Exception: <% HTMLWriter.writeHtml(out,msg); %>
</h2>
<hr>
<a href="main.jsp"><img src="home.gif"></a>
<a href="config.jsp">Config</a>
<pre>
<%=jo.toString(2)%>
</pre>
<hr/>
</BODY>
</HTML>
