<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.UtilityMethods"
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
    String order = UtilityMethods.reqParam(request, pageName, "o");

    Vector<ImageInfo> groupImages = new Vector<ImageInfo>();
    groupImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(groupImages, order);

    //reset the counter to the beginning
    Vector mem = findMemoryBank(request);

    int lastNum = 0;
    int count = 0;
    for (ImageInfo ii : groupImages) {
        mem.addElement(ii);
        count++;
    }
    if (dest == null) {
        dest = "selection.jsp?msg=Added%20"+count+"%20Files";
    }
    response.sendRedirect(dest);
%>

    <%@ include file="functions.jsp"%>
