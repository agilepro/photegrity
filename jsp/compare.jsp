<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.MarkedVector" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.UtilityMethods" %>
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

    int mina = UtilityMethods.defParamInt(request, "mina", 0);
    int minb = UtilityMethods.defParamInt(request, "minb", 0);
    if (mina < 0) {
        mina = 0;
    }
    if (minb < 0) {
        minb = 0;
    }
    int maxa = mina + pageSize;
    int maxb = minb + pageSize;
    int preva = mina - pageSize;
    int prevb = minb - pageSize;
    if (preva < 0) {
        preva = 0;
    }
    if (prevb < 0) {
        prevb = 0;
    }

    String selectionOrder = "compare.jsp";
    String moveDest = (String) session.getAttribute("moveDest");
    if (moveDest == null) {
        moveDest = "";
    }

    int columnA = UtilityMethods.getSessionInt(session, "columnA", 1);
    int columnB = UtilityMethods.getSessionInt(session, "columnB", 2);

    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);

    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
    }
    int destSize = destVec.size();

    String lastPath = "";
    Hashtable groupMap = new Hashtable();
    MarkedVector group0 = ImageInfo.memory[columnA-1];
    MarkedVector group1 = ImageInfo.memory[columnB-1];
    int marka = group0.getMarkPosition();
    int markb = group1.getMarkPosition();
    int sizea = group0.size();
    int sizeb = group1.size();

    Enumeration e0 = group0.elements();
    Enumeration e1 = group1.elements();
    int totalCount = -1;

    if (dummy==null) {
        dummy = ImageInfo.getNullImage();
    }
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Compare (<%= sizea %>/<%= sizeb %> images)</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">

        <a href="compare.jsp?mina=<%=preva%>&minb=<%=minb%>"><img src="ArrowBack.gif" borderwidth="0"></a>
        <b><%= mina %></b> / <%= sizea %>
        <a href="compare.jsp?mina=<%=maxa%>&minb=<%=minb%>"><img src="ArrowFwd.gif" borderwidth="0"></a>
        <a href="clearSelection.jsp?set=<%=columnA%>&dest=compare.jsp&mina=0&minb=<%=minb%>">clear<%=columnA%></a>
        <a href="compare.jsp?mina=<%=mina%>&minb=<%=prevb%>"><img src="ArrowBack.gif" borderwidth="0"></a>
        <b><%= minb %></b> / <%= sizeb %>
        <a href="compare.jsp?mina=<%=mina%>&minb=<%=maxb%>"><img src="ArrowFwd.gif" borderwidth="0"></a>
        <a href="clearSelection.jsp?set=<%=columnB%>&dest=compare.jsp&mina=<%=mina%>&minb=0">clear<%=columnB%></a>

<a href="sel.jsp?set=1" target="sel1">1</a>
<a href="sel.jsp?set=2" target="sel2">2</a>
<a href="sel.jsp?set=3" target="sel3">3</a>
<a href="sel.jsp?set=4" target="sel4">4</a>
<a href="sel.jsp?set=5" target="sel5">5</a>
<a href="main.jsp"><img src="home.gif"></a>

<table>
<tr><th width="<%=thumbsize%>">
<%
for (int i=1; i<=5; i++) {
    if (columnB == i) {
        //do nothing
    }
    else if (columnA == i) {
        %><b>[<%=i%>]</b> <%
    }
    else {
    %><a href="compedit.jsp?set=<%=i%>&pos=0&mina=<%=mina%>&minb=<%=minb%>&op=chooseA"><%=i%></a> <%
    }
}
%> <a href="show.jsp?q=s(<%=columnA%>)&o=none">S</a>


