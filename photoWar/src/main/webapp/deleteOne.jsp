<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileWriter"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
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
    String localPath = request.getParameter("p");
    if (localPath == null) {
        throw new Exception("page needs a 'p' parameter to specify the path");
    }
    String sFileName = request.getParameter("fn");
    if (sFileName == null) {
        throw new Exception("page needs a 'fn' parameter to specify the filename");
    }

    DiskMgr dm1 = DiskMgr.getDiskMgr(sDiskName);
    File containingPath = dm1.getFilePath(localPath);
    if (!containingPath.exists()) {
        throw new Exception("The containing folder does not exist: "+containingPath);
    }
    File fullPath = new File(containingPath, sFileName);
    if (!fullPath.exists()) {
        throw new Exception("The file path does not exist: "+fullPath);
    }
    
    ImageInfo ii = ImageInfo.genFromFile(fullPath);

    if (ii == null) {
        throw new Exception ("cant find an image with d="+sDiskName+",  fn="+sFileName);
    }
    ii.toggleTrashImage();

    String go = request.getParameter("go");
    if (go == null) {
        go = "selection.jsp?msg=Deleted%201%20File";
    }
    response.sendRedirect(go);
%>
