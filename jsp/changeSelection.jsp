<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String query = request.getParameter("q");
    if (query == null) {
        query="s(1)";
    }
    String oldPatt = request.getParameter("p1");
    if (oldPatt == null) {
        throw new Exception("page needs a 'p1' parameter to specify the old pattern to change from");
    }
    String newPatt = request.getParameter("p2");
    if (newPatt == null) {
        throw new Exception("page needs a 'p2' parameter to specify the new pattern to change to");
    }
    String dest = request.getParameter("dest");
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Change Patterns in Selection</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=6>
<h1>Change Patterns in Selection</h1>
</tr>
<tr><td colspan=6>
</tr>
<tr><td colspan=7><img src="bar.jpg"></td></tr>
<tr><td>Query</td><td><% HTMLWriter.writeHtml(out,query); %></td></tr>
<tr><td>From Pattern</td><td><% HTMLWriter.writeHtml(out,oldPatt); %></td></tr>
<tr><td>To Pattern</td><td><% HTMLWriter.writeHtml(out,newPatt); %></td></tr>
</table>
<hr><ul>
<%

    // must make  a copy because the move and suppress commands
    // cause elements to be removed from the original vector
    Vector copyImages = new Vector();
    copyImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e2 = copyImages.elements();
    while (e2.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e2.nextElement();
        if (ii == null) {
            throw new Exception ("null image file ");
        }
        if (ii.getPattern().equalsIgnoreCase(oldPatt)) {
            out.write("\n<li>");
            HTMLWriter.writeHtml(out,ii.getFilePath().toString());
            ii.changePattern(newPatt);
            out.write(" --&gt; ");
            HTMLWriter.writeHtml(out,ii.fileName);
        }
        else {
            out.write("\n<li><i>ignoring ");
            HTMLWriter.writeHtml(out,ii.fileName);
            out.write("</i>");
        }

    }

%>
<li><b>All Done</b>
</ul><hr>
<a href="main.jsp"><img src="home.gif"></a>
</BODY>
</HTML>