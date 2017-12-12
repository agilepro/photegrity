<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounterIgnoreCase"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.LocalMapping"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Stack"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";
    String groupName = "alt.binaries.pictures.erotica.latina";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    groupName = newsGroup.getName();


    String dig = UtilityMethods.reqParam(request, "News Files Listing", "d");
    String f = UtilityMethods.reqParam(request, "News Files Listing", "f");
    String sort= UtilityMethods.defParam(request, "sort", "dig");
    String thisPage = "newsFiles.jsp?d="+URLEncoder.encode(dig,"UTF-8")+"&f="+URLEncoder.encode(f,"UTF-8");

    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig, f);

    boolean hasData = bunch.hasTemplate();

    String folder = bunch.getFolderLoc();
    boolean folderExists = bunch.hasFolder();
    File   folderPath = bunch.getFolderPath();
    File[] folderChildren = new File[0];
    if (folderPath.exists()) {
        folderChildren = folderPath.listFiles();
        if (folderChildren==null) {
            //fix broken logic of system call.  Should never return null!
            folderChildren = new File[0];
        }
    }

    Vector<String> tagList = new Vector<String>();
    boolean isTag = false;

    DiskMgr mgr = DiskMgr.getDiskMgrOrNull(newsGroup.groupName);
    if (mgr==null) {
        //throw new Exception("need to create disk manager for "+newsGroup.groupName);
    }

    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector<String>();
        session.setAttribute("destVec", destVec);
    }
    while (destVec.size()>8) {
        destVec.remove(8);
    }

    String zingpat = (String) session.getAttribute("zingpat");
    String queueMsg = "("+NewsAction.getActionCount()+" tasks)";

    HashCounterIgnoreCase tagCache = new HashCounterIgnoreCase();
    ImageInfo.parsePathTags(tagCache, folder);
    JSONArray lastPaths = new JSONArray();
    for (String destVal : destVec) {
        lastPaths.put(destVal);
    }

