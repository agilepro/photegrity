<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
%><jsp:include page="PasswordPanel.jsp" flush="true"/><%
    return;
    }
    // msg is not required, just used by functions redirecting here
    String msg = request.getParameter("msg");
    if (msg == null) {
        msg = "";
    }
    String pattern = request.getParameter("g");
    if (pattern == null) {
        pattern = "aa";
    }
    else {
        pattern = pattern.toLowerCase();
    }

    int set = UtilityMethods.defParamInt(request, "set", 1);
    if (set<1) {
        throw new Exception("memory banks are numbered 1 thru 6, and '"+set+"' is too small.");
    }
    if (set>6) {
        throw new Exception("memory banks are numbered 1 thru 6, and '"+set+"' is too large.");
    }

    // **** sort in a given order?
    String order = UtilityMethods.defParam(request, "o", "none");
    String pict = UtilityMethods.defParam(request, "pict", "no");

    int pageSize = 500;
    boolean showPict = (pict.equals("yes"));
    String pictParam = "";
    if (showPict) {
        pictParam = "&pict=yes";
        pageSize = 20;
    }

    String listName = (String) session.getAttribute("listName");
    if (listName == null) {
        listName = "";
    }

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }

    String selectionOrder = "selection.jsp?o="+order+pictParam;
    String moveDest = (String) session.getAttribute("moveDest");
    if (moveDest == null) {
        moveDest = "";
    }
    String np = (String) session.getAttribute("np");
    if (np == null) {
        np = "";
    }
    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
    }
    int destSize = destVec.size();

    String lastPath = "";
    Hashtable groupMap = new Hashtable();
    Hashtable diskMap = new Hashtable();
    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.memory[set-1]);
    ImageInfo.sortImages(groupImages, order);
    Enumeration e2 = groupImages.elements();
    int lastSize = -1;
    ImageInfo lastImage = null;
    int totalCount = -1;
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Display Selection</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Selection (<%=groupImages.size()%> images)
    <font color=#0000AA>
    <%=msg%> </font></H1>
<table>
<tr><td colspan=7><img src="bar.jpg"></td></tr>
    <tr><td colspan=7><a href="clearSelection.jsp">
        <img border=0 src="removeicon.gif">Clear Selection</a>
        <%
            if (showPict) {
        %>
            <a href="selection.jsp?pict=no&min=<%=dispMin%>&o=<%=order%>&min=<%=dispMin%>">Without Images</a>
        <%
            } else {
        %>
            <a href="selection.jsp?pict=yes&min=<%=dispMin%>&o=<%=order%>&min=<%=dispMin%>">With Images</a>
        <%
            }
        %>
        <a href="<%=selectionOrder%>&min=<%=prevPage%>"><img src="ArrowBack.gif" borderwidth="0"></a>
        <%=dispMin%>
        <a href="<%=selectionOrder%>&min=<%=dispMax%>"><img src="ArrowFwd.gif" borderwidth="0"></a>
        </td></tr>
    <tr><td>&nbsp;</td>
        <td bgcolor=#EEEEBB><a href="selection.jsp?o=name<%=pictParam%>&min=<%=dispMin%>">Name</a>
                            <a href="selection.jsp?o=num<%=pictParam%>&min=<%=dispMin%>">Number</a></td>
        <td>&nbsp;</td>
        <td bgcolor=#EEEEBB><a href="selection.jsp?o=path<%=pictParam%>&min=<%=dispMin%>">Disk</a></td>
        <td></td>
        <td bgcolor=#EEEEBB><a href="selection.jsp?o=size<%=pictParam%>&min=<%=dispMin%>">Size</a></td></tr>
<%
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
        }
        if (totalCount < dispMin) {
            continue;
        }
        if (totalCount == dispMax) {
%><tr><td colspan="7">That's all for this page. <a href="<%=selectionOrder%>&min=<%=dispMax%>">Next page</a> starts at <%=dispMax%></td></tr><%
    continue;
        }
        if (totalCount > dispMax) {
            continue;
        }
        String sizeDup = "";
        if (lastImage == ii) {
%><tr><td colspan="5"></td><td>-- duplicate entry --</td></tr><%
    continue;
        }
        lastImage = ii;
        if (lastSize == ii.fileSize) {
            sizeDup = "***";
        }
        lastSize = ii.fileSize;
        String encodedName = URLEncoder.encode(ii.fileName,"UTF8");
        String encodedPath = URLEncoder.encode(ii.getFullPath(),"UTF8");
%>
        <tr><td>
<%
    if (showPict) {
%>          <a href="photo/<%=ii.getRelPath()%>" target="photo">
            <img src="thumb/100/<%=ii.getRelPath()%>" width=100 border=0></a>
<%
    }
