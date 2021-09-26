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
<%@page import="java.util.ArrayList" %>

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

    ArrayList<MarkedVector> customLists = new ArrayList<MarkedVector>();


    MarkedVector group = findMemoryBank(request);
    String set = group.id;
    
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
<HEAD><TITLE>Set <%=set%> (<%= group.size() %> images)</TITLE>
    <link href="//netdna.bootstrapcdn.com/bootstrap/3.3.7/css/bootstrap.min.css" rel="stylesheet">
    <link href="photoStyle.css" rel="stylesheet">
</HEAD>
<BODY BGCOLOR="#FDF5E6">

<a href="main.jsp"><img src="home.gif"></a>

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

<table><tr>
<%
    boolean showedImage = false;
    ImageInfo i0 = null;
    if (dispMin<group.size()) {
        i0 = group.get(dispMin);
    }
    group.setMarkPosition(dispMin);
    String chosenId = "" + group.id;
    if (i0!=null) {
        String imageURL = i0.getRelPath();

        %><td>
            <div style="width:350px;height:350px"><a href="photo/<%=imageURL%>" target="photo">
              <img src="photo/<%=imageURL%>"
                   style="max-height:350px;max-width:350px" border="0"></a></div></td><%

        showedImage = true;
        int trailer = dispMin;
        if (++trailer < group.size()) {
            imageURL = group.get(trailer).getRelPath();
            %><td><a href="photo/<%=imageURL%>" target="photo">
                  <img src="thumb/100/<%=imageURL%>"
                       height="100" border="0"></a><br/></td><%
        }
        if (++trailer < group.size()) {
            imageURL = group.get(trailer).getRelPath();
            %><td><a href="photo/<%=imageURL%>" target="photo">
                  <img src="thumb/100/<%=imageURL%>"
                       height="100" border="0"></a><br/></td><%
        }
        if (++trailer < group.size()) {
            imageURL = group.get(trailer).getRelPath();
            %><td><a href="photo/<%=imageURL%>" target="photo">
                  <img src="thumb/100/<%=imageURL%>"
                       height="100" border="0"></a><br/></td><%
        }
        if (++trailer < group.size()) {
            imageURL = group.get(trailer).getRelPath();
            %><td><a href="photo/<%=imageURL%>" target="photo">
                  <img src="thumb/100/<%=imageURL%>"
                       height="100" border="0"></a><br/></td><%
        }
    }

    %>
    </tr></table>


    <%if(i0!=null){%>
    <a href="pattern.jsp?g=<%= URLEncoder.encode(i0.getPattern(),"UTF8") %>"><%= i0.getPattern() %></a>
        <%= i0.value %>
        <a href="photo/<%=i0.getRelPath()%>" target="photo">
            <%= i0.tail %></a>
       (<%= i0.getFileSize() %>)
    <%}%>
<%
    out.flush();

    if (!showedImage)
    {
        %><img src="photo/unknown.jpg"  height="350" border="0"><br/>no photo at this position in set.<%
    }
%>
<hr/>
<table><tr>
<%
    int rowCount=0;
    int iii = 0;
    for (int i=1; i<=ImageInfo.customLists.size(); i++){
        MarkedVector destSet = ImageInfo.customLists.get(i-1);
        if (chosenId.equals(destSet.id)) {
            continue;
        }
        rowCount++;

            
        int mpos = destSet.getMarkPosition();
        if (mpos==-1 || mpos>=destSet.size()) {
            mpos=destSet.size()-1;
        }
        int mpos2 = mpos;
        int mpos3 = mpos;
        if (mpos>1) {
            mpos2=0;
            mpos3=1;
        }
        String imagePath1 = "default.jpg";
        String imagePath2 = "default.jpg";
        String imagePath3 = "default.jpg";
        if (mpos>-1) {
            ImageInfo sample = (ImageInfo) destSet.get(mpos);
            imagePath1 = sample.getRelPath();
            sample = (ImageInfo) destSet.get(mpos2);
            imagePath2 = sample.getRelPath();
            sample = (ImageInfo) destSet.get(mpos3);
            imagePath3 = sample.getRelPath();
        }
        String editPage = "compedit.jsp?set="+set+"&pos="+dispMin+"&min="
                           +dispMin+"&go="+thisPageEncoded;

        %>
        <td style="padding:5px"><%=i%> 
          <a href="<%=editPage%>&op=Move&dest=<%=destSet.id%>"><img src="addicon.gif" border="0"></a>
          <a href="sort.jsp?set=<%=destSet.id%>">swap</a> 
          <img src="removeicon.gif" border="0">
          <span><%=destSet.name%> (<%=destSet.id%>)</span><br/>
          <a href="photo/<%=imagePath1%>" target="photo">
             <img src="thumb/100/<%=imagePath1%>" width="<%=thumbsize%>" border="0"></a>
          <a href="photo/<%=imagePath2%>" target="photo">
             <img src="thumb/100/<%=imagePath2%>" width="<%=thumbsize%>" border="0"></a>
          <a href="photo/<%=imagePath3%>" target="photo">
             <img src="thumb/100/<%=imagePath3%>" width="<%=thumbsize%>" border="0"></a>
        </td>
        <%
        
        if (rowCount>2)
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
