<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.GridData"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }


    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    if (DiskMgr.archivePaths == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String r = UtilityMethods.reqParam(request, "setBound.jsp", "r");
    String op = UtilityMethods.reqParam(request, "setBound.jsp", "op");

    if (op.equals("T"))
    {
        int v = UtilityMethods.defParamInt(request, "v", -1000);
        gData.rangeTop = v;
    }
    else if (op.equals("B"))
    {
        int v = UtilityMethods.defParamInt(request, "v", 1000);
        gData.rangeBottom = v;
    }

    response.sendRedirect("showGrid.jsp?r="+r);

%>
