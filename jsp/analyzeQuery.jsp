<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%

    request.setCharacterEncoding("UTF-8");
    String pageName = "analyzeQuery.jsp";
    long starttime = System.currentTimeMillis();

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    // **** query?
    //    g(xyz)  find all images with matching tags
    //    p(xyz)  find all images with matching pattern
    //    s(#)    get from storage area #
    String query = UtilityMethods.reqParam(request, pageName, "q");
    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
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
    int pageSize = 500;
    boolean showPict = (pict.equals("yes"));
    String pictParam = "";
    if (showPict) {
        pictParam = "&pict=yes";
        pageSize = 20;
    }

    String listName = UtilityMethods.getSessionString(session, "listName", "");
    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");


    String queryNoOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+pictParam;
    String lastPath = "";
    Hashtable groupMap = new Hashtable();
    Hashtable patternMap = new Hashtable();
    Hashtable diskMap = new Hashtable();
    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(groupImages, order);
    String lastSize = "";
    ImageInfo lastImage = null;
    int totalCount = -1;
    HashCounter groupCount = new HashCounter();
    HashCounter pattCount = new HashCounter();

    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
    }
    int destSize = destVec.size();
    String queryOrderPart = URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+dispMin;


%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Analyze <%HTMLWriter.writeHtml(out,query);%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table width="600"><tr><td>

<table><tr>
   <td>
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td bgcolor="#FF0000">
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderPart%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderPart%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
      <%HTMLWriter.writeHtml(out,query);%>   #<%= groupImages.size() %>
   </td></tr>
</table>
<table>
    <tr><td colspan="7"><img src="bar.jpg"></td></tr>
    <tr><td colspan="7">
        <table><tr><td>
            <a href="main.jsp"><img src="home.gif"></a>
            <a href="show.jsp?q=s(1)">1</a>
            <a href="show.jsp?q=s(2)">2</a>
            <a href="show.jsp?q=s(3)">3</a>
        </td><td>
        <form action="show.jsp" method="get">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Show">
            </form>
        </td><td>
        <form action="selectQuery.jsp" method="get" target="suppwindow">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="submit" value="Select All">
            </form>
        </td><td>
        <form method="GET" action="analyzeQuery.jsp">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Search:">
            <input type="text" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        </form>
        </td></tr></table>
    </td></tr>
<%

    Enumeration e2 = groupImages.elements();
    while (e2.hasMoreElements()) {
        totalCount++;
        ImageInfo ii = (ImageInfo)e2.nextElement();
        diskMap.put(ii.diskMgr.diskName, ii);
        String pp = ii.getRelativePath();
        if (pp.equals(lastPath)) {
            pp = "";
        }
        else {
            lastPath = pp;
        }
        for (String tagName : ii.getTagNames()) {
            groupMap.put(tagName, "x");
            groupCount.increment(tagName);
        }
        String lcPattern = ii.getPattern();

        patternMap.put(lcPattern, ii);
        pattCount.increment(lcPattern);
        out.flush();
    }
%>
    </table>
    Tags:
    <table>
        <tr>
            <td>&nbsp;</td>
            <td>&nbsp;</td>
            <td>S</td>
            <td>A</td>
            <td>Exclude</td>
            <td>Select</td>
            <td>Explore</td>
            <td>Detail</td>
        </tr>

<%
    int lineGrey = 0;
    Enumeration e3 = HashCounter.sort(groupCount.keys());
    while (e3.hasMoreElements()) {
        String gg = (String) e3.nextElement();
        Integer cnt = (Integer) groupCount.get(gg);
        String newQ = query+"g("+gg+")";
%>
        <tr <%if(((lineGrey++)%5)==4){%> BGCOLOR="#CCCCCC" <% } %> >
            <td>&nbsp;<%=cnt%></td>
            <td><%=gg%></td>
            <td><a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%><%=orderParam%><%=pictParam%>">S</a></td>
            <td><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%><%=orderParam%><%=pictParam%>">A</a></td>
            <td><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode(query+"d("+gg+")","UTF8")%><%=orderParam%><%=pictParam%>">Exclude</a></td>
            <td><a href="selectQuery.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%><%=orderParam%>" target="suppwindow">Select</a></td>
            <td><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode("g("+gg+")","UTF8")%><%=orderParam%><%=pictParam%>">Explore</a></td>
            <td><a href="xgroups.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>">T</a>
                <a href="allPatts.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>">P</a>
                <a href="queryManip.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>">M</a></td>
        </tr>
<%
    }
