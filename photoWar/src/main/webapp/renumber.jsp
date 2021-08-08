<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
<%@page import="java.util.Set" %>
<%@page import="java.util.HashSet" %>
<%@page import="java.util.List" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="com.purplehillsbooks.streams.HTMLWriter" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String pageName = "renumberSelection.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    // must make  a copy because the move and suppress commands
    // cause elements to be removed frrom the original vector
    String newName = UtilityMethods.reqParam(request, pageName, "newName");
    
    String dest = request.getParameter("dest");

    String query = UtilityMethods.reqParam(request, pageName, "q");

    List<ImageInfo> copyImages = ImageInfo.imageQuery(query);
    //ImageInfo.sortImages(copyImages, "num");
    int count = 0;
    int num = 1;
    Set<File> locCleanup = new HashSet<File>();
    for (ImageInfo ii : copyImages) {
        locCleanup.add(ii.pp.getFolderPath());
        // rename it here
        if (ii.value<=0) {
            //preserve the old value for these files
            ii.nextName(newName, ii.value);
            continue;
        }
        count ++;
        num = ii.nextName(newName, num);
    }
    for (File loc : locCleanup) {
        DiskMgr.refreshDiskFolder(loc);
    }


    if (dest == null) {
        dest = "show.jsp?q="+URLEncoder.encode(query);
    }
    response.sendRedirect(dest);
%>
