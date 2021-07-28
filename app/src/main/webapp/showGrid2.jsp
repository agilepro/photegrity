<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.GridData"
%><%@page import="com.purplehillsbooks.photegrity.TagInfo"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null)
    {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pageName = "showGrid.jsp";
    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }
    gData.setQuery(gData.getQuery());
    gData.reindex(); 
    Vector<ImageInfo> row = gData.getRow(0);
    
    //Make a vector of Vectors
    JSONObject grid = gData.getJSON();


    int r = UtilityMethods.defParamInt(request, "r", 1);
    int c = UtilityMethods.defParamInt(request, "c", 0);
    String query = gData.getQuery();
    String queryOrder = "startGrid.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrderRow = queryOrder+"&r="+r;
    String lastPath = "";
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8");
    String queryOrderPart = queryOrderNoMin+"&r="+r;

/*
$scope.dataSet = {
   "cols": [
        "euro_sets:tiny_com_es/bruthin/Angelica/ZKC",
        "euro_sets:tiny_com_es/bruthin/KQR"
    ],
    "defs": {
        "euro_sets:tiny_com_es/FXR": {
            "disk": "euro_sets",
            "fileName": "FXR108.jpg",
            "fileSize": 83409,
            "path": "tiny_com_es/",
            "pattern": "FXR",
            "tags": [
                "euro_sets",
                "tiny_com_es"
            ],
            "value": 108
        },
        "euro_sets:tiny_com_es/JCX": {
            "disk": "euro_sets",
            "fileName": "JCX262.jpg",
            "fileSize": 122415,
            "path": "tiny_com_es/",
            "pattern": "JCX",
            "tags": [
                "euro_sets",
                "tiny_com_es"
            ],
            "value": 262
        }
    },
    "grid": {
        "euro_sets:tiny_com_es/FXR": {
            "108": {
                "disk": "euro_sets",
                "fileName": "FXR108.jpg",
                "fileSize": 83409,
                "path": "tiny_com_es/",
                "pattern": "FXR",
                "tags": [
                    "euro_sets",
                    "tiny_com_es"
                ],
                "value": 108
            },
            "109": {
                "disk": "euro_sets",
                "fileName": "FXR109.jpg",
                "fileSize": 95457,
                "path": "tiny_com_es/",
                "pattern": "FXR",
                "tags": [
                    "euro_sets",
                    "tiny_com_es"
                ],
                "value": 109
            }
        },
        "euro_sets:tiny_com_es/blomid/QHZ": {
            "816": {
                "disk": "euro_sets",
                "fileName": "QHZ816.jpg",
                "fileSize": 69610,
                "path": "tiny_com_es/blomid/",
                "pattern": "QHZ",
                "tags": [
                    "blomid",
                    "euro_sets",
                    "tiny_com_es"
                ],
                "value": 816
            }
        }
    },
    "rows": [
        "800",
	    "801"
    ]
}

*/
    
    
    
%>
<!DOCTYPE HTML>
<html ng-app="bunchApp">
<head>
<TITLE></TITLE>

    <script type="text/javascript" src="lib/angular.js"></script>
    <script type="text/javascript" src="lib/ui-bootstrap-tpls.min.js"></script>
    <script type="text/javascript" src="lib/jquery.min.js"></script>
    <script type="text/javascript" src="lib/bootstrap.min.js"></script>
<link href="//netdna.bootstrapcdn.com/bootstrap/3.3.2/css/bootstrap.min.css" rel="stylesheet">
<script src="//netdna.bootstrapcdn.com/bootstrap/3.3.2/js/bootstrap.min.js"></script>
    
