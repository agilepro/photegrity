<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "showblack.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }


    // **** query?
    //    g(xyz)  find all images with matching tags
    //    p(xyz)  find all images with matching pattern
    //    s(#)    get from storage area #
    String query = UtilityMethods.reqParam(request, pageName, "q");
    String requestURL = request.getQueryString();

    String widerQuery = null;
    int ppos = query.lastIndexOf('(');
    if (ppos>3) {
        widerQuery = query.substring(0,ppos-1);
    }


    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");

    // **** sort in a given order?
    String order = UtilityMethods.defParam(request, "o", "name");
    String orderParam = "&o="+order;

    // **** show pictures?
    String pict = request.getParameter("pict");
    if (pict == null) {
        pict = UtilityMethods.getSessionString(session, "selPict", "no");
    }
    else {
        session.setAttribute("selPict", pict);
    }

    String listName = UtilityMethods.getSessionString(session, "listName", "");
    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);

    int pageSize = 40;

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;


    String queryNoOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrder = "manage.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order;
    String lastPath = "";
    Hashtable groupMap = new Hashtable();
    Hashtable patternMap = new Hashtable();
    Hashtable diskMap = new Hashtable();
    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(groupImages, order);
    Enumeration e2 = groupImages.elements();
    int lastSize = -1;
    ImageInfo lastImage = null;
    int totalCount = -1;
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8")+"&o="+order;
    String queryOrderPart = queryOrderNoMin+"&min="+dispMin;
    int recordCount = groupImages.size();

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>ShowBlack <%= dispMin %> / <%= recordCount %></TITLE></HEAD>
<BODY BGCOLOR="#000000">
<font color="#FFFFFF">
<table><tr>
   <td>
      <a href="show.jsp?q=<%=queryOrderPart%>"><font color="#AAAAAA">S</font></a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>"><font color="#AAAAAA">A</font></a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderNoMin%>"><font color="#AAAAAA">T</font></a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderNoMin%>"><font color="#AAAAAA">P</font></a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>"><font color="#AAAAAA">M</font></a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>"><font color="#AAAAAA">I</font></a>
   </td><td>
      <a href="compare.jsp"><font color="#AAAAAA">Compare</font></a> <font color="#AAAAAA">Order: <%=order%></font>
   </td></tr>
</table>
</font>
<hr>
<%
    while (e2.hasMoreElements())
    {
        totalCount++;
        ImageInfo ii = (ImageInfo)e2.nextElement();

        if (totalCount < dispMin) {
            continue;
        }
        if (totalCount > dispMax) {
            continue;
        }

%>    <a href="<%=queryOrder%>&min=<%=totalCount%>"><img src="photo/<%=ii.getRelPath()%>" border="0"></a>
<%
    }
%>
</BODY>
</HTML>

