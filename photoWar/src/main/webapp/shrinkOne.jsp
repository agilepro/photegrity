<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.Thumb"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileWriter"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String sPath = UtilityMethods.reqParam(request, "shrinkOne.jsp", "p");
    String go = UtilityMethods.reqParam(request, "shrinkOne.jsp", "go");
    String sFileName = UtilityMethods.reqParam(request, "shrinkOne.jsp", "fn");
    File fullPath = new File(sPath);

    ImageInfo ii = ImageInfo.genFromFile(fullPath);

    if (ii == null) {
        throw new Exception ("cant find an image at path: "+sPath);
    }
    if (!ii.fileName.equalsIgnoreCase(sFileName)) {
        throw new Exception ("Found an image, but file name ("+ii.fileName+") does not match ("+sFileName+")");
    }
    if (!ii.getFilePath().getAbsolutePath().equalsIgnoreCase(sPath)) {
        throw new Exception ("Found an image, but path ("+ii.getFilePath().getAbsolutePath()+") does not match ("+sPath+")");
    }

    Thumb.shrinkFile(ii);
    response.sendRedirect(go);
%>
