<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileWriter"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pageName = "selectQuery.jsp";

    // **** query?
    //    g(xyz)  find all images with matching tags
    //    p(xyz)  find all images with matching pattern
    //    s(#)    get from storate area #
    String query = UtilityMethods.reqParam(request, pageName, "q");

    String dest = request.getParameter("dest");
    String order = UtilityMethods.defParam(request, "o", "name");

    Vector<ImageInfo> groupImages = new Vector<ImageInfo>();
    groupImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(groupImages, order);

    //reset the counter to the beginning
    MarkedVector group = findMemoryBank(request);

    int lastNum = 0;
    int count = 0;
    for (ImageInfo ii : groupImages) {
        group.addElement(ii);
        count++;
    }
    if (dest==null) {
        dest = "sel.jsp?set="+group.id;
    }
    response.sendRedirect(dest);
%>

    <%@ include file="functions.jsp"%>
