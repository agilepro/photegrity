<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.GridData"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.PrintWriter"
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

    String col = request.getParameter("col");
    String r = request.getParameter("r");
    String cval = request.getParameter("cval");
    if (cval!=null)
    {
        gData.toggleColumn(cval);
    }

    String sel = request.getParameter("sel");
    if (sel!=null)
    {
        gData.selMode = sel;
    }
    String go = request.getParameter("go");
    if (go==null)
    {
        if (gData.singleRow)
        {
            go = "showRow.jsp?r="+r;
        }
        else
        {
            go = "showGrid.jsp?r="+r;
        }
    }

    response.sendRedirect(go);

%>
