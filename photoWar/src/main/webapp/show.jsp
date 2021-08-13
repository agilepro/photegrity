<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.photegrity.MongoDB"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "show.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
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
    if (pict == null)
    {
        pict = UtilityMethods.getSessionString(session, "selPict", "no");
    }
    else
    {
        session.setAttribute("selPict", pict);
    }

    String listName = UtilityMethods.getSessionString(session, "listName", "");
    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    String localPath2 = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);
    int pageSize = UtilityMethods.getSessionInt(session, "listSize", 20);

    int rowMax = pageSize;

    boolean groupSize = false;
    boolean groupNum = false;
    if (pict.equals("group"))
    {
        if (order.equals("size"))
        {
            groupSize = true;
        }
        else
        {
            groupNum = true;
            order = "num";
        }
    }
    boolean showPict = (pict.equals("yes"));
    boolean allPict = (pict.equals("all"));
    String pictParam = "";
    if (groupSize || groupNum)
    {
        pictParam = "&pict=group";
        rowMax = 6;
    }
    else if (showPict)
    {
        pictParam = "&pict=yes";
        rowMax = 6;
    }
    else if (allPict)
    {
        pictParam = "&pict=all";
        pageSize = columns * rows;
        rowMax = rows;
    }

    Hashtable<Integer,Vector<ImageInfo>> rowVectors = new Hashtable<Integer,Vector<ImageInfo>>();

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }


    String queryNoOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+pictParam;
    String thisPage = queryOrder +"&min="+dispMin;

    String lastPath = "";
    Hashtable diskMap = new Hashtable();
    
    Vector<ImageInfo> groupImages = ImageInfo.imageQuery(query);
     
    int totalCount = -1;
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8")+"&o="+order;
    String queryOrderPart = queryOrderNoMin+"&min="+dispMin;
    int recordCount = groupImages.size();
    
    ImageInfo.sortImages(groupImages, order);

///////////////////////////////////////
 
    int rowNum = -1;
    int colNum = 9999;
    int nextStart = 0;
    int lastSize = -1;
    int minValue = 9999;
    String lastPattern = "";
    HashCounter tagsCount = new HashCounter();

    for (ImageInfo ii : groupImages) {
        
        for (String tag : ii.pp.getPathTags()) {
            tagsCount.increment(tag);
        }
        totalCount++;
        int value = ii.value;
        int fileSize = ii.fileSize;
        String diskName = ii.pp.getDiskMgr().diskName;
        if (value>0 && value<minValue) {
            minValue = value;
        }
        lastPattern = ii.pp.getPattern();

        if (!ii.isNullImage())
        {
            diskMap.put(diskName, ii);
        }

        //if you have not reached the start image, then skip
        if (totalCount < dispMin) {
            continue;
        }
        //if you have all the rows, then skip forward (so statistics are over fullset)
        if (rowNum >= rowMax) {
            continue;
        }

        //if this image causes things to go to the next row, and that
        //is too many rows, then nextStart will be the image that caused
        //this, and nextStart will be the right image to start next time with
        nextStart = totalCount;

        //now determine if we need a new row
        if (groupNum)
        {
            if (lastSize != value)
            {
                rowNum++;
                lastSize = value;
            }
        }
        else if (groupSize)
        {
            if (lastSize != fileSize)
            {
                rowNum++;
                lastSize = fileSize;
            }
        }
        else if (showPict)
        {
            rowNum++;
        }
        else if (allPict)
        {
            colNum++;
            if (colNum>=columns)
            {
                rowNum++;
                colNum = 0;
            }
        }
        else
        {
            rowNum++;
        }

        if (rowNum<0 || rowNum >= rowMax)
        {
            continue;
        }

        Vector<ImageInfo> row = rowVectors.get(rowNum);
        if (row==null)
        {
            row = new Vector<ImageInfo>();
            rowVectors.put(rowNum, row);
        }

        row.add(ii);
    }
    
        
%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
    <TITLE>Show <%=dispMin%> / <%=recordCount%></TITLE>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <link href="photoStyle.css" rel="stylesheet">
    <script type="text/javascript" src="lib/angular.js"></script>
    <script type="text/javascript" src="lib/ui-bootstrap-tpls.min.js"></script>
    <script type="text/javascript" src="lib/jquery.min.js"></script>
    <script type="text/javascript" src="lib/bootstrap.min.js"></script>
