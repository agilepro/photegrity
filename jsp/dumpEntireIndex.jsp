<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.UtilityMethods"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
%><%

    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String startStr = request.getParameter("start");

    int start = 0;
    if (startStr!=null) {
        start = UtilityMethods.safeConvertInt(startStr);
    }
    int stop = start + 40;
    int prev = start - 40;
    if (prev<0) {
        prev=0;
    }

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>JSP Test</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">

<table><tr>
<td><form action="dumpEntireIndex.jsp">
Start: <input name="start" value="<%=start%>">
<input name="go" value="Fetch" type="submit">
</form></td>
<td> &nbsp; </td>
<td><form action="dumpEntireIndex.jsp">
<input name="start" value="<%=prev%>" type="hidden">
<input name="go" value="Prev" type="submit">
</form></td>
<td><form action="dumpEntireIndex.jsp">
<input name="start" value="<%=(stop)%>" type="hidden">
<input name="go" value="Next" type="submit">
</form></td>
</tr></table>
<ul>
<%

    Vector<ImageInfo> vFiles = ImageInfo.getImagesByName();
    int cx=0;
    int count = 0;
    for (ImageInfo ii : vFiles) {

        if (cx++<start) {
            continue;
        }
        if (cx>stop) {
            break;
        }


        out.write("<li>"+(cx)+":");
        HTMLWriter.writeHtml(out, ii.fileName);
        for (TagInfo gi: ii.tagVec) {
            out.write("||");
            HTMLWriter.writeHtml(out, gi.tagName);
        }
        out.write("</li>");
        count++;

    }
%>
</ul>
Found <%=count%> images

</body>
</HTML>
