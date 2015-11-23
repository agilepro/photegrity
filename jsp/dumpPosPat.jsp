<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.UtilityMethods"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    if (DiskMgr.archivePaths == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String startStr = request.getParameter("start");

    int start = 0;
    if (startStr!=null) {
        start = UtilityMethods.safeConvertInt(startStr);
    }
    int stop = start + 30;
    int prev = start - 30;
    if (prev<0) {
        prev=0;
    }
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>JSP Test</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">

<table><tr>
<td><a href="main.jsp"><img src="home.gif" border="0"></a></td>
<td><form action="dumpPosPat.jsp">
Start: <input name="start" value="<%=start%>">
<input name="go" value="Fetch" type="submit">
</form></td>
<td> &nbsp; </td>
<td><form action="dumpPosPat.jsp">
<input name="start" value="<%=prev%>" type="hidden">
<input name="go" value="Prev" type="submit">
</form></td>
<td><form action="dumpPosPat.jsp">
<input name="start" value="<%=(stop)%>" type="hidden">
<input name="go" value="Next" type="submit">
</form></td>
</tr></table>
<table>
<%

    Vector<PosPat> vFiles = PosPat.getAllEntries();
    int cx=-1;
    int count = 0;
    String lastPat = "zyzy";
    for (PosPat pp : vFiles) {
        cx++;
        if (cx<start) {
            continue;
        }
        if (cx>stop) {
            break;
        }

        String thisPat = pp.getPattern();

        out.write("<tr><td>"+(cx)+" &nbsp; </td><td>");
        if (pp.getDiskMgr().isLoaded) {
            out.write("*");
        }
        out.write("</td><td>");
        HTMLWriter.writeHtml(out, pp.getDiskMgr().diskName);
        out.write(":");
        HTMLWriter.writeHtml(out, pp.getLocalPath());
        out.write("</td><td>");
        out.write("<a href=\"pattern2.jsp?g=");
        UtilityMethods.writeURLEncoded(out, thisPat);
        out.write("\">");
        HTMLWriter.writeHtml(out, thisPat);
        out.write("</a> ");
        if (lastPat.equals(thisPat)) {
            out.write("  <font color=\"red\">(D)</font>");
        }
        out.write("</td><td>");
        for (String gi: pp.getTags()) {
            HTMLWriter.writeHtml(out, gi);
            out.write(", ");
        }
        out.write("</td><td>"+pp.getImageCount());
        lastPat = thisPat;
        out.write("</td></tr>");
        count++;
    }
%>
</table>
Found <%=count%> position patterns

</body>
</HTML>
