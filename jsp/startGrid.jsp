<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.GridData"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null)
    {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pageName = "startGrid.jsp";
    String q = UtilityMethods.reqParam(request, pageName, "q");
    String mode = UtilityMethods.defParam(request, "mode", "row");

    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }
    gData.setQuery(q);
    gData.selMode = "all";


    String min = UtilityMethods.reqParam(request, pageName, "min");

    boolean dupMode = ("dups".equals(mode));
    if (dupMode) {
        mode = "grid";
        for (String cval : gData.getColumnMap()) {
            gData.toggleColumn(cval);
        }
        gData.selMode = "sel";
    }

    if ("row".equals(mode)) {
        response.sendRedirect("showRow.jsp?r="+min);
    }
    else {
        response.sendRedirect("showGrid.jsp?r="+min);
    }

%>