<style>
.thumbnail {
    border:0;
    min-width:100px;
    min-height:100px;
}
</style>
<script>
console.log("foo");
</script>

<script>

console.log("foo");
var bunchApp = angular.module('bunchApp', ['ui.bootstrap']);
bunchApp.controller('bunchCtrl', function ($scope, $http) {
    $scope.query = "<%=query%>";
    console.log("Peekaboo");
});

</script>

</head>
<body  ng-app="bunchApp" ng-controller="bunchCtrl">
<table width="600"><tr><td>

<table><tr>
   <td bgcolor="#FF0000">
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>" title="Analyze this query">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderNoMin%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderNoMin%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
      <a href="showGrid2.jsp?query=<%=queryOrderPart%>">Row</a>
   </td><td>
      <a href="compare.jsp">Compare</a>
   </td></tr>
</table>
<table>
    <tr><td colspan="7"><img src="bar.jpg"></td></tr>
    <tr valign="top"><td colspan="7">
        <table><tr><td>
            <a href="main.jsp"><img src="home.gif" border="0"></a>
            <a href="sel.jsp?set=1" target="sel1">1</a>
            <a href="sel.jsp?set=2" target="sel2">2</a>
            <a href="sel.jsp?set=3" target="sel3">3</a>
            <a href="sel.jsp?set=4" target="sel4">4</a>
            <a href="sel.jsp?set=5" target="sel5">5</a>
        </td><td>
        <a href="<%=queryOrder%>&min=<%=prevPage%><%=pictParam%>"><img src="ArrowBack.gif" border="0"></a>
        <%=dispMin%> / <%=recordCount%>
        <a href="<%=queryOrder%>&min=<%=nextStart%><%=pictParam%>"><img src="ArrowFwd.gif" border="0"></a>
        <%
            if (!groupSize && !groupNum)
                {
        %><a href="<%=queryNoOrder%><%=orderParam%>&pict=group&min=<%=dispMin%>"><img src="radio_off.png" border="0">Grouped</a> <%
    }
         else
         {
 %><img src="radio_on.png" border="0">Grouped <%
    }
         if (!showPict)
         {
 %><a href="<%=queryNoOrder%><%=orderParam%>&pict=yes&min=<%=dispMin%>"><img src="radio_off.png" border="0">Images</a> <%
    }
         else
         {
 %><img src="radio_on.png" border="0">Images <%
    }
         if (!allPict)
         {
 %><a href="<%=queryNoOrder%><%=orderParam%>&pict=all&min=<%=dispMin%>"><img src="radio_off.png" border="0">All</a> <%
    }
         else
         {
 %> <img src="radio_on.png" border="0">All <%
    }
         if (showPict || allPict || groupSize || groupNum)
         {
 %><a href="<%=queryNoOrder%><%=orderParam%>&pict=no&min=<%=dispMin%>"><img src="radio_off.png" border="0">Namelist</a> <%
    }
         else
         {
 %> <img src="radio_on.png" border="0">Namelist {{query}}<%
    }
 %>
        </td><td>
        </td></tr></table>
    </td></tr>
</table>

 {{query}}
