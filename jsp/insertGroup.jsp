<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String diskName = request.getParameter("d");
    String fileName = request.getParameter("fn");
    String path = request.getParameter("p");
    String newGroupName = request.getParameter("newGroup");
    if (diskName == null) {
        throw new Exception("page needs a 'd' parameter to specify the diskName");
    }
    if (fileName == null) {
        throw new Exception("page needs a 'fn' parameter to specify the fileName");
    }
    if (path == null) {
        throw new Exception("page needs a 'p' parameter to specify the path");
    }
    if (newGroupName == null) {
        throw new Exception("page needs a 'newGroup' parameter to specify the new tag");
    }
    DiskMgr dm1 = DiskMgr.getDiskMgr(diskName);
    ImageInfo ii = ImageInfo.findImage(diskName, path, fileName);
    ii.insertGroup(newGroupName);
    Vector tagVec = (Vector) session.getAttribute("tagVec");
    if (tagVec != null) {
        int vecSize = tagVec.size();
        boolean found = false;
        for (int i=0; i<vecSize; i++) {
            if (newGroupName.equalsIgnoreCase((String) tagVec.elementAt(i))) {
                found = true;
                break;
            }
        }
        if (!found) {
            tagVec.insertElementAt(newGroupName, 0);
            while (tagVec.size() > 16) {
                tagVec.removeElementAt(tagVec.size()-1);
            }
        }
    }
    else {
        tagVec = new Vector();
        tagVec.insertElementAt(newGroupName, 0);
        session.setAttribute("tagVec", tagVec);
    }
    String go = request.getParameter("go");
    if (go == null) {
        go = "selection.jsp?msg=File%20Renamed";
    }
    session.setAttribute("newGroup", newGroupName);
    response.sendRedirect(go);
%>
