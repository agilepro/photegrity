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
%><%@page import="org.workcast.streams.JavaScriptWriter"
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

    String pageName = "showGrid.jsp";
    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }


    //Make a vector of Vectors
    JSONObject grid = gData.getJSON();


    int r = 1;
    String query = gData.getQuery();
    String queryOrder = "startGrid.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrderRow = queryOrder+"&r="+r;
    String lastPath = "";
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8");
    String queryOrderPart = queryOrderNoMin+"&r="+r;


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
        $scope.dataSet.rows.sort();
        $scope.ySize = 6;
        $scope.xSize = 6;
        $scope.pinCols = [];
        $scope.pinMap = {};
        $scope.biasMap = {};
        $scope.showCols = [];
        $scope.showRows = [];
        $scope.rowNameToPos = {};
        $scope.onlyPinned = false;
        $scope.singleRow = false;
        $scope.currentRow = 0;
        $scope.currentCol = 0;
        $scope.dataSet.cols.forEach( function(colName) {
            $scope.pinMap[colName] = "unpinned";
            $scope.biasMap[colName] = 0;
        });
        var rowPoz = 0;
        $scope.dataSet.rows.forEach( function(rowName) {
            $scope.rowNameToPos[rowName] = rowPoz;
            rowPoz++;
        });
        
        
        
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
            var colrecs = $scope.dataSet.grid[col];
            var bias = $scope.biasMap[col];
            if (colrecs) {
                var rowOffset = $scope.rowNameToPos[row];
                var modRow = $scope.dataSet.rows[rowOffset+bias];
                var image = colrecs[modRow];
                if (image) {
                    return [image];
                }
            }
            var image = $scope.dataSet.defs[col];
            image.isDefault = true;
            return [image];
        }
        $scope.findBias = function() {
            $scope.dataSet.cols.forEach( function(colName) {
                var offset = 0;
                $scope.biasMap[colName] = -1;
                var colSet = $scope.dataSet.grid[colName];
                $scope.dataSet.rows.forEach( function(rowName) {
                    if (colSet[rowName]) {
                        if ($scope.biasMap[colName]==-1) {
                            $scope.biasMap[colName] = offset;
                        }
                    }
                    offset++;
                });
            });
        }
        $scope.colDown = function(colName) {
            $scope.biasMap[colName]--;
        }
        $scope.colUp = function(colName) {
            $scope.biasMap[colName]++;
        }
        $scope.clearBias = function() {
            $scope.dataSet.cols.forEach( function(colName) {
                $scope.biasMap[colName] = 0;
            });
        }
        $scope.setRow = function(rowTarget) {
            var maxRow = $scope.dataSet.rows.length;
            if (rowTarget > maxRow - $scope.ySize) {
                rowTarget = maxRow - $scope.ySize;
            }
            if (rowTarget<0) {
                rowTarget=0;
            }
            var max = rowTarget + $scope.ySize;
            if (max > maxRow) {
                max = maxRow;
            }
            var finalList = [];
            for (var i=rowTarget; i<max; i++) {
                finalList.push($scope.dataSet.rows[i]);
            }
            $scope.currentRow = rowTarget;
            $scope.showRows = finalList;
        }
        $scope.setRow(0);
        $scope.setCol = function(colTarget) {
            if ($scope.onlyPinned) {
                $scope.showCols = $scope.pinCols;
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
            console.log("showCols", $scope.showCols);
        }
        $scope.setCol(0);
        $scope.pin = function(colTarget) {
            console.log("----------------pinning", colTarget);
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
            
            console.log("PINLIST", $scope.pinCols);
            console.log("PINMAP", $scope.pinMap);
            
            $scope.setCol($scope.currentCol);
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
   </td></tr>
</table>
<button ng-click="setRow(currentRow+1)">Down</button>
<button ng-click="setRow(currentRow-1)">Up</button>
<button ng-click="setCol(currentCol-1)">Left</button>
<button ng-click="setCol(currentCol+1)">Right</button>
<button ng-click="togglePin()">
    <span class="glyphicon glyphicon-check" ng-show="onlyPinned"></span>           
    <span class="glyphicon glyphicon-unchecked" ng-hide="onlyPinned"></span>           
    Only Pinned
</button>
<button ng-click="toggleSingleRow()">
    <span class="glyphicon glyphicon-check" ng-show="singleRow"></span>           
    <span class="glyphicon glyphicon-unchecked" ng-hide="singleRow"></span>           
    Single Row
</button>
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

        <td>
           {{row}}
        </td>
        <td ng-repeat="col in showCols" class="{{pinMap[col]}}">
            <div ng-repeat="image in imageOrDefault(col,row)">
                <a href="photo/{{image.disk}}/{{image.path}}/{{image.fileName}}" target="photo">
                    <img ng-show="image.isDefault" style="opacity:0.2" 
                         src="thumb/100/{{image.disk}}/{{image.path}}/{{image.fileName}}"/>
                    <img ng-hide="image.isDefault" 
                         src="thumb/100/{{image.disk}}/{{image.path}}/{{image.fileName}}"/>
                </a>
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
            <a href="show.jsp?q={{query}}e({{stripPath(col)}})" target="_blank">S</a>
        </td>
    </tr>
</table>
</div>


<div ng-show="singleRow">{{showRows[0]}}
        <div ng-repeat="col in dataSet.cols" class="{{pinMap[col]}}" style="float:left;padding:5px">
            <div ng-repeat="image in imageOrDefault(col,showRows[0])">
                <button ng-click="pin(col)">
               <span class="glyphicon glyphicon-check" ng-show="pinMap[col]=='pinned'"></span>           
               <span class="glyphicon glyphicon-unchecked" ng-hide="pinMap[col]=='pinned'"></span>           
               pin</button><br/>
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
</body>
</html>
