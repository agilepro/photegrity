<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.MarkedVector" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
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
    MarkedVector group = findMemoryBank(request); 

    group.clear();
    if (dest==null) {
        dest = "sel.jsp?set="+group.id;
    }
    response.sendRedirect(dest);
%>
<%@ include file="functions.jsp"%>