<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.io.Writer" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Arrays" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.TagInfo" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounter" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    int n = UtilityMethods.defParamInt(request, "n", 0);

    String search = request.getParameter("s");
    if (search != null) {
        search = search.toLowerCase();
        int min = 0;
        int max = DiskMgr.masterGroups.size();
        while (max - min > 5) {
            int middle = (max+min)/2;
            String item = (String) DiskMgr.masterGroups.elementAt(middle);
            if (search.compareTo(item) > 0) {
                min = middle;
            }
            else {
                max = middle;
            }
        }
        n = min;
    }
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>All Tags '<%= 8 %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<h1>Master Tags

<a href="masterGroups.jsp?n=<%=n>100?n-100:0%>"><img src="ArrowBack.gif" borderwidth="0"></a>
<%= n %>
<a href="masterGroups.jsp?n=<%=n+100%>"><img src="ArrowFwd.gif" borderwidth="0"></a>
</h1>
<table>
<tr><td>
<a href="main.jsp"><img src="home.gif"></a></td><td>
<form method="get" action="masterGroups.jsp"><input type="text" name="s"><input type="submit" value="Search"></form>
</tr></table>
<ul>
<%
    int last = n+100;
    if (last > DiskMgr.masterGroups.size()) {
        last = DiskMgr.masterGroups.size();
    }
    String alreadyPrinted = "";
    while (n<last) {
        String g = (String) DiskMgr.masterGroups.elementAt(n);
        if (!alreadyPrinted.equals(g)) {
        %>
        <li> <a href="group.jsp?g=<%=URLEncoder.encode(g, "UTF-8")%>"><%=g%></a> .<%
            alreadyPrinted = g;
        }
        else {
            %>.<%
        }
        n++;
    }
%>
</ul>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</body>
</html>