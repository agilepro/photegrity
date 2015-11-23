<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.UtilityMethods"
%><%@page import="org.workcast.streams.HTMLWriter"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.getImagesByName());
    Enumeration e = groupImages.elements();

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Clearing out Trashcan</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=6>
<H1>Clearing out Trashcan</H1>
</tr>
<tr><td colspan=6>
</tr>
<tr><td colspan=7><img src="bar.jpg"></td></tr>
</table>
<hr><ul>
<%

    int lastNum = 0;

    while (e.hasMoreElements())
    {
        ImageInfo ii = (ImageInfo)e.nextElement();
        if (ii == null)
        {
            throw new Exception ("null image file where lastnum="+lastNum);
        }
        if (!ii.isTrashed)
        {
            continue;
        }
        if (ii.isTrashed)
        {
            out.write("\n<li> ");
            HTMLWriter.writeHtml(out, ii.getFilePath().toString());
            out.flush();
            if (ii.isNullImage()) {
                out.write("NULL");
            }
            else {
                ii.suppressImage();
            }
        }
    }

%>
<li><b>Trashcan Cleared</b>
</ul><hr>
<a href="main.jsp"><img src="home.gif"></a>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>