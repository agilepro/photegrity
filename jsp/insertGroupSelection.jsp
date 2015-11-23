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
    String pageName = "insertGroupSelection.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String query = UtilityMethods.reqParam(request, pageName, "q");
    String order = UtilityMethods.defParam(request, "o", "name");
    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    String grp = UtilityMethods.reqParam(request, pageName, "grp");
    session.setAttribute("newGroup", grp);
    if (grp.length() == 0) {
        throw new Exception("page requires a 'grp' parameter with a non-null value");
    }
    String dest = request.getParameter("dest");

    Vector copyImages = new Vector();
    copyImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e2 = copyImages.elements();
    int count = 0;
    int num = 1;
    while (e2.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e2.nextElement();
        if (ii == null) {
            throw new Exception ("null image file in selection");
        }
        // rename it here
        ii.insertGroup(grp);

        count++;
    }

    if (dest == null) {
        dest = "selection.jsp?msg=Insert%20"+grp+"%20Into%20"+count+"%20Files";
    }
    response.sendRedirect(dest);
%>
