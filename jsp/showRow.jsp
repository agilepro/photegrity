<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.GridData"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.json.JSONObject"
%><%@page import="org.workcast.json.JSONArray"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null)
    {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pageName = "showRow.jsp";
    String unneededQuery = request.getParameter("q");
    if (unneededQuery!=null)
    {
        throw new Exception("got a query but we don't need one");
    }

    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }
    String query = gData.getQuery();
    gData.singleRow = true;
    Hashtable selectedColumns = gData.getSelectedColumns();





    String requestURL = request.getQueryString();

    String sel = gData.selMode;
    boolean showAll = (sel.equals("all"));
    boolean showSel = (sel.equals("sel"));
    boolean showUnsel = (sel.equals("unsel"));

    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");


    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);
    int pageSize = UtilityMethods.getSessionInt(session, "listSize", 20);

    boolean groupSize = false;    //TODO: eliminate
    boolean groupNum = true;    //TODO: eliminate
    String order = "num";     //TODO: eliminate

    Vector rowMap = gData.getRowMap();
    if (showSel)
    {
        rowMap = gData.getSelectedRowMap();
    }

    int r  = UtilityMethods.defParamInt(request, "r", -999999);
    int rowMin = getRowNumberForValueX(r, rowMap);

    //now test if you are off the high end
    if (rowMin==-1)
    {
        //if the set is small, then set to zero
        rowMin = 0;

        //set 1 from the end if larger than 1 in set
        if (rowMap.size()>1)
        {
            rowMin = rowMap.size()-1;
        }
    }
    if (rowMin<rowMap.size())
    {
        r = ((Integer)rowMap.elementAt(rowMin)).intValue();
    }

    if (rowMin<0)
    {
        rowMin = 0;
    }

    int nextRow = rowMin + 1;
    String nextRowValue = "1000";
    if (nextRow>=rowMap.size())
    {
        nextRow=rowMap.size();
    }
    else
    {
        nextRowValue = rowMap.elementAt(nextRow).toString();
    }
    int prevRow = rowMin - 1;
    if (prevRow < 0)
    {
        prevRow = 0;
    }
    String prevRowValue = "0";
    if (prevRow<rowMap.size())
    {
        prevRowValue = rowMap.elementAt(prevRow).toString();
    }


    //Make a vector of Vectors
    Vector grid = gData.getEntireGrid();

    Vector<String> colVec = gData.getColumnMapWithoutSelectionPrioritization();

    Enumeration e2 = grid.elements();
    String queryOrder = "startGrid.jsp?q="+URLEncoder.encode(query,"UTF8");
    String lastPath = "";
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8");
    String queryOrderPart = queryOrderNoMin+"&r="+r;
    int recordCount = rowMap.size();

    String thisPage = "showRow.jsp?r="+r;

///////////////////////////////////////

    int colNum = 9999;
    int nextStart = 0;
    int lastSize = -1;

    int rowQuant = ((Integer)rowMap.elementAt(rowMin)).intValue();
    Vector<ImageInfo> row = gData.getRow(rowQuant);
    if (row==null) {
        throw new Exception("row '"+rowQuant+"' of grid is inexplicably null.");
    }

    JSONArray rowData = new JSONArray();
    for (String colLoc : colVec) {
        boolean isMarked = (selectedColumns.get(colLoc)!=null);
        JSONObject oneColumn = new JSONObject();
        oneColumn.put("column", colLoc);
        oneColumn.put("isMarked", isMarked);
        ImageInfo sii = null;
        for (ImageInfo ii : row) {
            String column = ii.getPosPat().getSymbol();
            if (!column.equals(colLoc)) {
                //finding the image with a particular column
                continue;
            }
            sii = ii;
            break;
        }
        if (sii==null) {
            sii = gData.defaultImage(colLoc);
            oneColumn.put("isNull", true);
        }
        else {
            oneColumn.put("isNull", sii.isNullImage());
        }
        oneColumn.put("fileName", sii.fileName);
        oneColumn.put("relPath",sii.getRelPath());
        oneColumn.put("fullPath", sii.getFullPath());
        oneColumn.put("patt", sii.getPosPat().getPattern());
        oneColumn.put("symbol", sii.getPosPat().getSymbol());
        oneColumn.put("disk", sii.diskMgr.diskName);
        oneColumn.put("isTrashed", sii.isTrashed);
        JSONArray tags = new JSONArray();
        for (TagInfo ti : sii.tagVec) {
            tags.put(ti.tagName);
        }
        oneColumn.put("tags", tags);        
        rowData.put(oneColumn);
    }

