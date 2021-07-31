<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="java.util.regex.Pattern" %>
<%@page import="java.util.regex.Matcher" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.TagInfo" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
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

    String query = UtilityMethods.reqParam(request, "replName.jsp", "q");
    if (query == null) {
        query="s(1)";
    }

    String dest = UtilityMethods.reqParam(request, "replName.jsp", "dest");

    boolean isTest  = UtilityMethods.defParam(request, "test",  "no").equals("yes");

    Vector copyImages = new Vector();
    copyImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e2 = copyImages.elements();
    int count = 0;
    int num = 1;
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Trimming Patterns</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Trimming Patterns</H1>
<p>Testing: <%if (isTest) {out.write("yes - nothing will be changed");} else {out.write("no");}%></p>
<ul>


<%
    while (e2.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e2.nextElement();
        String pattern = ii.getPattern();
        String trimmed = pattern.trim();
        if (pattern.length() == trimmed.length()) {
            continue;
        }

        out.write("\n<li>");
        HTMLWriter.writeHtml(out,ii.fileName);
        out.write(" --- ");
        if (!isTest) {
            ii.changePattern(trimmed);
        }
        HTMLWriter.writeHtml(out,ii.fileName);
        out.write("</li>");
        out.flush();
    }

%>
</ul>
</body>
</html>