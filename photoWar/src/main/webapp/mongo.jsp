<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.List"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PosPat"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.photegrity.GridData"
%><%@page import="com.purplehillsbooks.photegrity.MongoDB"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="org.bson.Document"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String option = request.getParameter("option");
    String query = request.getParameter("query");

    GridData grid = new GridData();
    if (query!=null && query.length()>0) {
        grid.setQuery(query);
    }
    JSONObject res = grid.getJSON();
    
    
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>MONGO</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">

<h1>Mongo (<%=option%>)</h1>

<button onclick="window.location='mongo.jsp'" class="btn">Refresh</button>
<button onclick="window.location='mongo.jsp?option=1'" class="btn">Update Mongo</button>
<button onclick="window.location='mongo.jsp?option=2'" class="btn">One PP</button>
<hr/>

<form  method="get" action="mongo.jsp">
Option: <input type="radio" name="option" value="0"/> Refresh <br/>
Query: <input type="text" name="query" value="<%=query%>"/>
<input type="submit" value="Submit">
</form>


<pre>
<%

    res.write(out, 2, 0);

%>
</pre>
<hr/>

</body>
</HTML>