%>
        </td><td><a href="pattern.jsp?g=<%=URLEncoder.encode(ii.getPattern(),"UTF8")%>"><%=ii.getPattern()%></a>
            <%=ii.value%>
            <a href="photo/<%=ii.getRelPath()%>" target="photo">
                <%=ii.tail%></a></td>
            <td><a href="removeSelection.jsp?d=<%=URLEncoder.encode(ii.diskMgr.diskName,"UTF8")%>&f=<%=encodedName%>&p=<%=encodedPath%>" target="suppwindow">
                <img border=0 src="removeicon.gif"></a>
                </td>
            <td bgcolor="#FFCCAA"><%=ii.diskMgr.diskName%></td>
            <td><a href="deleteOne.jsp?d=<%=URLEncoder.encode(ii.diskMgr.diskName,"UTF8")%>&fn=<%=encodedName%>&p=<%=encodedPath%>" target="suppwindow">
                <img border=0 src="delicon.gif"></a></td>
            <td><%=sizeDup%>(<%=ii.fileSize%>)
<%
                Enumeration eg = ii.tagVec.elements();
                                    while (eg.hasMoreElements()) {
                                        TagInfo gi = (TagInfo) eg.nextElement();
                                        HTMLWriter.writeHtml(out, gi.tagName);
                                        out.write(" \t ");
                                    }
            %> <b><%= pp %></b></td></tr>
<%
        out.flush();
    }
%>
    <tr><td colspan=7><a href="deleteAllSelection.jsp">
        <img border=0 src="delicon.gif">Delete Entire Selection</a>
        </td></tr>
    <tr><td colspan=7>Tags:
<%
    Enumeration e3 = groupMap.keys();
    while (e3.hasMoreElements()) {
        String gg = (String) e3.nextElement();
%>
            <a href="group.jsp?g=<%= URLEncoder.encode(gg,"UTF8") %>"><%= gg %></a>
<%
    }
%>
    </tr>
    <tr>
    <td colspan=7><table><tr><td>
          <form action="move.jsp" method="get">
          <input type="hidden" name="q" value="s(1)">
          To destination <input type="text" name="dest" value="<%HTMLWriter.writeHtml(out,moveDest);%>">
          <input type="submit" value="Move">
          </form>
        </td><td>
          <form action="move.jsp" method="get">
          <input type="hidden" name="q" value="s(1)">
          OR to
            <% for(int i=0; i<destSize; i++) { %>
            <input type="submit" name="dest" value="<%HTMLWriter.writeHtml(out,(String)destVec.elementAt(i));%>">
            <% } %>
          </form>
        </td></tr></table>
    </td></tr>
    <tr><td colspan=7>
        <form action="cleanSelection.jsp" method="get">
        Clean pattern <input type="text" name="p">
        from selection <input type="submit" value="Clean">
        </form></td></tr>
    <tr><td colspan=7>
        <form action="changeSelection.jsp" method="get">
        Change pattern from <input type="text" name="p1">
        to <input type="text" name="p2">
        <input type="submit" value="Change">
        </form></td></tr>
    <tr><td colspan=7>
        <form action="renumberSelection.jsp" method="get">
        New pattern <input type="text" name="np" value="<%HTMLWriter.writeHtml(out,np);%>">
        <input type="submit" value="Renumber">
        </form></td></tr>
    <tr><td colspan=7>
        <form action="insertGroupSelection.jsp" method="get">
        New group <input type="text" name="grp">
        <input type="submit" value="Insert Tag">
        </form></td></tr>
    <tr><td colspan=7>
        <form action="replName.jsp" method="get">
        Replace <input type="text" name="s"> with <input type="text" name="t">
        <input type="submit" value="Replace">
        </form></td></tr>
    <tr><td colspan=7>
        <form action="restrictSelection.jsp" method="get">
        <select name="op"><option>keep</option><option>remove</otion></select> file if
        <select name="el"><option>filename</option><option>group</otion><option>duplicates</otion></select>
        contains <input type="text" name="p">
        <input type="submit" value="Restrict">
        </form></td></tr>
    <tr><td colspan=7>
        <form action="saveSelection.jsp" method="get">
        File List: <input type="text" name="list" value="<%=listName%>">
        <input type="submit" name="op" value="Save">
        <input type="submit" name="op" value="Load">
        <input type="submit" name="op" value="Clear">
        </form></td></tr>

<tr><td colspan=7><img src="bar.jpg"></td></tr>
</table>
<br>
<a href="main.jsp"><img src="home.gif"></a>
<a href="selection.jsp?p=<%= pattern %>">Display Selection</a>
</BODY>
</HTML>
