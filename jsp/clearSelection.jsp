<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.MarkedVector" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector" %>
<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String dest = request.getParameter("dest");
    int set = UtilityMethods.defParamInt(request, "set", 1);

    if (set<1) {
        throw new Exception("memory banks are numbered 1 thru "+ImageInfo.MEMORY_SIZE+", and '"+set+"' is too small.");
    }
    if (set>ImageInfo.MEMORY_SIZE) {
        throw new Exception("memory banks are numbered 1 thru "+ImageInfo.MEMORY_SIZE+", and '"+set+"' is too large.");
    }
    MarkedVector mem = ImageInfo.memory[set-1];

    mem.clear();
    if (dest == null)
    {
        dest = "selection.jsp?msg=Selection%20Cleared";
    }
    response.sendRedirect(dest);
%>
