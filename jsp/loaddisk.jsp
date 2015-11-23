<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileOutputStream" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.io.PrintWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.NewsActionLoadDisk"%>
<%@page import="bogus.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String diskName = request.getParameter("n");
    if (diskName == null) {
        throw new Exception("Page loaddisk.jsp requires a parameter 'n' to specify the disk to load");
    }
    diskName = diskName.toLowerCase();
    String dest = request.getParameter("dest");
    if (dest == null) {
        dest = "diskinfo.jsp?n="+diskName;
    }
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Loading '<%= diskName %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Loading '<%= diskName %>'</H1>

<%
    boolean allOk = false;
    out.flush();
    try {
        DiskMgr mgr = DiskMgr.getDiskMgr(diskName);
        NewsActionLoadDisk nald = new NewsActionLoadDisk(mgr);
        nald.addToFrontOfHigh();
        allOk = true;
    }
    catch (Exception e) {
        %><h3>got an exception</h3>
        <pre><%
        e.printStackTrace(new PrintWriter(out));
        %></pre><%
    }

%>
<hr>
<a href="main.jsp"><img src="home.gif"></a> &nbsp;
<a href="diskinfo.jsp?n=<%=diskName%>">Info</a> &nbsp;
<%  if (allOk) { %>
<script language="javascript">
    document.location = "<%=dest%>";
</script>
<%
    }
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>