<script>

    var bunchApp = angular.module('bunchApp', ['ui.bootstrap']);
    bunchApp.controller('bunchCtrl', function ($scope, $http, $timeout) {
        $scope.query = "<%JavaScriptWriter.encode(out,query);%>";
        $scope.dataSet = <% grid.write(out, 2, 2); %>;
        $scope.dataSet.cols.sort();
        $scope.dataSet.rows.sort(function(a,b){
            return Number(a)-Number(b);
        });
        $scope.ySize = 5;
        $scope.xSize = 6;
        $scope.pinCols = [];
        $scope.pinMap = {};
        $scope.biasMap = {};
        $scope.showCols = [];
        $scope.allRows = [];
        $scope.showRows = [];
        $scope.rowNameToPos = {};
        $scope.onlyPinned = false;
        $scope.singleRow = false;
        $scope.currentRow = <%=r%>;
        $scope.currentCol = <%=c%>;
        $scope.imageCount = {};
        $scope.dataSet.cols.forEach( function(colName) {
            $scope.pinMap[colName] = "unpinned";
            $scope.biasMap[colName] = 0;
            $scope.imageCount[colName] = Object.keys($scope.dataSet.grid[colName]).length;
        });
        var rowPoz = 0;
        
        $scope.fastConvert = {};
        for (var i=10; i<100; i++) {
            $scope.fastConvert[i] = "0"+i.toString();
        }
        for (var i=100; i<1000; i++) {
            $scope.fastConvert[i] = i.toString();
        }
        $scope.fastConvert[-300] = "-300";
        $scope.fastConvert[-200] = "-200";
        $scope.fastConvert[-100] = "-100";
        $scope.fastConvert[0] = "000";
        $scope.fastConvert[1] = "001";
        $scope.fastConvert[2] = "002";
        $scope.fastConvert[3] = "003";
        $scope.fastConvert[4] = "004";
        $scope.fastConvert[5] = "005";
        $scope.fastConvert[6] = "006";
        $scope.fastConvert[7] = "007";
        $scope.fastConvert[8] = "008";
        $scope.fastConvert[9] = "009";
        $scope.fastConvert[-1] = "-1";
        $scope.fastConvert[-2] = "-2";
        $scope.fastConvert[-3] = "-3";
        $scope.fastConvert[-4] = "-4";
        $scope.fastConvert[-5] = "-5";
        $scope.fastConvert[-6] = "-6";
        $scope.fastConvert[-7] = "-7";
        $scope.fastConvert[-8] = "-8";
        $scope.fastConvert[-9] = "-9";
        
        
        
        $scope.imageUrl = function(col, row) {
            var colrecs = $scope.dataSet.grid[col];
            if (!colrecs) {
                return "removeicon.gif";
            }
            var image = colrecs[row];
            if (image) {
                return "thumb/100/" + image.disk + "/" + image.path + "/" + image.fileName;
            }
            image = $scope.dataSet.defs[col];
            return "thumb/100/" + image.disk + "/" + image.path + "/" + image.fileName;
        }
        $scope.imageOrDefault = function(col, row) {
            var rowVal = parseInt(row);
            var rowNumForCol = rowVal + $scope.biasMap[col];
            var newRowName = $scope.fastConvert[rowNumForCol];
            var colrecs = $scope.dataSet.grid[col];
            if (colrecs) {
                var image = colrecs[newRowName];
                if (image) {
                    return [image];
                }
            }
            var image = $scope.dataSet.defs[col];
            image.isDefault = true;
            return [image];
        }
        $scope.findBias = function() {
            var curRowName = $scope.allRows[$scope.currentRow];
            $scope.dataSet.cols.forEach( function(colName) {
                var offset = 0;
                $scope.biasMap[colName] = -1;
                var colSet = $scope.dataSet.grid[colName];
                var bias = 999;
                Object.keys(colSet).forEach( function(key) {
                    var keyVal = parseInt(key);
                    if (keyVal>=0 && keyVal<bias) {
                        bias = keyVal;
                    }
                });
                if (bias>0) {
                    $scope.biasMap[colName] = bias;
                }
                else {
                    $scope.biasMap[colName] = 0;
                }
            });
            findAllRows();
            $scope.setRowFromValue(curRowName);
        }
        $scope.colDown = function(colName) {
            var curRowName = $scope.allRows[$scope.currentRow];
            $scope.biasMap[colName]--;
            findAllRows();
            $scope.setRowFromValue(curRowName);
        }
        $scope.colUp = function(colName) {
            var curRowName = $scope.allRows[$scope.currentRow];
            $scope.biasMap[colName]++;
            findAllRows();
            $scope.setRowFromValue(curRowName);
        }
        $scope.clearBias = function() {
            $scope.dataSet.cols.forEach( function(colName) {
                $scope.biasMap[colName] = 0;
            });
        }
        $scope.setRowFromValue = function(rowVal) {
            var newTarget = $scope.currentRow;
            for (var i=0; i<$scope.allRows.length; i++) {
                if (rowVal == $scope.dataSet.rows[i]) {
                    newTarget = i;
                }
            }
            $scope.setRow(newTarget);
        }
        
        function findAllRows() {
            var allRows = [];
            if (someColumnHasRowValue(-300)) {
                allRows.push($scope.fastConvert[-300]);
            }
            if (someColumnHasRowValue(-200)) {
                allRows.push($scope.fastConvert[-200]);
            }
            if (someColumnHasRowValue(-100)) {
                allRows.push($scope.fastConvert[-100]);
            }
            for (var i = -9; i<1000; i++) {
                if (someColumnHasRowValue(i)) {
                    allRows.push($scope.fastConvert[i]);
                }
            }
            console.log("findAllRows", allRows);
            $scope.allRows = allRows;
            
            $scope.rowNameToPos = {};
            for (var i=0; i<allRows.length; i++) {
                $scope.rowNameToPos[allRows[i]] = i;
            }
        }
        function someColumnHasRowValue(rowVal) {
            var res = false;
            $scope.dataSet.cols.forEach( function(col) {
                var thisCol = $scope.dataSet.grid[col];
                if (rowVal<0) {
                    if ($scope.fastConvert[rowVal] in thisCol) {
                        res = true;
                    }
                }
                else {
                    var rowValForCol = rowVal + $scope.biasMap[col];
                    if (rowValForCol>=0 && rowValForCol<=999 && $scope.fastConvert[rowValForCol] in thisCol) {
                        res = true;
                    }
                }
            });
            return res;
        }
        findAllRows();
        
        $scope.setRow = function(rowTarget) {
            //make sure it is a valid index into allRows
            var maxRow = $scope.allRows.length;
            if (rowTarget > maxRow - $scope.ySize) {
                rowTarget = maxRow - $scope.ySize;
            }
            if (rowTarget<0) {
                rowTarget=0;
            }
            
            //calculate the stop
            var max = rowTarget + $scope.ySize;
            if (max > maxRow) {
                max = maxRow;
            }
            
            var finalList = [];
            finalList.push($scope.allRows[rowTarget]);
            var yCount = $scope.ySize-1;
            var pos=rowTarget+1;
            while (yCount>0 && pos<$scope.allRows.length) {
                var atLeastOne = false;
                var rowName = $scope.allRows[pos];
                $scope.showCols.forEach( function(col) {
                    var image = $scope.imageOrDefault(col, rowName)[0];
                    if (!image.isDefault) {
                        atLeastOne=true;
                    }
                });
                if (atLeastOne) {
                    finalList.push(rowName);
                    yCount--;
                }
                pos++;
            }
            $scope.currentRow = rowTarget;
            $scope.showRows = finalList;
        }
        $scope.setRow($scope.currentRow);
        $scope.setCol = function(colTarget) {
            if ($scope.onlyPinned) {
                $scope.showCols = $scope.pinCols;
                $scope.setRow($scope.currentRow);
                return;
            }
            var maxCol = $scope.dataSet.cols.length;
            if (colTarget > maxCol - $scope.xSize) {
                colTarget = maxCol - $scope.xSize;
            }
            if (colTarget<0) {
                colTarget=0;
            }
            var realSize = $scope.xSize - $scope.pinCols.length;
            console.log("maxCol: "+maxCol+" / $scope.xSize: "+$scope.xSize+" / realSize: "+realSize);
            var max = colTarget + realSize;
            if (max > maxCol) {
                max = maxCol;
            }
            var finalList = [];
            $scope.pinCols.forEach( function(item) {
                finalList.push(item);
            });
            var i=colTarget;
            while (i<maxCol && finalList.length < $scope.xSize) {
                var thisCol = $scope.dataSet.cols[i];
                if ($scope.pinMap[thisCol]!="pinned") {
                    finalList.push(thisCol);
                }
                i++;
            }
            $scope.currentCol = colTarget;
            $scope.showCols = finalList;
            $scope.setRow($scope.currentRow);
        }
        $scope.setCol($scope.currentCol);
        $scope.setColByName = function(newName) {
            for (var i=0; i<$scope.dataSet.cols.length; i++) {
                if (newName == $scope.dataSet.cols[i]) {
                    $scope.setCol(i);
                    console.log("Found", newName, i);
                }
            }
        }
        $scope.pin = function(colTarget) {
            var isPinned = $scope.pinCols.includes(colTarget);
            
            if (isPinned) {
                var newPin = [];
                $scope.pinCols.forEach(function(item) {
                   if (item != colTarget) {
                       newPin.push(item);
                   } 
                });
                $scope.pinCols = newPin;
                $scope.pinMap[colTarget] = "unpinned";
            }
            else {
                $scope.pinCols.push(colTarget);
                $scope.pinMap[colTarget] = "pinned";
            }
            
            $scope.setCol($scope.currentCol);
        }
        
        function recalcResults() {
            var colcount = 6;
            var rowcount = 6;
            
        }
        
        
        $scope.togglePin = function() {
            $scope.onlyPinned = !$scope.onlyPinned;
            $scope.setCol($scope.currentCol);
        }
        $scope.toggleSingleRow = function() {
            $scope.singleRow = !$scope.singleRow;
        }
        $scope.stripPath = function(path) {
            var pos = path.lastIndexOf("/");
            return (path.substring(pos+1));
        }
        
        $scope.mergeLeft = function() {
            if ($scope.pinCols.length!=2) {
                throw "Problem that pinCols is not exclusively 2 columns to manipulate";
            }
            
            mergeColumns($scope.pinCols[1], $scope.pinCols[0]);
        }
        $scope.mergeRight = function() {
            if ($scope.pinCols.length!=2) {
                throw "Problem that pinCols is not exclusively 2 columns to manipulate";
            }
            
            mergeColumns($scope.pinCols[0], $scope.pinCols[1]);
        }
        
        function mergeColumns(sourceCol, destCol) {
            console.log("col1", sourceCol);
            console.log("col2", destCol);
            var url = "mergeSets.jsp?q="+encodeURIComponent($scope.query)
            +"&col1="+encodeURIComponent(sourceCol)
            +"&bias1="+$scope.biasMap[sourceCol]
            +"&col2="+encodeURIComponent(destCol)
            +"&bias2="+$scope.biasMap[destCol];
            window.open(url);
        }
        
        $scope.getSingleRow = function() {
            if ($scope.singleRow) {
                return $scope.dataSet.cols;
            }
            else {
                return [];
            }
        }
        
        $scope.listOneColumn = function(col) {
            var url = "show.jsp?q="+encodeURIComponent($scope.query+"e("+$scope.stripPath(col)+")");
            window.open(url);
        }
        
        $scope.refresh = function() {
            var newLoc = "showGrid2.jsp?r="+$scope.currentRow+"&c="+$scope.currentCol;
            window.location = newLoc;
        }
        
    });
    bunchApp.filter('encodeURIComponent', function() {
        return window.encodeURIComponent;<!--  www . jav  a  2 s . c o m-->
    });