%>
<html ng-app="fileApp">
<head>
    <meta charset="UTF-8">
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls-0.12.0.js"></script>
    <style>
    body {
        padding: 5;
    }
    table {
        table-layout:fixed;
        overflow: hidden;
    }
    .trSelected {
        outline: dotted red;
    }
    .menuBox {
        outline: dotted yellow;
        background-color: LightYellow;
        padding: 8px;
    }
    td {
        border-width: 1px;
        border-color: white;
        border-style: solid;
        white-space: nowrap;
        overflow: hidden;
        padding: 2;
    }
    .cellPicked {
        background-color: yellow;
    }
    .position-fixed {
        position: fixed;
    }
    </style>

    <script>

    var fileApp = angular.module('fileApp', []);
    fileApp.factory('fileFactory', function($http) {
        return {
            listFiles: function(callback) {
                $http.get('listFiles.jsp?d=<%=URLEncoder.encode(dig,"UTF-8")%>&f=<%=URLEncoder.encode(f,"UTF-8")%>')
                .success(callback)
                .error( function(data) {
                    alert(JSON.stringify(data,null,2));
                });
            },
            getBunch: function(callback) {
                $http.get('getBunch.jsp?dig=<%=URLEncoder.encode(dig,"UTF-8")%>&f=<%=URLEncoder.encode(f,"UTF-8")%>')
                .success(callback)
                .error( function(data) {
                    alert(JSON.stringify(data,null,2));
                });
            }
        }
    });
    fileApp.controller('fileCtrl', function ($scope, $http,  $timeout, fileFactory) {
        $scope.digest = "<%JavaScriptWriter.encode(out, dig);%>";
        $scope.f = "<%JavaScriptWriter.encode(out, f);%>";
        $scope.bunch = <% bunch.getJSON().write(out,2,0); %>;
        $scope.refetchData = function() {
            $scope.opResult = $scope.opResult + " *refresh"+$scope.counter++;
            fileFactory.listFiles( function(data) {
                $scope.fileSet = data;
            });
            fileFactory.getBunch( function(data) {
                $scope.bunch = data;
                $scope.divideStates();
            });
        }

        $scope.lastPaths = <%lastPaths.write(out,2,0);%>;
        $scope.folder = "<%HTMLWriter.writeHtml(out, folder);%>";
        $scope.refetchData();
        $scope.thisPath = "newsFiles.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>";
        $scope.getFiltered = function() {
			if (!$scope.showDownloaded) {
				return $scope.fileSet;
			}
            return $scope.fileSet.filter(function(item) {
				return item.fileExists;
			});
        }
        $scope.bunchActionPath = "bunchAction.jsp?dig=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>";
        $scope.opResult = "";

        $scope.divideStates = function() {
            $scope.qHide = "no";
            $scope.qInt  = "no";
            $scope.qSeek = "no";
            $scope.qDown = "no";
            $scope.qComp = "no";
            if ($scope.bunch.state == 7) {
                $scope.qHide = "yes";
            }
            else if ($scope.bunch.state == 9) {
                $scope.qInt  = "active";
            }
            else if ($scope.bunch.state == 1) {
                $scope.qInt  = "yes";
            }
            else if ($scope.bunch.state == 2) {
                $scope.qInt  = "yes";
                $scope.qSeek = "active";
            }
            else if ($scope.bunch.state == 3) {
                $scope.qInt  = "yes";
                $scope.qSeek = "done";
            }
            else if ($scope.bunch.state == 4) {
                $scope.qInt  = "yes";
                $scope.qSeek = "done";
                $scope.qDown = "active";
            }
            else if ($scope.bunch.state == 5) {
                $scope.qInt  = "yes";
                $scope.qSeek = "done";
                $scope.qDown = "done";
            }
            else if ($scope.bunch.state == 6) {
                $scope.qInt  = "yes";
                $scope.qSeek = "done";
                $scope.qDown = "done";
                $scope.qComp = "done";
            }
        };

        $scope.deleteFile = function(searchName) {
            var length = $scope.fileSet.length;
            for(var j = 0; j < length; j++) {
                var rec = $scope.fileSet[j];
                if (rec.fileName == searchName) {
                    rec.needSave = true;
                    $http.get("newsFileDelJS.jsp?fn="+encodeURIComponent(rec.bestName)+"&dig="+encodeURIComponent($scope.digest))
                    .success( function(data) {
                        $scope.opResult = "Delete ("+searchName+": "+data;
                    });
                }
            }
        };
        $scope.fetchFile = function(searchName) {
            var length = $scope.fileSet.length;
            for(var j = 0; j < length; j++) {
                var rec = $scope.fileSet[j];
                if (rec.fileName == searchName) {
                    rec.isDownloading = true;
                    $http.get("newsFileFetchJS.jsp?fn="+encodeURIComponent(rec.bestName)+"&dig="+encodeURIComponent($scope.digest)
                               +"&f="+encodeURIComponent($scope.f))
                    .success( function(data) {
                        $scope.opResult = "Fetch ("+searchName+"): "+data;
                    });
                }
            }
        };
        $scope.counter=0;
        $scope.tick = function() {
            $scope.refetchData();
            $timeout( $scope.tick, 60000);
        }
        var xx = $timeout( $scope.tick, 60000);

        $scope.bunchAction =  function(cmd) {
            var url = $scope.bunchActionPath+"&cmd="+cmd;
            console.log("REQUESTING: "+url);
            $http.get(url).success(function(data) {
                $scope.opResult = "success: "+data;
                $scope.refetchData();
            }).error(function(data){
                $scope.opResult = "error: "+data;
                alert("NF Error: "+JSON.stringify(data,null,2));
            });
        }

    });

    fileApp.filter('encode', function() {
        return window.encodeURIComponent;
    });
    </script>

</head>
<body ng-controller="fileCtrl">
<h3>News Files Listing  <%=queueMsg%></h3>
<p><a href="news.jsp?<%=startPart%>">News</a>
 | <a href="newsDetail2.jsp?d={{digest|encode}}&f={{f|encode}}">Articles</a>
 | <font color="red">Files</font>
 | <a href="newsPatterns.jsp?d={{digest|encode}}&f={{f|encode}}">Patterns</a>
 <span style="background-color: yellow;">{{opResult}}</span></p>

