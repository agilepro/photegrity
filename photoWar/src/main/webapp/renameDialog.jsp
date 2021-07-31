<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounter" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>
<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String fileName = request.getParameter("fn");
    if (fileName == null) {
        throw new Exception("parameter 'fn' must be set to the name of the file to change.");
    }
    String diskName = request.getParameter("d");
    if (diskName == null) {
        throw new Exception("parameter 'd' must be set to the name of the disk of the file.");
    }
    String path = request.getParameter("p");
    if (path == null) {
        throw new Exception("parameter 'p' must be set to the path of the file.");
    }
    diskName = diskName.toLowerCase();
    Vector tagVec = (Vector) session.getAttribute("tagVec");
    if (tagVec==null) {
        tagVec = new Vector();
    }
    int vecSize = tagVec.size();
%>
<HTML>
<HEAD><TITLE>Rename File '<%= fileName %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<h1>Rename '<%= fileName %>'</h1>
<form method="get" action="renameFile.jsp">
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
NewName: <input type="text" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="submit" value="Rename">
</form>
<form method="get" action="insertGroup.jsp">
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
AddGroup: <input type="text" name="newGroup" value="">
<input type="submit" value="Insert Tag">
</form>
<form method="get" action="insertGroup.jsp">
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<% for (int i=0; i<vecSize; i++) { %>
<input type="submit" name="newGroup" value="<%HTMLWriter.writeHtml(out, (String)tagVec.elementAt(i));%>">
<% } %>
</form>
</p>
<img src="bar.jpg"><br>
<a href="main.jsp"><img src="home.gif"></a>
<hr>
Disk: <%= diskName %><br>
Path: <%= path %><br>
Name: <%= fileName %><br>
</BODY>
</HTML>