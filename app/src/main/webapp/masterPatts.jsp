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
<%@page import="java.util.List" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.TagInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PosPat" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounter" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    int pageLength = 30;
    int colNum = 3;
    int maxEntries = pageLength*colNum;

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    List<PosPat> allPatts = PosPat.getAllEntries();
    int listMax = allPatts.size();

    int n = UtilityMethods.defParamInt(request, "n", 0);

    String search = request.getParameter("s");
    if (search != null) {
        int min = 0;
        int max = listMax;
        while (max - min > 1) {
            int middle = (max+min)/2;
            String item = allPatts.get(middle).getPattern();
            if (search.compareToIgnoreCase(item) > 0) {
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
<HEAD><TITLE>Master Patterns '<%= n %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<h1>Master Patterns
<a href="masterPatts.jsp?n=<%=n>maxEntries?n-maxEntries:0%>"><img src="ArrowBack.gif" borderwidth="0"></a>
<%= n %>
<a href="masterPatts.jsp?n=<%=n+maxEntries%>"><img src="ArrowFwd.gif" borderwidth="0"></a>
<a href="pattern3.jsp">dups</a>
</h1>
<table>
<tr><td>
<a href="main.jsp"><img src="home.gif"></a></td><td>
<form method="get" action="masterPatts.jsp"><input type="text" name="s"><input type="submit" value="Search"></form>

</tr></table>
<table><tr>
<%
    int last = n+maxEntries;
    if (last > allPatts.size()) {
        last = allPatts.size();
    }
    String alreadyPrinted = "";
    while (n<last) {
        int innerlast = n+pageLength;
        %><td><ul><%
        while (n<innerlast && n<listMax) {
            String g = (String) allPatts.get(n).getPattern();
            if (!alreadyPrinted.equals(g)) {
            %>
            <li> <a href="pattern2.jsp?g=<%=URLEncoder.encode(g,"UTF8")%>"><%=g%></a></li><%
                alreadyPrinted = g;
            }
            else {
                %><li>.</li><%
            }
            n++;
        }
        %></ul></td><%
    }
    long duration = System.currentTimeMillis() - starttime;
%>
</tr></table>

    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</body>
</html>
