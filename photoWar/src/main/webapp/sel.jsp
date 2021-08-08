<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.MarkedVector" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector" %>

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


    int pageSize = 5;

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

    String selectionOrder = "compare.jsp";
    String moveDest = (String) session.getAttribute("moveDest");
    if (moveDest == null) {
        moveDest = "";
    }
    int set = UtilityMethods.defParamInt(request, "set", 1);

    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
    }
    int destSize = destVec.size();

    String lastPath = "";
    Hashtable groupMap = new Hashtable();

    MarkedVector group = ImageInfo.memory[set-1];

    Enumeration e0 = group.elements();
    int totalCount = -1;

    if (dummy==null) {
        dummy = ImageInfo.getNullImage();
    }

    String thisPage = "sel.jsp?set="+set+"&min="+dispMin;
    String thisPageEncoded = URLEncoder.encode(thisPage, "UTF8");

    int mark = group.getMarkPosition();
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<TITLE>Set <%=set%> (<%= group.size() %> images)</TITLE>
<link href="//netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">
</HEAD>
<BODY BGCOLOR="#FDF5E6">

<a href="main.jsp"><img src="home.gif"></a>
<a href="sel.jsp?set=1" target="sel1">1</a>
<a href="sel.jsp?set=2" target="sel2">2</a>
<a href="sel.jsp?set=3" target="sel3">3</a>
<a href="sel.jsp?set=4" target="sel4">4</a>
<a href="sel.jsp?set=5" target="sel5">5</a>
        <a href="sel.jsp?set=<%=set%>&min=<%=prevPage%>"><img src="ArrowBack.gif" borderwidth="0"></a>
        <%= dispMin %>
        <a href="sel.jsp?set=<%=set%>&min=<%=dispMax%>"><img src="ArrowFwd.gif" borderwidth="0"></a>
Clear:
<a href="clearSelection.jsp?set=<%=set%>&dest=<%=thisPageEncoded%>">clear<%=set%></a>
- - - <%=mark%>
<table class="table">
<tr><th width="<%=thumbsize%>">
(<a href="sort.jsp?set=<%=set%>&min=<%=dispMin%>">Sort</a>) Set <%=set%> - 
</th>
<th width="225">
<a href="show.jsp?q=$(<%=set%>)&o=none"><i class="glyphicon glyphicon-list-alt"></i></a>
<a href="queryManip.jsp?q=$(<%=set%>)&o=none"><i class="glyphicon glyphicon-cog"></i></a></a>

<%= group.size() %> </th>
</tr>
<%
    String lastPatt = "";
    while (e0.hasMoreElements() ) {

        totalCount++;
        ImageInfo i0 = (ImageInfo)e0.nextElement();
        lastPatt = i0.getPattern();

        if (totalCount < dispMin) {
            continue;
        }
        if (totalCount == dispMax) {
            %><tr><td colspan="7">That's all for this page. <a href="sel.jsp?set=<%=set%>&min=<%=dispMax%>">Next page</a> starts at <%=dispMax%></td></tr><%
            continue;
        }
        if (totalCount > dispMax) {
            continue;
        }


        %><tr <% if (totalCount==mark) { %>bgcolor="#FFAABB"<% } %> ><td><%

        displayThumbnail(out, i0, thumbsize);

        String editPage = "compedit.jsp?set="+set+"&pos="+totalCount+"&min="+dispMin+"&go="+thisPageEncoded;

        %></td><td><a href="<%=editPage%>&op=up"><img src="upicon.gif" border="0"></a>
                   <a href="<%=editPage%>&op=down"><img src="downicon.gif" border="0"></a>
                   <a href="<%=editPage%>&op=insert"><img src="inserticon.gif" border="0"></a>
                   <a href="<%=editPage%>&op=remove"><img src="removeicon.gif" border="0"></a>
                   <a href="<%=editPage%>&op=setMark<% if (totalCount!=mark) { %>&mark=<%=totalCount%><%}%>">mark</a><br>
<%
        for (int i=1; i<=5; i++) {
            if (set != i) {
            %><a href="<%=editPage%>&op=<%=i%>">&gt;<%=i%></a> <%
            }
        }
        %><a href="sort.jsp?set=<%=set%>&min=<%=totalCount%>">sort</a><%
%><br>
        <%if(!i0.isNullImage()){%>
        <a href="pattern.jsp?g=<%= URLEncoder.encode(i0.getPattern(),"UTF8") %>"><%= i0.getPattern() %></a>
            <%= i0.value %>
            <a href="photo/<%=i0.getRelPath()%>" target="photo">
                <%= i0.tail %></a>
        <%}%><br>
        (<%= i0.fileSize %>)
        </tr>
<%

        out.flush();
    }
%>
    </tr>
</table>
<H1>Memory Set <%=set%> (<%= group.size() %> images)
    <font color=#0000AA>
    <%= msg %> </font></H1>
<p>Query: $(<%=set%>)</p>
<form method="get" action="renumber.jsp">
<input type="hidden" name="q" value="$(<%=set%>)">
Renumber: <input type="text" name="newName" value="<%=lastPatt%>"/>
<button type="submit">Renumber</button>
</BODY>
</HTML>
<%@ include file="functions.jsp"%>