</script>
</head>


<body ng-controller="bunchCtrl">



<style>
.pinned {
    background-color: bisque;
}
.unpinned {
    background-color: white;
}
.spacey tr td {
    padding: 5px;
}
</style>


<table class="spacey"><tr>
   <td>
       <a href="main.jsp"><img src="home.gif" border="0"></a>
   </td>
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
      <a href="showRow.jsp?r=<%=r%>">Row</a>
   </td><td>
      <a href="showGrid.jsp?r=<%=r%>">Grid1</a>
      ({{currentRow}} - {{allRows[currentRow]}}) 
      ({{currentCol}} - {{allRows[currentRow]}}) 
   </td></tr>
</table>
<div>
    <table><tr>
    <td>
    <button ng-click="setCol(currentCol-1)">Left</button>
    </td><td>
    <button ng-click="setRow(currentRow-1)">Up</button><br/>
    <button ng-click="setRow(currentRow+1)">Down</button>
    </td><td>
    <button ng-click="setRow(currentRow-10)">Up 10</button><br/>
    <button ng-click="setRow(currentRow+10)">Down 10</button>
    </td><td>
    <button ng-click="setCol(currentCol+1)">Right</button>
    </td><td>
    <button ng-click="togglePin()">
        <span class="glyphicon glyphicon-check" ng-show="onlyPinned"></span>           
        <span class="glyphicon glyphicon-unchecked" ng-hide="onlyPinned"></span>           
        Only Pinned
    </button><br/>
    <button ng-click="toggleSingleRow()">
        <span class="glyphicon glyphicon-check" ng-show="singleRow"></span>           
        <span class="glyphicon glyphicon-unchecked" ng-hide="singleRow"></span>           
        Single Row
    </button>
    </td>
    <td>
    <button ng-show="onlyPinned && pinCols.length==2" ng-click="mergeLeft()">Merge Left</button>
    <button ng-show="onlyPinned && pinCols.length==2" ng-click="mergeRight()">Merge Right</button>
    </td>
    <td>
    <button ng-hide="onlyPinned && pinCols.length==2" ng-click="refresh()">Refresh</button>
    </br>{{currentRow}}-{{currentCol}}
    </td>
    </tr></table>
    
