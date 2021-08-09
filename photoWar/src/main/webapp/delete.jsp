<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileWriter"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="java.util.List"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
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

    List<ImageInfo> groupImages = ImageInfo.imageQuery(query);

    int lastNum = 0;

    for (ImageInfo ii : groupImages) {
        if (ii == null) {
            throw new Exception ("null image file where lastnum="+lastNum);
        }
        if (ii.isTrashed()!=trashAll) {
            ii.toggleTrashImage();
        }
    }

    response.sendRedirect(go);

%>