<table><tr><td>Bunch Subject: </td><td bgcolor="{{bunch.color}}"><%
    HTMLWriter.writeHtml(out, bunch.digest);
%></td></tr></table>
<ul>
    <form action="newsDetailAction.jsp?dig=<%= URLEncoder.encode(dig, "UTF-8") %>&f=<%= URLEncoder.encode(f, "UTF-8") %>" name="moveForm" method="post">
    <li>Current: <font color="brown"><%
        HTMLWriter.writeHtml(out, folder);
        HTMLWriter.writeHtml(out, bunch.getTemplate());
    %></font>
    </li>
    <li>
    Folder: <input type="text" name="folder"
            ng-model="folder"
            size="50"
            placeholder="Paths"
            typeahead="path for path in lastPaths | filter:$viewValue | limitTo:8">
        <span ng-click="showFolders=!showFolders">vv</span>
        <input type="submit" name="cmd" value="Set And Move Files">
        <input type="hidden" name="createIt" value="yes">
        <input type="submit" name="cmd" value="Set Without Files">

    </li>
    <li ng-show="showFolders" style="background-color: springgreen; padding: 5;">
    <%
        for (String destVal : destVec) {
    %>
        <input ng-click="folder='<%=destVal%>'"
              type="button" value="<%=destVal%>"/><br/>
    <%
        }
    %>
    </li>
    <li>Template: <input type="text" name="template" value="<%HTMLWriter.writeHtml(out, bunch.getTemplate());%>" size="50">

                <input type="checkbox" name="plusOne" value="true" <% if (bunch.plusOneNumber) {%>checked="checked"<%}%>> Plus One
                <br/>
                <input type="submit" name="cmd" value="SetPattern">
                <input type="submit" name="cmd" value="Cover">
                <input type="submit" name="cmd" value="Flogo">
                <input type="submit" name="cmd" value="Sample">
                <input type="submit" name="cmd" value="SetIndex">
                <input type="submit" name="cmd" value="SetOneIndex">
                AutoPath: <input type="checkbox" name="autopath" value="true" checked="checked">
                Zing: <%HTMLWriter.writeHtml(out, zingpat);%>
                </li>
    <%
        if (bunch.pState==NewsBunch.STATE_ERROR) {
            out.write("<li>Error: <font color=\"deeppink\">"+bunch.failureMessage.toString()+"</font></li>");
        }
    %>
    <input type="hidden" name="go" value="<%=thisPage%>">
    </form>
    <hr/>
        <button ng-click="bunchAction('DeleteAllHide')">Delete All & Hide</button>
        <button ng-click="bunchAction('MarkInterested')">Mark Interested</button>
        <button ng-click="bunchAction('GetABit')">Get A Bit</button>
        <button ng-click="bunchAction('SeekBunch')">Seek Bunch</button>
        <button ng-click="bunchAction('DownloadAll')">Download All</button>
        <button ng-click="bunchAction('MarkComplete')">Mark Complete</button>
        <button ng-click="bunchAction('CancelSeek')">Cancel Seek</button>
        <button ng-click="bunchAction('CancelInterest')">Cancel Interest</button>
        <button ng-click="bunchAction('CancelDownload')">Cancel Download</button>
    <hr/>
        <button ng-click="toggleState('Hide')">Hide: {{qHide}}</button>
        <button ng-click="toggleState('Int')">Interest: {{qInt}}</button>
        <button ng-click="toggleState('Seek')">Seek: {{qSeek}}</button>
        <button ng-click="toggleState('Down')">Download: {{qDown}}</button>
        <button ng-click="toggleState('Comp')">Complete: {{qComp}}</button>
        <input type="checkbox" ng-model="showDownloaded"> Show Down
    <li>
    Pattern:  <%
    Vector<PosPat> bunchPosPats = bunch.getPosPatList();
    PosPat.sortByPattern(bunchPosPats);
    for (PosPat ppp : bunchPosPats) {
        String ppp_patt = ppp.getPattern();
        out.write("<a href=\"pattern2.jsp?g="+URLEncoder.encode(ppp_patt,"UTF-8")+"\">");
        HTMLWriter.writeHtml(out, ppp_patt);
        out.write("</a>");
        PosPat pp = bunch.getPosPat(ppp_patt);
        LocalMapping map = LocalMapping.getMapping(pp);
        boolean jaMap = (map!=null && map.enabled);
        if (jaMap) {
            %><a href="newsFilePatt.jsp?d=<%=UtilityMethods.URLEncode(dig)
            %>&f=<%=URLEncoder.encode(f,"UTF-8")%>&selPatt=<%=UtilityMethods.URLEncode(ppp_patt)
            %>"><img src="fileMapped.png"></a>
        <% } else {
            %><a href="newsFilePatt.jsp?d=<%=UtilityMethods.URLEncode(dig)
            %>&f=<%=URLEncoder.encode(f,"UTF-8")%>&selPatt=<%=UtilityMethods.URLEncode(ppp_patt)
            %>"><img src="fileUnmapped.png"></a>
        <% }
        out.write("</a>, ");
    }
    %>




    <hr/>

    <button ng-click="refetchData()">Refresh</button>
    <button ng-click="bunchAction('GetPatt')">Get Patt</button>
    <button ng-click="bunchAction('DoubleExtent')">Extent: {{bunch.seekExtent}}</button>
    <button ng-click="bunchAction('ToggleShrink')">Shrink: {{bunch.shrinkFiles}}</button>
    <button ng-click="bunchAction('ToggleYEnc')">yEnc: {{bunch.isYEnc}}</button>
    <form action="taglist.jsp" method="get">
    <input type="submit" value="Tags Checked:">
    <%
    boolean needComma = false;
    for (String tagName : tagCache.sortedKeys()) {
        needComma = true;
        %><input type="checkbox" name="tag" checked="checked" value="<%HTMLWriter.writeHtml(out, tagName);%>"><%
        out.write("<a href=\"taglist.jsp?t="+URLEncoder.encode(tagName,"UTF-8")+"\">");
        HTMLWriter.writeHtml(out, tagName);
        out.write("</a>, ");
    }
    %>
    </form>
    </li>