<table>
<%
    //set totalcount back to value of first row
    totalCount = dispMin-1;

    for (rowNum=0; rowNum<rowMax; rowNum++)
    {
        Vector<ImageInfo> row = rowVectors.get(rowNum);
        if (row==null)
        {
            continue;
        }
        out.write("<tr>");
        boolean firstInRow = true;
        for (ImageInfo ii : row) {
            totalCount++;

            String fileName = ii.fileName;
            int value = ii.value;
            int fileSize = ii.fileSize;
            String diskName = ii.pp.getDiskMgr().diskName;
            String localPath = ii.pp.getLocalPath();
            String fullPath = diskName + "/" + localPath + fileName;
            String encodedName = URLEncoder.encode(fileName,"UTF8");
            String encodedPath = URLEncoder.encode(localPath,"UTF8");
            String encodedDisk = URLEncoder.encode(diskName,"UTF8");
            String stdParams = "d="+encodedDisk+"&fn="+encodedName+"&p="+encodedPath;
            String newQ = query+"x("+ii.pp.getSymbol()+")";
            String trashIcon = "trash.gif";

            if (ii.isTrashed()) {
                trashIcon = "delicon.gif";
            }


            String truncName = fileName;
            if (truncName.length()>30) {
                truncName = truncName.substring(0,28)+"...";
            }

            if (groupSize || groupNum)
            {
                if (firstInRow)
                {
                    if (groupSize)
                    {
                        out.write(Integer.toString(fileSize));
                    }
                    else
                    {
                        out.write(Integer.toString(value));
                    }
                    out.write("</td>");
                }
                out.write("<td>");
%>
                <a href="photo/<%=fullPath%>" target="photo">
                <img src="thumb/<%=thumbsize%>/<%=fullPath%>" width="<%=thumbsize%>" class="thumbnail" ></a>
                </td><td><a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">S</a><br/>
                <a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                    <img border=0 src="addicon.gif" border="0"></a><br/>
                <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                    <img border=0 src="searchicon.gif" border="0"></a><br/>
                <font size="-4" color="#99CC99"><%=value%></font><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="<%=trashIcon%>" border="0"></a>
                </td><%
                    }
                            else if (showPict)
                            {
                %>
                <td>
                <a href="photo/<%=fullPath%>" target="photo">
                <img src="thumb/<%=thumbsize%>/<%=fullPath%>" class="thumbnail" ></a>
                </td>
                <td>
                <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">S</a><br/>
                <a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                    <img border=0 src="addicon.gif" border="0"></a><br/>
                <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                    <img border=0 src="searchicon.gif" border="0"></a><br/>
                <font size="-4" color="#99CC99"><%=value%></font><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="<%=trashIcon%>" border="0"></a>
                </td><td><%=diskName%>:<%=fullPath%>
                </td><%
                    }
                            else if (allPict)
                            {
                                if (firstInRow && false)
                                {
                                    out.write("<td>Row ");
                                    out.write(Integer.toString(rowNum));
                                    out.write("</td>");
                                }
                %>
                <td>
                <a href="photo/<%=fullPath%>" target="photo">
                <img src="thumb/<%=thumbsize%>/<%=fullPath%>" class="thumbnail"></a>
                </td><td>
                <font size="-4" ><%=value%></font><br/>
                <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">
                       S</a><br/>
                <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                       <img border=0 src="searchicon.gif" border="0"></a><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="<%=trashIcon%>" border="0"></a>
                </td>
    <%
        }
                else {
    %>
                <td>
                <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">S</a>
                <a href="photo/<%=fullPath%>" target="photo">
                    <%=truncName%></a></td>
                <td><a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                    <img border=0 src="searchicon.gif" border="0"></a></td>
                <td bgcolor="#FFCCAA"><%=diskName%></td>
                <td>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img src="<%=trashIcon%>" border="0"></a>
                </td>
                <td>(<%
                    if (fileSize>250000) {
                                    out.write("<b><font color=\"red\">"+fileSize+"</font></b>");
                                  } else {
                                    out.write(Integer.toString(fileSize));
                                  }
                %>)
    <%

                    for (String tag : ii.getTagNames()) {
                        HTMLWriter.writeHtml(out, tag);
                        out.write(" \t ");
                    }
                    //suppress duplicate paths
                    String pp = localPath;
                    if (pp.equals(lastPath))
                    {
                        pp = "";
                    }
                    else
                    {
                        lastPath = pp;
                    }
                %>
                <b><%= pp %></b>
                </td>
    <%
            }
            firstInRow = false;
        }
        out.write("</tr>");
        out.flush();
    }

    if (nextStart!=0)
    {
        %><tr><td colspan="7">End of page
        <a href="<%=queryOrder%>&min=<%=prevPage%><%=pictParam%>"><img src="ArrowBack.gif" border="0"></a>
        <%= dispMin %> / <%= recordCount %>
        <a href="<%=queryOrder%>&min=<%=nextStart%><%=pictParam%>">
          <img src="ArrowFwd.gif" border="0"></a> next page:  <%=nextStart%></td></tr><%
    }

