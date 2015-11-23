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
<%@page import="bogus.NewsActionFixDisk"%>
<%@page import="bogus.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String diskName = request.getParameter("disk");
    if (diskName == null) {
        throw new Exception("Page loaddisk.jsp requires a parameter 'n' to specify the disk to load");
    }
    DiskMgr mgr = DiskMgr.getDiskMgr(diskName);
    if (mgr==null) {
        throw new Exception("Can not find a disk with the name: "+diskName);
    }
    String relPath = request.getParameter("relPath");
    File fullPath = mgr.getFilePath(relPath);
    String go = request.getParameter("go");

    NewsActionFixDisk nafd = new NewsActionFixDisk(mgr, fullPath);
    nafd.addToFrontOfHigh();

    response.sendRedirect(go);
%>
