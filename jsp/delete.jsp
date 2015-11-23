<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileWriter"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.DiskMgr"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    String go = request.getParameter("go");
    if (go == null) {
        throw new Exception("page needs a 'go' parameter to specify the query");
    }
    String query = request.getParameter("q");
    if (query == null) {
        throw new Exception("page needs a 'q' parameter to specify the query");
    }
    String untrashstr = request.getParameter("untrash");
    boolean trashAll = (untrashstr==null);

    if (session.getAttribute("userName") == null) {
        //not logged in, just return without doing anything
        //sort out the login on the calling page
        response.sendRedirect(go);
        return;
    }

    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e = groupImages.elements();

    int lastNum = 0;

    while (e.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e.nextElement();
        if (ii == null) {
            throw new Exception ("null image file where lastnum="+lastNum);
        }
        if (!ii.isNullImage()) {
            ii.isTrashed=trashAll;
        }
    }

    response.sendRedirect(go);

%>
