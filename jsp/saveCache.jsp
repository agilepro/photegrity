<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="bogus.HashCounter" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Save Cache</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Save Cache</H1>

<ul>
<%

    //ImageInfo.saveImageInfo();
    Hashtable ht = DiskMgr.getDiskList();
    Enumeration e3 = HashCounter.sort(ht.keys());

    while (e3.hasMoreElements()) {

        String key = (String) e3.nextElement();
        out.write("<li>");
        out.write(key);
        out.flush();
        DiskMgr mgr = (DiskMgr) ht.get(key);
        if (mgr.isChanged && mgr.isLoaded) {
            mgr.writeSummary();
            out.write("  ...  saved to disk.\n");
        }
        else {
            out.write("\n");
        }
    }

%>
</ul>
<hr>
<a href="main.jsp"><img src="home.gif"></a>

</BODY>
</HTML>
