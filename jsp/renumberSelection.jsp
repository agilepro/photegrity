<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String pageName = "renumberSelection.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    // must make  a copy because the move and suppress commands
    // cause elements to be removed frrom the original vector
    String np = UtilityMethods.reqParam(request, pageName, "np");
    int pos = np.indexOf("#");
    if (pos<1) {
        throw new Exception("new pattern must have '#' character in it");
    }
    String dest = request.getParameter("dest");

    String query = UtilityMethods.reqParam(request, pageName, "q");
    String order = UtilityMethods.defParam(request, "o", "none");
    int dispMin = UtilityMethods.defParamInt(request, "min", 0);

    session.setAttribute("np", np);
    String prepos = np.substring(0,pos);
    while (pos < np.length()-1 && np.charAt(pos) == '#') {
        pos++;
    }
    String postpos = "";
    if (pos < np.length()-1) {
        postpos = np.substring(pos);
    }
    Vector copyImages = new Vector();
    copyImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(copyImages, order);
    Enumeration e2 = copyImages.elements();
    int count = 0;
    int num = 1;
    while (e2.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e2.nextElement();
        if (ii == null) {
            throw new Exception ("null image file in selection");
        }
        // rename it here
        count ++;
        num = ii.nextName(prepos, num);
    }

    if (dest == null) {
        dest = "selection.jsp?msg=Renumbered%20"+count+"%20Files";
    }
    response.sendRedirect(dest);
%>