%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<head><TITLE>Show <%= r %> / <%= recordCount %></TITLE>
    <script src="lib/angular.js"></script>

    <script>

    var rowApp = angular.module('rowApp', []);
    rowApp.factory('rowFactory', function($http) {
        return {
            list: function(callback) {
                $http.get('listRow.jsp?dMode=<%=rowMin%>').success(callback);
            }
        }
    });
    rowApp.controller('rowCtrl', function ($scope, $http, rowFactory, $timeout) {
        $scope.showAll = true;
        $scope.thumbsize=<%=thumbsize%>;
        $scope.query="<%=gData.query%>";
        $scope.selected = [];
        $scope.images = <% rowData.write(out,2,0); %>;

        $scope.toggleColumn = function(colName) {
            var pos = $scope.selected.indexOf(colName);
            if (pos >= 0) {
                $scope.selected.remove(pos);
            }
            else {
                $scope.selected.push(colName);
            }
        }
    });

    rowApp.filter('encode', function() {
        return window.encodeURIComponent;
    });

    rowApp.filter('btoa', function() {
        return function (str) {
            return window.btoa(encodeURIComponent(escape(str)));
        }
    });

    rowApp.filter('atob', function() {
        return function(str) {
            return unescape(decodeURIComponent(window.atob(str)));
        }
    });

    </script>

<style>
#content {
    width:100%;
    margin:0 auto;
}
.box {
    float: left;
    display: table;
    height: 118px;
    width: 100px;
    margin:5px;
    background-color:#FFE;
}
</style>

</head>
<body style="background-color:#FDF5FF;" ng-app="rowApp" ng-controller="rowCtrl">


<table><tr><td>

<table><tr>
   <td bgcolor="#FF0000">
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderNoMin%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderNoMin%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
      <a href="compare.jsp">Compare</a>
   </td><td>
      <a href="showGrid.jsp?r=<%=r%>">Grid</a>
   </td><td>
      <a href="showGrid2.jsp?r=<%=r%>">Grid2</a>
   </td></tr>
</table>
<table>
    <tr valign="top"><td colspan="7">
        <table><tr><td>
            <a href="main.jsp"><img src="home.gif" border="0"></a>
            <a href="sel.jsp?set=1" target="sel1">1</a>
            <a href="sel.jsp?set=2" target="sel2">2</a>
            <a href="sel.jsp?set=3" target="sel3">3</a>
            <a href="sel.jsp?set=4" target="sel4">4</a>
            <a href="sel.jsp?set=5" target="sel5">5</a>
        </td><td>
        <a href="showRow.jsp?r=<%=prevRowValue%>"><img src="ArrowBack.gif" border="0"></a>
        @<%= r %>, <%= rowMin %> / <%= recordCount %>
        <a href="showRow.jsp?r=<%=nextRowValue%>"><img src="ArrowFwd.gif" border="0"></a>
        <%

        if (showAll)
        {
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=sel">ShowSelected</a> <%
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=unsel">ShowUnSelected</a> <%
        }
        else if (showSel)
        {
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=all">ShowAll</a> <%
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=unsel">ShowUnSelected</a> <%
        }
        else
        {
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=all">ShowAll</a> <%
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=sel">ShowSelected</a> <%
        }
        %>
        </td><td>
        (<a href="setBound.jsp?r=<%=r%>&op=T&v=-1000"><%=gData.rangeTop%></a>,
        <a href="setBound.jsp?r=<%=r%>&op=B&v=1000"><%=gData.rangeBottom%></a>)
        <%=gData.query%>
        </td></tr></table>
    </td></tr>
</table>

<button ng-show="showAll" ng-click="showAll = false"><img src="radio_on.png"> Show All</button>
<button ng-hide="showAll" ng-click="showAll = true"><img src="radio_off.png"> Show All</button>