</div>
<div ng-hide="singleRow">
    <table class="spacey">
    <tr>
        <td>
        </td>
        <td ng-repeat="col in showCols">
           <button ng-click="pin(col)">
               <span class="glyphicon glyphicon-check" ng-show="pinMap[col]=='pinned'"></span>           
               <span class="glyphicon glyphicon-unchecked" ng-hide="pinMap[col]=='pinned'"></span>           
               pin</button>
        </td>
    </tr>

    <tr ng-repeat="row in showRows">

        <td ng-click="setRowFromValue(row)" style="cursor:pointer">
           {{row}}
        </td>
        <td ng-repeat="col in showCols" class="{{pinMap[col]}}">
            <div ng-repeat="image in imageOrDefault(col,row)">
                <div ng-show="image.isDefault">
                    <img style="opacity:0.2" 
                             src="thumb/100/{{image.disk}}/{{image.path}}/{{image.fileName}}"/><br/>
                    <span>- - -</span>
                </div>
                <div ng-hide="image.isDefault">
                    <a href="photo/{{image.disk}}/{{image.path}}/{{image.fileName}}" target="photo">
                    <img src="thumb/100/{{image.disk}}/{{image.path}}/{{image.fileName}}"/>
                    </a><br/>
                    <span>{{image.value}}</span>
                </div>
            </div>
        </td>

    </tr>
    <tr>
        <td>
        </td>
        <td ng-repeat="col in showCols">
            <button ng-click="colDown(col)">-</button>
            {{biasMap[col]}}
            <button ng-click="colUp(col)">+</button>
        </td>
    </tr>
    <tr>
        <td>
        </td>
        <td ng-repeat="col in showCols">
            <button ng-click="listOneColumn(col)"><i class="glyphicon glyphicon-share"></i></button>
            ({{imageCount[col]}})
        </td>
    </tr>
