<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStreamReader"
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
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONTokener"
%><%@page import="com.purplehillsbooks.streams.MemFile"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "jsonTest.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }


%>
<html>
<body>
<h3>JSON Test</h3>
<p><a href="news.jsp">News</a> | <a href="main.jsp">Main</a> | <a href="jsonTest.jsp">JSON Test</a></p>
<hr/>


<%
    JSONTokener jt = new JSONTokener("{\"JSON\": \"Hello, World\"}");
    JSONObject jo = new JSONObject(jt);
%>
    <pre>
<%jo.write(out, 2, 0);%>
</pre>
<%
    jo = new JSONObject();
    JSONObject jo2 = new JSONObject();
    JSONArray ja = new JSONArray();
    ja.put("first");
    ja.put("second");
    ja.put("third");
    jo2.put("A", "New A Value");
    jo2.put("B", ja);
    jo2.put("C", "New C Value");
    jo.put("obj1", jo2);
    jo.put("obj2", jo2);

    MemFile mf = new MemFile();
    Writer w = mf.getWriter();
    jo.write(w, 2, 0);
    w.flush();
%>
<h2>From MemFile</h2>
<pre>
<%mf.outToWriter(out);%>
</pre>
<%
    Reader r = mf.getReader();
    JSONObject jo3 = new JSONObject(new JSONTokener(r));


%>
<pre>
<%jo3.write(out, 2, 0);%>
</pre>

<%

%>



</body>
</html>
