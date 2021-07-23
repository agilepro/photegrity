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

    String query = request.getParameter("q");
    String col1 = request.getParameter("col1");
    String col2 = request.getParameter("col2");
    String bias1 = request.getParameter("bias1");
    String bias2 = request.getParameter("bias2");

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pageName = "showGrid.jsp";
    GridData gData = new GridData();
    gData.setQuery(query);
    gData.getSelectedColumns();
    session.setAttribute("gData", gData);

    //Make a vector of Vectors
    JSONObject grid = gData.getJSON();


    int r = 1;


%>
<!DOCTYPE HTML>
<html ng-app="bunchApp">

<style>
.spacy tr td {
    padding:5px;
}
</style>

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
        $scope.col1 = "<%JavaScriptWriter.encode(out,col1);%>";
        $scope.col2 = "<%JavaScriptWriter.encode(out,col2);%>";
        $scope.bias1 = <%JavaScriptWriter.encode(out,bias1);%>;
        $scope.bias2 = <%JavaScriptWriter.encode(out,bias2);%>;
        $scope.ySize = 6;
        $scope.xSize = 6;
        $scope.pinCols = [];
        $scope.pinMap = {};
        $scope.biasMap = {};
        $scope.showCols = [];
        $scope.rowNameToPos = {};
        $scope.onlyPinned = false;
        $scope.singleRow = false;
        $scope.currentRow = 0;
        $scope.currentCol = 0;
        $scope.resultData = [];
        $scope.dataSet.cols.forEach( function(colName) {
            $scope.pinMap[colName] = "unpinned";
            $scope.biasMap[colName] = 0;
        });
        $scope.biasMap[$scope.col1] = $scope.bias1;
        $scope.biasMap[$scope.col2] = $scope.bias2;
        $scope.col1def = $scope.dataSet.defs[$scope.col1];
        $scope.col2def = $scope.dataSet.defs[$scope.col2];
        $scope.col1full = $scope.dataSet.grid[$scope.col1];
        $scope.col2full = $scope.dataSet.grid[$scope.col2];
        
        $scope.showset = [];
        function findItem(searchValue) {
            var foundItem = null;
            $scope.showset.forEach( function(item) {
                if (item.value == searchValue) {
                    foundItem = item;
                }
            });
            if (!foundItem) {
                foundItem = {};
                foundItem.value = searchValue;
                foundItem.result = "";
                $scope.showset.push(foundItem);
            }
            return foundItem;
        }
        function fillItems() {
            if ($scope.col1full) {
                Object.keys($scope.col1full).forEach( function(key) {
                    imgItem = $scope.col1full[key];
                    var itemVal = imgItem.value;
                    if (itemVal<0) {
                        //preserve negative values without bias1
                        var theItem = findItem(itemVal);
                        theItem.img1 = imgItem;
                        theItem.include1 = true;
                        return;
                    }
                    var seekVal = itemVal - $scope.bias1;
                    if (seekVal>=0) {
                        //note that values that go negative due to bias are forgotten
                        var theItem = findItem(seekVal);
                        theItem.img1 = imgItem;
                        theItem.include1 = true;
                    }
                });
            }
            
            if ($scope.col2full) {
                Object.keys($scope.col2full).forEach( function(key) {
                    imgItem = $scope.col2full[key];
                    var itemVal = imgItem.value;
                    if (itemVal<0) {
                        //preserve negative values without bias1
                        var theItem = findItem(itemVal);
                        theItem.img2 = imgItem;
                        theItem.include2 = true;
                        return;
                    }
                    var seekVal = itemVal - $scope.bias2;
                    if (seekVal>=0) {
                        //note that values that go negative due to bias are forgotten
                        var theItem = findItem(seekVal);
                        theItem.img2 = imgItem;
                        theItem.include2 = true;
                    }
                });
            }

            $scope.showset.sort( function(a,b) {
                return (a.value-b.value);
            });
        }
        fillItems();
        console.log("SHOWSET", $scope.showset);
        
        
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
                    image.myRow = modRow;
                    image.include = true;                    
                    return [image];
                }
            }
            var image = $scope.dataSet.defs[col];
            image.isDefault = true;
            image.include = false;
            return [image];
        }
        function findImage(col, offset) {
            if (offset>=0 && offset<top) {
                var row = $scope.dataSet.rows[offset];
                var image = $scope.dataSet.grid[col][row];
                if (image) {
                    image.myRow = row;
                    image.isDefault = false;
                    image.include = true;
                    return image;
                }
            }
            var image = $scope.dataSet.defs[col];
            image.myRow = "???";
            image.isDefault = true;
            image.include = false;
            return image;
        }




        $scope.delCol1 = function(item) {
            item.include1 = !item.include1;
        }
        $scope.delCol2 = function(item) {
            item.include2 = !item.include2;
        }

        $scope.mergeThem = function(item) {
            var batch = [];
            
            $scope.showset.forEach( function(item) {
                var newFileName = makeFileName($scope.col2def.pattern, item.value, ".jpg");
                if (!item.img1) {
                    console.log(item.row+": NULL SOURCE FILE");
                }
                else if (item.img1.isDefault) {
                    console.log(item.row+": NO SOURCE FILE");
                }
                else if (!item.include1) {
                    batch.push(deleteImage(item.img1));
                }
                else if (!item.img2) {
                    batch.push(moveImage(item.img1, $scope.col2def.disk, $scope.col2def.path, $scope.col2def.pattern, item.value, ".jpg"));
                }
                else if (item.img2.isDefault) {
                    batch.push(moveImage(item.img1, $scope.col2def.disk, $scope.col2def.path, $scope.col2def.pattern, item.value, ".jpg"));
                }
                else if (!item.include2) {
                    batch.push(deleteImage(item.img2));
                    batch.push(moveImage(item.img1, $scope.col2def.disk, $scope.col2def.path, $scope.col2def.pattern, item.value, ".jpg"));
                }
                else {
                    batch.push(deleteImage(item.img1));
                }
            });
            
            //var fobj = {list: [batch[0]]};
            var fobj = {list: batch};
            console.log("READY TO SEND! ", fobj);
            var promise = $http.post("api/batchUpdate", fobj);
            promise.success( function(data) {
                processResults(data);
            } );
            promise.error( function(data, status, headers, config) {
                console.log("the POST failed: "+JSON.stringify(data,null,2));
                alert("session update failed: "+JSON.stringify(data,null,2));
            });
            return promise;
        }
        
        function deleteImage(image) {
            console.log(": Deleting: "+image.fileName);
            var op = {};
            op.disk = image.disk;
            op.path = image.path;
            op.fn = image.fileName;
            op.cmd = "del";
            return op;
        }
        function moveImage(image, disk, path, pattern, number, tail) {
            var op = {};
            op.disk = image.disk;
            op.path = image.path;
            op.fn = image.fileName;
            op.disk2 = disk;
            op.path2 = path;
            op.fn2 = makeFileName(pattern, number, tail)
            op.cmd = "move";
            console.log(": Moving: "+image.fileName+" to "+op.fn2);
            console.log(":   full request: ",op);
            return op;
        }
        function makeFileName(pattern, number, tail) {
            var numStr = "";
            if (number==-100) {
                numStr = "000.cover";
            }
            else if (number==-200) {
                numStr = "000.flogo";
            }
            else if (number==-300) {
                numStr = "000.sample";
            }
            else if (number<0) {
                numStr = "!"+(""+(-100+number)).substring(2);
            }
            else {
                numStr = (""+(1000+number)).substring(1);
            }
            return pattern+numStr+tail;
        }
        
        function processResults(data) {
            console.log("PROCESSING RESULTS: ", data);
            var list = data.list;
            list.forEach( function(item) {
                var src = item.src;
                var found = false;
                var op = "UNKNOWN";
                if (item.del) {
                    op = "DELETED";
                }
                if (item.move) {
                    op = "MOVED";
                }
                $scope.showset.forEach( function(showItem) {
                    if (!showItem.img1) {
                        return;
                    }
                    if (src.fn == showItem.img1.fileName) {
                        showItem.result = op;
                        found = true;
                        console.log("    MARKED "+op, item);
                    }
                });
                if (!found) {
                    console.log("DID NOT FIND :", item);
                }
            });
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

<div>
   <button ng_click="mergeThem()">Merge Them</button>
</div>

<table class="spacy">
    <tr>
      <td>#</td>
      <td>No</td>
      <td>Source</td>
      <td> X --- X </td>
      <td>Dest</td>
      <td>#</td>
      <td><button ng_click="mergeThem()">Merge Them</button></tf>
    </tr>
    <tr ng-repeat="item in showset">
        <td>
           {{item.value}}
        </td>
        <td>
           {{item.img1.value}}
        </td>
        <td>
            <a href="photo/{{item.img1.disk}}/{{item.img1.path}}/{{item.img1.fileName}}" target="photo"
               title="{{item.img1.disk}}/{{item.img1.path}}/{{item.img1.fileName}}">
                <img ng-hide="item.include1" style="opacity:0.2"
                     src="thumb/100/{{item.img1.disk}}/{{item.img1.path}}/{{item.img1.fileName}}"/>
                <img ng-show="item.include1"
                     src="thumb/100/{{item.img1.disk}}/{{item.img1.path}}/{{item.img1.fileName}}"/>
            </a>
        </td>
        <td> <a ng-click="delCol1(item)"><img border=0 src="trash.gif"></a>
             ---
             <a ng-click="delCol2(item)"><img border=0 src="trash.gif"></a> 
        </td>
        <td>
            <a href="photo/{{item.img2.disk}}/{{item.img2.path}}/{{item.img2.fileName}}" target="photo"
               title="{{item.img2.disk}}/{{item.img2.path}}/{{item.img2.fileName}}">
                <img ng-hide="item.include2" style="opacity:0.2"
                     src="thumb/100/{{item.img2.disk}}/{{item.img2.path}}/{{item.img2.fileName}}"/>
                <img ng-show="item.include2"
                     src="thumb/100/{{item.img2.disk}}/{{item.img2.path}}/{{item.img2.fileName}}"/>
            </a>
        </td>
        <td>
           {{item.img2.value}}
        </td>
        <td> 
           <div ng-hide="item.img1.isDefault">
           {{item.img1.disk}}:{{item.img1.path}}{{item.img1.fileName}}
           </div>
           -------------------
           <div ng-hide="item.img2.isDefault">
           {{item.img2.disk}}:{{item.img2.path}}{{item.img2.fileName}}<br/>
           </div>
           <div style="color:red">
           {{item.result}}
           </div>
        </td>

    </tr>
</table>
</div>


</body>
</html>