</table>
</div>


<div ng-show="singleRow">{{showRows[0]}}
        <div ng-repeat="col in getSingleRow()" class="{{pinMap[col]}}" style="float:left;padding:5px">
            <div ng-repeat="image in imageOrDefault(col,showRows[0])">
                <button ng-click="pin(col)">
               <span class="glyphicon glyphicon-check" ng-show="pinMap[col]=='pinned'"></span>           
               <span class="glyphicon glyphicon-unchecked" ng-hide="pinMap[col]=='pinned'"></span>           
               pin</button>{{image.value}} 
               <button ng-click="setColByName(col)">X</button><br/>
                <a href="photo/{{image.disk}}/{{image.path}}/{{image.fileName}}" target="photo">
                    <img ng-show="image.isDefault" style="opacity:0.2" 
                         src="thumb/100/{{image.disk}}/{{image.path}}/{{image.fileName}}"/>
                    <img ng-hide="image.isDefault" 
                         src="thumb/100/{{image.disk}}/{{image.path}}/{{image.fileName}}"/>
                </a>
            </div>
        </div>
</div>


<div style="clear:both"></div>
<hr/>
<ul>
<li ng-repeat="col in showCols" class="{{pinMap[col]}}">{{col}}</li>
</ul>

<button ng-click="findBias()">Find Bias</button>
<button ng-click="clearBias()">Clear Bias</button>
<button ng-click="xxx()">FindAllRows</button>
<pre>{{showCols|json}}</pre>
<pre>{{showRows|json}}</pre>
</body>
</html>
