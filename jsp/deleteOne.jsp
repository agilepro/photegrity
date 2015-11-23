<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileWriter"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.UtilityMethods"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String sDiskName = request.getParameter("d");
    if (sDiskName == null) {
        throw new Exception("page needs a 'd' parameter to specify the disk");
    }
    String sPath = request.getParameter("p");
    if (sPath == null) {
        throw new Exception("page needs a 'p' parameter to specify the path");
    }
    String sFileName = request.getParameter("fn");
    if (sFileName == null) {
        throw new Exception("page needs a 'fn' parameter to specify the filename");
    }

    DiskMgr dm1 = DiskMgr.getDiskMgr(sDiskName);
    ImageInfo ii = ImageInfo.findImage(sDiskName, sPath, sFileName);

    if (ii == null) {
        throw new Exception ("cant find an image with d="+sDiskName+",  fn="+sFileName);
    }
    if (ii.fileName.equals(sFileName) &&
        ii.getFullPath().equals(sPath) &&
        ii.diskMgr.diskName.equals(sDiskName)) {
        ii.isTrashed = !ii.isTrashed;
    }
    else {
        throw new Exception ("Found an image, bit it did not match, with d="+sDiskName+",  fn="+sFileName);
    }

    String go = request.getParameter("go");
    if (go == null) {
        go = "selection.jsp?msg=Deleted%201%20File";
    }
    response.sendRedirect(go);
%>
