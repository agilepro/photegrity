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

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String disk = request.getParameter("d");
    String fileName = request.getParameter("fn");
    String path = request.getParameter("p");
    if (disk == null) {
        throw new Exception("page needs a 'd' parameter to specify the disk");
    }
    if (fileName == null) {
        throw new Exception("page needs a 'fn' parameter to specify the fileName");
    }
    if (path == null) {
        throw new Exception("page needs a 'p' parameter to specify the path");
    }
    ImageInfo ii = ImageInfo.findImage(disk, path, fileName);
    MarkedVector mem = findMemoryBank(request);
    mem.addElement(ii);
    response.sendRedirect("sel.jsp?msg=Added%201%20File");
%>

    <%@ include file="functions.jsp"%>
