<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.Thumb" %>
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
    String query = UtilityMethods.reqParam(request, "fillThumbnails.jsp", "q");


    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e = groupImages.elements();

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Create Thumbnails</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=6>
<H1>Create Thumbnails</H1>
</tr>
<tr><td colspan=6>
</tr>
<tr><td colspan=7><img src="bar.jpg"></td></tr>
<tr><td>Query</td><td><%HTMLWriter.writeHtml(out,query);%></td></tr>
<tr><td>Number to create</td><td><%=groupImages.size()%></td></tr>
</table>
<hr><ol><li>0
<%


    int lastNum = 0;
    long totalTime = System.currentTimeMillis();
    long cycleTime = System.currentTimeMillis();

    while (e.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e.nextElement();
        if (ii == null) {
            throw new Exception ("null image file where lastnum="+lastNum);
        }
        lastNum++;
        if (lastNum%100 == 0) {
            long currTime = System.currentTimeMillis();
            long allMillis = (currTime - totalTime)/lastNum - 200;
            long hundredMillis = (currTime - cycleTime)/100 - 200;
            cycleTime = currTime;
            %> <%=hundredMillis%>ms, <%=allMillis%>ms
            <li><%=lastNum%>  <%
        }
        out.write(".");
        Thumb.genThumbNail(ii, 100);
        out.flush();
        Thread.sleep(200);
    }


%>
</ol>
<p><b>All Done</b></p>
<hr>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>