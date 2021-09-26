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
    String sPath = request.getParameter("p");
    if (sPath == null) {
        throw new Exception("page needs a 'p' parameter to specify the path");
    }
    String sFileName = request.getParameter("fn");
    if (sFileName == null) {
        throw new Exception("page needs a 'fn' parameter to specify the filename");
    }
    String dest = request.getParameter("dest");
    if (dest == null) {
        throw new Exception("page needs a 'dest' parameter to specify the destination");
    }
    int colonpos = dest.indexOf(':');
    if (colonpos <= 0) {
        throw new Exception("Parameter 'dest' must have a disk name, colon, and path on that disk, instead received '"+dest+"'.");
    }
    if (dest.indexOf("\\")>=0) {
        dest = dest.replace('\\','/');
    }
    if (!dest.endsWith("/")) {
        dest = dest + "/";
    }
    String disk2 = dest.substring(0, colonpos);
    String destPath = dest.substring(colonpos+1);

    DiskMgr dm1 = DiskMgr.getDiskMgr(sDiskName);
    DiskMgr dm2 = DiskMgr.getDiskMgr(disk2);
    ImageInfo ii = ImageInfo.findImage(sDiskName, sPath, sFileName);

    if (ii == null) {
        throw new Exception ("cant find an image with d="+sDiskName+",  fn="+sFileName);
    }
    if (ii.fileName.equals(sFileName) &&
        ii.getFilePath().getAbsolutePath().equals(sPath) &&
        ii.diskMgr.diskName.equals(sDiskName)) {
        ii.moveImage(disk2, dm2.extraPath + destPath);
    }
    else {
        throw new Exception ("Found an image, bit it did not match, with d="+sDiskName+",  fn="+sFileName);
    }

    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
        session.setAttribute("destVec", destVec);
    }
    int vecSize = destVec.size();
    boolean found = false;
    for (int i=0; i<vecSize; i++) {
        if (dest.equalsIgnoreCase((String) destVec.elementAt(i))) {
            destVec.removeElementAt(i);
            break;
        }
    }
    destVec.insertElementAt(dest, 0);
    while (destVec.size() > 16) {
        destVec.removeElementAt(destVec.size()-1);
    }

    String go = UtilityMethods.defParam(request, "go", "selection.jsp?msg=Moved%20File");
    response.sendRedirect(go);
%>
