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



    String listName = (String) session.getAttribute("listName");
    if (listName == null) {
        listName = "";
    }

    int set = UtilityMethods.defParamInt(request, "set", 1);
    MarkedVector group = ImageInfo.memory[set-1];

    int startPos = group.getMarkPosition();

    int dispMin = UtilityMethods.defParamInt(request, "min", startPos);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + 1;
    int prevPage = dispMin - 1;
    if (prevPage < 0) {
        prevPage = 0;
    }

    String selectionOrder = "compare.jsp";
    String moveDest = (String) session.getAttribute("moveDest");
    if (moveDest == null) {
        moveDest = "";
    }

    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
    }
    int destSize = destVec.size();

    String lastPath = "";
    Hashtable groupMap = new Hashtable();


    Enumeration e0 = group.elements();
    int totalCount = -1;

    if (dummy==null) {
        dummy = ImageInfo.getNullImage();
    }

    String thisPage = "sort.jsp?set="+set+"&min="+dispMin;
    String thisPageEncoded = URLEncoder.encode(thisPage, "UTF8");

    int mark = group.getMarkPosition();
    int lastPage = group.size() - 1;
    if (lastPage<0)
    {
        lastPage = 0;
    }
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Set <%=set%> (<%= group.size() %> images)</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">

<a href="main.jsp"><img src="home.gif"></a>
<a href="sort.jsp?set=1" target="sel1">1</a>
<a href="sort.jsp?set=2" target="sel2">2</a>
<a href="sort.jsp?set=3" target="sel3">3</a>
<a href="sort.jsp?set=4" target="sel4">4</a>
<a href="sort.jsp?set=5" target="sel5">5</a>
        <a href="sort.jsp?set=<%=set%>&min=0">
            <img src="ArrowFRev.gif" border="0"></a>
        <a href="sort.jsp?set=<%=set%>&min=<%=prevPage%>">
            <img src="ArrowBack.gif" borderwidth="0"></a>
        <%= dispMin %>
        <a href="sort.jsp?set=<%=set%>&min=<%=dispMax%>">
            <img src="ArrowFwd.gif" borderwidth="0"></a>
        <a href="sort.jsp?set=<%=set%>&min=<%=lastPage%>">
            <img src="ArrowFFwd.gif" border="0"></a>
Clear:
<a href="clearSelection.jsp?set=<%=set%>&dest=<%=thisPageEncoded%>">clear<%=set%></a>
- - - <%=mark%>
Set <%=set%> - (<%= group.size() %> images)
(<a href="sel.jsp?set=<%=set%>&min=<%=dispMin%>">list</a>)
<a href="show.jsp?q=s(<%=set%>)&o=none">S</a><br/>


<%
    boolean showedImage = false;
    while (e0.hasMoreElements() )
    {
        totalCount++;
        ImageInfo i0 = (ImageInfo)e0.nextElement();

        if (totalCount < dispMin) {
            continue;
        }
        if (totalCount >= dispMax) {
            continue;
        }


        String imageURL = i0.getRelPath();

        %><a href="photo/<%=imageURL%>" target="photo">
              <img src="photo/<%=imageURL%>"
                   height="350" border="0"></a><br/><%

        showedImage = true;
        group.setMarkPosition(dispMin);

        String editPage = "compedit.jsp?set="+set+"&pos="+totalCount+"&min="
                          +dispMin+"&go="+thisPageEncoded;

        %>


        <%if(!i0.isNullImage()){%>
        <a href="pattern.jsp?g=<%= URLEncoder.encode(i0.getPattern(),"UTF8") %>"><%= i0.getPattern() %></a>
            <%= i0.value %>
            <a href="photo/<%=i0.getRelPath()%>" target="photo">
                <%= i0.tail %></a>
        <%}%>
        (<%= i0.fileSize %>)
        </tr>
<%
        out.flush();
    }
    if (!showedImage)
    {
        %><img src="photo/unknown.jpg"  height="350" border="0"><br/>no photo at this position in set.<%
    }
%>
<hr/>
<table><tr>
<%
    int rowCount=0;
    for (int i=1; i<=ImageInfo.MEMORY_SIZE; i++)
    {
        rowCount++;
        if (set == i)
        {
            %>
            <td></td>
            <%
        }
        else
        {
            MarkedVector destSet = ImageInfo.memory[i-1];
            int mpos = destSet.getMarkPosition();
            if (mpos==-1 || mpos>=destSet.size())
            {
                mpos=destSet.size()-1;
            }
            String imagePath = "default.jpg";
            if (mpos>-1)
            {
                ImageInfo sample = (ImageInfo) destSet.get(mpos);
                imagePath = sample.getRelPath();
            }
            String editPage = "compedit.jsp?set="+set+"&pos="+dispMin+"&min="
                               +dispMin+"&go="+thisPageEncoded;

            %>
            <td><%=i%> <a href="<%=editPage%>&op=<%=i%>"><img src="addicon.gif" border="0"></a>
                <a href="sort.jsp?set=<%=i%>">swap</a> <img src="removeicon.gif" border="0"><br/>
              <a href="photo/<%=imagePath%>" target="photo">
                 <img src="thumb/100/<%=imagePath%>" width="<%=thumbsize%>" border="0"></a></td>
            <%
        }
        if (rowCount>=7)
        {
            %></tr><tr><%
            rowCount=0;
        }
    }
%>
</tr></table>
</BODY>
</HTML>
<%@ include file="functions.jsp"%>