</ul>

<style>
.gapstyle td {
    border-style: solid;
    border-top: thick double #ff8888;
}
</style>

<table>
    <tr ng-repeat="rec in getFiltered()" class="{{rec.gap?'gapstyle':''}}">
    <td><img ng-click="deleteFile(rec.fileName)" src="trash.gif">
    </td>
    <td>{{rec.bestName}}</td>
    <td>
        <img ng-show="rec.needSave && !rec.isDownloading && rec.isComplete"
             ng-click="fetchFile(rec.fileName)" src="downicon.gif">
        <a ng-show="rec.isDownloading" ng-click="refetchData()"><img src="downloading.png"></a>
        <a href="/photo/photo/{{rec.bestPath}}" ng-show="rec.fileExists"
            target="photo"  title="{{rec.bestPath}}"><img src="fileExists.png"></a>
        <span ng-show="!rec.isComplete && rec.needSave">partial</span>
    </td>
    <td>
        <img ng-hide="rec.isMapped" src="fileUnmapped.png">
        <img ng-show="rec.isMapped" src="fileMapped.png">
    </td>
    <td>
        <span ng-hide="rec.needSave">{{rec.fileSize}}</span>
        <span ng-show="rec.needSave">{{rec.partsAvailable}} /{{rec.partsExpected}}</span>
    </td>
    <td> &nbsp; |
    <a href="debugFile.jsp?artno={{rec.sampleArticle}}"><img src="debug-icon.png" title="Debug this file object"></a>
    <a href="newsMatch.jsp?artno={{rec.sampleArticle}}"><img src="search.png"></a>
    </td>
    <td style="color:red;">{{rec.hadError}}</td>
    </tr>

</table>

<hr/>

</body>
</html>

