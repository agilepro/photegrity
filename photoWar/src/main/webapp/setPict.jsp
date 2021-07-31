<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String goPage = UtilityMethods.reqParam(request, "setPict.jsp", "go");
    String pict = UtilityMethods.defParam(request, "pict", null);
    if (pict != null) {
        session.setAttribute("localPath", pict);
    }
    int thumbsize = UtilityMethods.defParamInt(request, "thumbsize", -4);
    if (thumbsize > 0) {
        session.setAttribute("thumbsize", new Integer(thumbsize));
    }
    int columns = UtilityMethods.defParamInt(request, "columns", -3);
    if (columns > 0) {
        session.setAttribute("columns", new Integer(columns));
    }
    int rows = UtilityMethods.defParamInt(request, "rows", -3);
    if (rows > 0) {
        session.setAttribute("rows", new Integer(rows));
    }
    int imageNum = UtilityMethods.defParamInt(request, "imageNum", -3);
    if (imageNum > 0) {
        session.setAttribute("imageNum", new Integer(imageNum));
    }
    int listSize = UtilityMethods.defParamInt(request, "listSize", -3);
    if (listSize > 0) {
        session.setAttribute("listSize", new Integer(listSize));
    }
    String iChoice = UtilityMethods.defParam(request, "iChoice", null);
    if (iChoice != null) {
        session.setAttribute("iChoice", iChoice);
    }

    response.sendRedirect(goPage);
%>