%>
    </table>
    Patts:
    <table>
        <tr>
            <td>&nbsp;</td>
            <td>Name</td>
            <td>S</td>
            <td>A</td>
            <td>Contains</td>
            <td>Exclude</td>
            <td>Select</td>
            <td>Explore</td>
        </tr>

<%
    Enumeration e4 = HashCounter.sort(pattCount.keys());
    lineGrey = 0;
    while (e4.hasMoreElements()) {
        String pp = (String) e4.nextElement();
        Integer cnt = (Integer) pattCount.get(pp);
        String newQ = query+"e("+pp+")";
%>
        <tr  <%if(((lineGrey++)%5)==4){%> BGCOLOR="#CCCCCC" <% } %> >
            <td>&nbsp;<%=cnt%></td>
            <td><%=pp%></td>
            <td><a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%><%=orderParam%><%=pictParam%>">S</a></td>
            <td><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%><%=orderParam%><%=pictParam%>">A</a></td>
            <td><a href="allPatts.jsp?q=<%=URLEncoder.encode(query+"p("+pp+")","UTF8")%><%=orderParam%><%=pictParam%>">Contains</a></td>
            <td><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode(query+"b("+pp+")","UTF8")%><%=orderParam%><%=pictParam%>">Exclude</a></td>
            <td><a href="selectQuery.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%><%=orderParam%>" target="suppwindow">Select</a></td>
            <td><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode("p("+pp+")","UTF8")%><%=orderParam%><%=pictParam%>">Explore</a></td>
            <td><a href="xgroups.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>">T</a>
                <a href="allPatts.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>">P</a></td>
        </tr>
<%
    }
%>
    </table>
<%
    out.flush();
    int startPos = 0;
    int pos = query.indexOf(")");
    while (pos >= startPos) {
        String pieceq = query.substring(startPos, pos+1);
        String piece = query.substring(startPos+2, pos);
        %><a href="analyzeQuery.jsp?q=<%=URLEncoder.encode(pieceq,"UTF8")%>"><%=pieceq%></a> <%
        %>patt:<a href="allPatts.jsp?g=<%=URLEncoder.encode(piece,"UTF8")%>"><%=piece%></a> <%
        %>grp:<a href="xgroups.jsp?g=<%=URLEncoder.encode(piece,"UTF8")%>"><%=piece%></a> <%
        %>simpatt:<a href="masterPatts.jsp?s=<%=URLEncoder.encode(piece,"UTF8")%>"><%=piece%></a> <%
        %>simgrp:<a href="masterGroups.jsp?s=<%=URLEncoder.encode(piece,"UTF8")%>"><%=piece%></a><br><%
        startPos = pos+1;
        pos = query.indexOf(")", startPos);
    }
%>
<a href="xgroups.jsp?q=<%=URLEncoder.encode(query,"UTF8")%>">AllTags</a>
<a href="allPatts.jsp?q=<%=URLEncoder.encode(query,"UTF8")%>">AllPatterns</a>
<table>

<tr>
   <td colspan="3">
       <form method="post" action="move.jsp">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <% for(int i=0; i<destSize; i++) { %>
            <input type="submit" name="dest" value="<%HTMLWriter.writeHtml(out,(String)destVec.elementAt(i));%>">
            <% } %>
   </form></td>
</tr>
</table>

<a href="main.jsp"><img src="home.gif"></a>
        <form method="GET" action="analyzeQuery.jsp">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Search:">
            <input type="text" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        </form>
</td></tr></table>
</BODY>
</HTML>
