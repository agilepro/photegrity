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

    String sDiskName = UtilityMethods.reqParam(request, "shrinkOne.jsp", "d");
    String sPath = UtilityMethods.reqParam(request, "shrinkOne.jsp", "p");
    String go = UtilityMethods.reqParam(request, "shrinkOne.jsp", "go");
    String sFileName = UtilityMethods.reqParam(request, "shrinkOne.jsp", "fn");

    DiskMgr dm1 = DiskMgr.getDiskMgr(sDiskName);
    ImageInfo ii = ImageInfo.findImage(sDiskName, sPath, sFileName);

    if (ii == null) {
        throw new Exception ("cant find an image with d="+sDiskName+",  fn="+sFileName);
    }
    if (!ii.fileName.equalsIgnoreCase(sFileName))
    {
        throw new Exception ("Found an image, but file name ("+ii.fileName+") does not match ("+sFileName+")");
    }
    if (!ii.getFullPath().equalsIgnoreCase(sPath))
    {
        throw new Exception ("Found an image, but path ("+ii.getFullPath()+") does not match ("+sPath+")");
    }
    if (!ii.pp.getDiskMgr().diskName.equalsIgnoreCase(sDiskName))
    {
        throw new Exception ("Found an image, but disk name name ("+ii.pp.getDiskMgr().diskName+") does not match ("+sDiskName+")");
    }

    Thumb.shrinkFile(ii);
    response.sendRedirect(go);
%>