<div id="content" style="clear: left">
    <div class="box" ng-repeat="rec in images" ng-show="showAll || rec.isMarked">
        <div style="height:20;">
            <font size="-4" color="#99CC99"><%=rowQuant%></font>
            <img src="radio_on.png" ng-show="rec.isMarked" ng-click="rec.isMarked=false">
            <img src="radio_off.png" ng-hide="rec.isMarked" ng-click="rec.isMarked=true">
            <a href="show.jsp?q={{query+'e('+rec.patt+')'|encode}}"  target="_blank">S</a> &nbsp;
            <a href="manage.jsp?q={{query+'e('+rec.patt+')'|encode}}"><img border=0 src="searchicon.gif"></a> &nbsp;
            <img src="trash.gif" ng-hide="rec.isTrashed" ng-click="rec.isTrashed=true">
            <img src="delicon.gif" ng-show="rec.isTrashed" ng-click="rec.isTrashed=false">
        </div>
    <a href="photo/{{rec.relPath}}" target="photo" ng-hide="rec.isNull">
        <img src="thumb/100/{{rec.relPath}}" width="{{thumbsize}}" border="0" title="{{rec.relPath}}">
    </a>
    <a href="" ng-show="rec.isNull" >
        <img style="opacity:0.2" src="thumb/100/{{rec.relPath}}" width="{{thumbsize}}" border="0" title="{{rec.relPath}}">
    </a>

    </div>
</div>
<div style="clear: left">
</div>
<ol>
    <li ng-repeat="rec in images" ng-show="showAll || rec.isMarked">
        <img src="radio_on.png" ng-show="rec.isMarked" ng-click="rec.isMarked=false">
        <img src="radio_off.png" ng-hide="rec.isMarked" ng-click="rec.isMarked=true">
        {{rec.symbol}}
    </li>
</ol>

<table>
<%
    //do the top info row
    %><tr><td></td><%
    Enumeration cole = colVec.elements();
    %></tr><%


    //this used to be a loop, but this page only has one iteration of that loop, so eliminated
    if (false) {

        int colCount = 0;
        for (String colLoc : colVec)
        {
            boolean isMarked = (selectedColumns.get(colLoc)!=null);
            if (showSel && !isMarked) {
                continue;
            }
            if (showUnsel && isMarked) {
                continue;
            }
            int colonPos = colLoc.lastIndexOf("/");
            String thisPattern = colLoc.substring(colonPos+1);
            String newQ = query+"e("+thisPattern+")";
            out.write("\n<td width=\"{{thumbsize}}");
            if (isMarked)
            {
                out.write("\" bgcolor=\"yellow");
            }
            out.write("\">");
            boolean foundOne = false;
            ImageInfo sii = null;
            for (ImageInfo ii : row)
            {
                String column = "";
                if (!ii.isNullImage()){
                    column = ii.getPosPat().getSymbol();
                }
                if (!column.equals(colLoc)){
                    continue;
                }
                if (foundOne){
                    continue;
                }
                sii = ii;
                foundOne = true;
            }
            if (sii!=null) {

    %>
                <a href="photo/<%=sii.getRelPath()%>" target="photo">
                <img src="thumb/100/<%=sii.getRelPath()%>" width="{{thumbsize}}" border="0"></a>
    <%
            }
            else {
                String dummyImg = "acquireSet/21Sextury/BlueAngel/blue_angel_100334_21_0005.jpg";
                ImageInfo defImg = gData.defaultImage(colLoc);
                if (defImg != null) {
                    dummyImg = defImg.getRelPath();
                }

    %>
                <img style="opacity:0.2" src="thumb/100/<%=dummyImg%>" width="{{thumbsize}}" border="0">
    <%
            }
    %>
            </td>
            <td<%if(isMarked){%> bgcolor="yellow"<%}%> width="20" valign="top">
            <font size="-4" color="#99CC99"><%=rowQuant%></font><br/>
            <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>" target="_blank"
               title="<%HTMLWriter.writeHtml(out,thisPattern);%>">S</a><br/>
            <a href="toggleColumn.jsp?r=<%=r%>&cval=<%=URLEncoder.encode(colLoc,"UTF8")%>&go=<%=URLEncoder.encode(thisPage,"UTF8")%>">&gt;&lt;</a><br/>
    <%
            if (sii!=null) {
                String encodedName = URLEncoder.encode(sii.fileName,"UTF8");
                String encodedPath = URLEncoder.encode(sii.getFullPath(),"UTF8");
                String encodedDisk = URLEncoder.encode(sii.diskMgr.diskName,"UTF8");
                String stdParams = "d="+encodedDisk+"&fn="+encodedName+"&p="+encodedPath;
                String trashIcon = "trash.gif";
                if (sii.isTrashed)
                {
                    trashIcon = "delicon.gif";
                }
    %>

                <a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                    <img border=0 src="addicon.gif"></a><br/>
                <a href="manage.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>"
                   title="<%HTMLWriter.writeHtml(out,thisPattern);%>">
                   <img border=0 src="searchicon.gif"></a><br/>

                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF8")%>">
                   <img border=0 src="<%=trashIcon%>"></a>
    <%
            }
    %>
            </td>
    <%
            if (colCount++>2)
            {
                out.write("</tr><tr>");
                colCount=0;
            }
        }
        %><td> &nbsp;  &nbsp; [<%=rowMin%>]</td><%
        out.write("\n</tr>");
        out.flush();
    }

    if (nextStart!=0)
    {
        %><tr><td colspan="7">That's all for this page. <a href="<%=queryOrder%>&min=<%=nextStart%>">
          Next page</a> starts at <%=nextStart%></td></tr><%
    }