</th><th width="25"></th><th width="<%=thumbsize%>">
<%
for (int i=1; i<=5; i++) {
    if (columnA == i) {
        //do nothing
    }
    else if (columnB == i) {
        %><b>[<%=i%>]</b> <%
    }
    else {
    %><a href="compedit.jsp?set=<%=i%>&pos=0&mina=<%=mina%>&minb=<%=minb%>&op=chooseB"><%=i%></a> <%
    }
}
%> <a href="show.jsp?q=s(<%=columnB%>)&o=none">S</a>
</th><th width="25"></th></tr>
<%
    int cnta = 0;
    int cntb = 0;
    while (e0.hasMoreElements() && cnta<mina)  {
        e0.nextElement();
        ++cnta;
    }
    while (e1.hasMoreElements() && cntb<minb)  {
        e1.nextElement();
        ++cntb;
    }

    cnta--;
    cntb--;

    while (e0.hasMoreElements() || e1.hasMoreElements()) {

        cnta++;
        cntb++;
        ImageInfo i0 = dummy;
        ImageInfo i1 = dummy;
        if (e0.hasMoreElements()) {
            i0 = (ImageInfo)e0.nextElement();
        }
        if (e1.hasMoreElements()) {
            i1 = (ImageInfo)e1.nextElement();
        }

        if (cnta >= maxa) {
            break;
        }

        %><tr>

        <td><%
        displayThumbnail(out, i0, thumbsize);
        String piecePart = "compedit.jsp?set="+columnA+"&pos="+cnta+"&mina="+mina+"&minb="+minb;
        %></td>

        <% if (cnta<sizea) { %>
        <td <% if (cnta==marka) { %>
               bgcolor="#FFAABB"><a href="<%=piecePart%>&op=setMark">unmark</a>
            <% } else { %>
                                ><a href="<%=piecePart%>&op=setMark&mark=<%=cnta%>">mark</a>
            <% } %>
                 <font size="-4"><%=cnta%></font><br/><br/>
                 <a href="<%=piecePart%>&op=up"><img src="upicon.gif" border="0"></a>
                 <a href="<%=piecePart%>&op=down"><img src="downicon.gif" border="0"></a>
                 <a href="<%=piecePart%>&op=insert"><img src="inserticon.gif" border="0"></a>
                 <a href="<%=piecePart%>&op=remove"><img src="removeicon.gif" border="0"></a><br>
                 <a href="<%=piecePart%>&op=<%=columnB%>">&gt;&gt;<%=columnB%></a><br>
        </td>
        <% } else { %>
        <td></td>
        <% } %>

        <td><%
        piecePart = "compedit.jsp?set="+columnB+"&pos="+cntb+"&mina="+mina+"&minb="+minb;
        displayThumbnail(out, i1, thumbsize);
        %></td>

        <% if (cntb<sizeb) { %>
        <td <% if (cntb==markb) { %>
               bgcolor="#FFAABB"><a href="<%=piecePart%>&op=setMark">unmark</a>
            <% } else { %>
                                ><a href="<%=piecePart%>&op=setMark&mark=<%=cntb%>">mark</a>
            <% } %>
                 <font size="-4"><%=cntb%></font><br/><br/>
                 <a href="<%=piecePart%>&op=up"><img src="upicon.gif" border="0"></a>
                 <a href="<%=piecePart%>&op=down"><img src="downicon.gif" border="0"></a>
                 <a href="<%=piecePart%>&op=insert"><img src="inserticon.gif" border="0"></a>
                 <a href="<%=piecePart%>&op=remove"><img src="removeicon.gif" border="0"></a><br>
                 <a href="<%=piecePart%>&op=<%=columnA%>"><%=columnA%>&lt;&lt;</a><br>
        </td>
        <% } else { %>
        <td></td><td></td>
        <% } %>


        <td><%

if (false) {%>
        </td><td>
        <%if(!i0.isNullImage()){%>
        <a href="pattern.jsp?g=<%= URLEncoder.encode(i0.getPattern(),"UTF8") %>"><%= i0.getPattern() %></a>
            <%= i0.value %>
            <a href="photo/<%=i0.getRelPath()%>" target="photo">
                <%= i0.tail %></a>
        <%}%>
        <br>
        <%if(!i1.isNullImage()){%>
        <a href="pattern.jsp?g=<%= URLEncoder.encode(i1.getPattern(),"UTF8") %>"><%= i1.getPattern() %></a>
            <%= i1.value %>
            <a href="photo/<%=i1.getRelPath()%>" target="photo">
                <%= i1.tail %></a>
        <%}%>
        </td><td>
        </td><td>(<%= i0.fileSize %>)<br>(<%= i1.fileSize %>)
        </tr>
<%
}

        out.flush();
    }
%>
    </tr>
</table>
<H1>Compare (<%= group0.size() %>/<%= group1.size() %> images)
    <font color=#0000AA>
    <%= msg %> </font></H1>
</BODY>
</HTML>
<%@ include file="functions.jsp"%>