%>
</table>
<table>
    <tr><td>Sort by:</td>
        <td bgcolor=#EEEEBB colspan="5">
            <a href="<%=queryNoOrder%>&o=name<%=pictParam%>">Name</a>
            <a href="<%=queryNoOrder%>&o=num<%=pictParam%>">Number</a>
            <a href="<%=queryNoOrder%>&o=rand<%=pictParam%>">Random</a>
            <a href="<%=queryNoOrder%>&o=path<%=pictParam%>">Path</a>
            <a href="<%=queryNoOrder%>&o=size<%=pictParam%>">Size</a>
            </td>
        <td>(currently: <%=order%>)</td></tr>
</table>

<table>
<tr>
   <form method="post" action="move.jsp">
        <td>
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Move:">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="text" name="dest" value="<%HTMLWriter.writeHtml(out,moveDest);%>">
       </td>
   </form>
   <td> &nbsp; &nbsp; &nbsp; &nbsp;</td>
   <form method="post" action="delete.jsp">
       <td>
            <input type="submit" value="Trash <%= recordCount %>"> &nbsp;
            <input type="submit" value="UnTrash <%= recordCount %>" name="untrash">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out,thisPage);%>">
       </td>
   </form>
</tr>
<tr>
    <form action="selectQuery.jsp" method="get">
        <td> <input type="submit" name="set" value="1">
            <input type="submit" name="set" value="2">
            <input type="submit" name="set" value="3">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="hidden" name="dest" value="show.jsp?<%=requestURL%>">
            &nbsp; &nbsp; <a href="showblack.jsp?q=<%=queryOrderPart%>">Display All On Black</a>
         </td>
    </form>
    <td> &nbsp; &nbsp;  &nbsp; &nbsp;</td>
    <form method="post" action="shrinkAll.jsp" target="_blank">
        <td>
            <input type="submit" value="Shrink <%= recordCount %>">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="checkbox" name="doubleCheck" value="ok"> check here to be sure
        </td>
    </form>
</tr>
</table>
<table width="600"><tr>
    <td><form method="GET" action="show.jsp">
        <input type="hidden" name="o" value="<%=order%>">
        <input type="submit" value="Search:">
        <input type="text" size="80" name="q" ng-model="query">
        <input type="text" size="5" name="min" value="<%=dispMin%>">
        <button ng-click="query=query+'n(1,999)'">Only Numbers</button>
    </form></td></tr>
</table>
<table>
    <tr><td><form method="GET" action="renumberIndices.jsp">
        <input type="submit" value="Renumber Indices">
        <input type="hidden" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        <input type="hidden" name="doubleCheck" value="ok">
    </form></td>
    <td><form method="GET" action="threeDigitNumbers.jsp">
        <input type="submit" value="Three Digit Numbers">
        <input type="hidden" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
    </form></td>
    <td><form method="GET" action="normalizeValues.jsp">
        <input type="submit" value="Normalize Minus <%=minValue%>">
        <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        <input type="hidden" name="min" value="<%=minValue%>">
    </form></td>
    <td><form method="GET" action="renumber.jsp">
        <input type="submit" value="Renumber All <%=recordCount%> Files">
        <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        <input type="text" name="newName" value="<%=lastPattern%>">
    </form></td>
    
</tr>    
</table>
<table>
<tr><td>
<form action="setPict.jsp" method="get">
  <input type="submit" value="Set">
  Thumbnail Size: <input type="text" name="thumbsize" size="5" value="<%=thumbsize%>">
  Columns: <input type="text" name="columns" size="5" value="<%=columns%>">
  Rows: <input type="text" name="rows" size="5" value="<%=rows%>">
  List: <input type="text" name="listSize" size="5" value="<%=pageSize%>">
  <input type="hidden" name="pict" value="<%=localPath2%>">
  <input type="hidden" name="go" value="show.jsp?q=<%=queryOrderPart%>">
</form>
</td></tr></table>

<p>
<%
    long duration = System.currentTimeMillis() - starttime;
    
    for (String tag : tagsCount.sortedKeys()) {
        %><a href="show.jsp?q=g(<%=tag%>)"><span><%=tag%> (<%=tagsCount.getCount(tag)%>)</span></a><br/><%
    }
%>
</p>
</td></tr></table>
    <font color="#BBBBBB">page generated in <%=duration%>ms.  </font>
</BODY>
</HTML>