%>
</table>
<table>
    <tr><td><a href="main.jsp"><img src="home.gif" border="0"></a></td>
        </tr>
</table>

<table>
<%
        int count = 0;
        if (false) {
        for (String colLoc : colVec)
        {
            boolean isMarked = (selectedColumns.get(colLoc)!=null);
            if (showSel && !isMarked)
            {
                continue;
            }
            if (showUnsel && isMarked)
            {
                continue;
            }
%>
            <tr><td><%=++count%>: </td><td <% if (isMarked) {%>bgcolor="yellow"<%}%> ><%=colLoc%>
                ( <%=gData.numberInColumn(colLoc)%> )
            <a href="toggleColumn.jsp?r=<%=r%>&cval=<%=URLEncoder.encode(colLoc,"UTF8")%>&go=<%=URLEncoder.encode(thisPage,"UTF8")%>">&gt;&lt;</a><br/>
            </td><form action="delDups.jsp">
                <input type="hidden" name="src" value="<%HTMLWriter.writeHtml(out,colLoc);%>">
                <td><input type="submit" name="action" value="Delete Dups">
                <input type="checkbox" name="doubleCheck" value="true"></td>
            </form>

            </tr>

            <%
            if (isMarked && showSel) {
                Enumeration othere = colVec.elements();
                while (othere.hasMoreElements())
                {
                    String otherLoc = (String) othere.nextElement();
                    boolean otherMarked = (selectedColumns.get(otherLoc)!=null);
                    if (!otherMarked)
                    {
                        continue;
                    }
                    if (colLoc.equals(otherLoc) && selectedColumns.size()>1)
                    {
                        continue;
                    }
                    int colonPos = otherLoc.lastIndexOf("/");
                    String dest = otherLoc.substring(0,colonPos)+"/";
                    String patt = otherLoc.substring(colonPos+1);

            %><tr><form action="delDups.jsp">
                  <input type="hidden" name="src" value="<%HTMLWriter.writeHtml(out,colLoc);%>">
                <td></td>
                <td>Move to: <input type="text" name="newLoc" value="<%HTMLWriter.writeHtml(out,dest);%>" size="50"><br/>
                    Rename to: <input type="text" name="newPatt" value="<%HTMLWriter.writeHtml(out,patt);%>">
                    <input type="submit" name="action" value="Consolidate">
                    <input type="checkbox" name="doubleCheck" value="true"><br/>
                    On Duplicate: <input type="radio" name="dupact" value="delNew" checked="checked"> delete file being moved
                                  <input type="radio" name="dupact" value="delOld"> copy over file</td>

            </form></tr><%
                }
            }
        }
    }
%>
    </table>
<br/>
<hr/>
<br/>
<table width="600">
    <form method="GET" action="startGrid.jsp">
        <tr width="600"><td width="600">
            <input type="hidden" name="o" value="num">
            <input type="submit" value="Change Query:">
            <input type="text" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="min" value="<%=r%>">
        </td></tr>
    </form>

<tr><td>
<form action="setPict.jsp" method="get">
  <input type="submit" value="Set">
  Thumbnail Size: <input type="text" name="thumbsize" size="5" ng-model="thumbsize">{{thumbsize}}
  Columns: <input type="text" name="columns" size="5" value="<%=columns%>">
  Rows: <input type="text" name="rows" size="5" value="<%=rows%>">
  List: <input type="text" name="listSize" size="5" value="<%=pageSize%>">
  <input type="hidden" name="pict" value="<%=localPath%>">
  <input type="hidden" name="go" value="show.jsp?q=<%=queryOrderPart%>">
</form>
</td></tr></table>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.  </font>
</body>
</HTML>

<%!

    public static int getRowNumberForValueX(int photoValue, Vector v)
        throws Exception
    {
        int last = v.size();
        for (int i=0; i<last; i++)
        {
            Integer iVal = (Integer) v.elementAt(i);
            if (iVal.intValue() >= photoValue)
            {
                return i;
            }
        }
        return -1;
    }


%>