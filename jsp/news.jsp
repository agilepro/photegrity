<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.Stats"
%><%@page import="bogus.UtilityMethods"
%><%@page import="bogus.APIHandler"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="java.util.Stack"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.streams.JavaScriptWriter"
%><%@page import="org.workcast.json.JSONObject"
%><%@page import="org.workcast.json.JSONArray"
%><%

    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "news.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    boolean groupLoaded = (newsGroup.defaultDiskMgr!=null);

    String dMode = UtilityMethods.defParam(request, "dMode", "norm");
    String thisPage = "news.jsp?dMode="+dMode;

    boolean isHidden = "full".equals(dMode);
    boolean onlyActive = "act".equals(dMode);

    String hidePart = "&dMode="+dMode;
    List<NewsBunch> allPatts;
    if (!isHidden) {
        allPatts = NewsGroup.getUnhiddenBunches();
    }
    else {
        allPatts = NewsGroup.getAllBunches();
    }
    int initialBunches = allPatts.size();

    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    String zingFolder = "";
    if (destVec!=null && destVec.size()>0) {
        zingFolder = destVec.get(0);
    }
    String zingPat = (String) session.getAttribute("zingpat");
    if (zingPat==null) {
        zingPat="";
    }

    String sortPart = "";
    boolean showID = false;
    boolean showTime = false;
    boolean showCount = true;
    boolean showFile = false;
    boolean showPath = false;

    if (!groupLoaded)
    {%>
        <html>
        <body>
        <h3>News Browser <a href="main.jsp"><img src="home.gif" border="0"></a></h3>

        <form action="newsFetch.jsp" method="post">
        <input type="hidden" name="command" value="Load">
        <input type="checkbox" name="connect" value="true" <%if (NewsGroup.connect) {%>checked="checked"<%}%> > Connect <br/>
        <%
            for (File aFile : DiskMgr.getNewsFiles() ) {
                    File parent = aFile.getParentFile();
        %> <input type="submit" name="newsFile" value="<%HTMLWriter.writeHtml(out, parent.toString());%>"> <%
            }
 %>
        </form>
        <p>No articles loaded yet.  (<a href="newsGroupList.jsp">Search groups</a>)</p>
        </body>
        </html>
        <%
            return;
    }

    String groupName = newsGroup.getName();


    if (onlyActive) {
        List<NewsBunch> filteredPatterns = new Vector<NewsBunch>();
        for (NewsBunch tpatt : allPatts) {
            if (tpatt.pState == NewsBunch.STATE_SEEK_DONE  ||
                    tpatt.pState == NewsBunch.STATE_INTEREST) {
                filteredPatterns.add(tpatt);
            }
        }
        if (filteredPatterns.size()>0) {
            allPatts = filteredPatterns;
        }
    }



    int fetchNo = allPatts.size();


    //figure out the starting point
    int start = UtilityMethods.defParamInt(request, "start", 0);
    String search = UtilityMethods.defParam(request, "search", null);
    if (start<=0) {
        if (search!=null) {
            int i=0;
            for (NewsBunch seeker : allPatts) {
                if (search.compareTo(seeker.digest)<=0) {
                    start = i;
                    break;
                }
                i++;
            }
        }
        else {
            search = "";
        }
        if (start>4) {
            //back up four places so it is not right at the top
            start = start - 4;
        }
        else {
            start = 0;
        }
    }
    else {
        NewsBunch top = allPatts.get(start);
        if (top!=null) {
            search = top.digest;
        }
        else {
            search = "";
        }
    }
    int next = start + 15;
    int prev = start - 15;
    if (prev<0) {
        prev = 0;
    }

    String queueMsg = "("+NewsAction.getActionCount()+" <a href=\"tasks.jsp\" target=\"_blank\">tasks</a>)";

    long duration = Stats.getTotalDuration()/1000;
    if (duration<=0) {
        //avoid divide by sero problem
        duration = 1;
    }
    long downloadRate = Stats.getTotalFinishedBytes()/duration;
    String go="news.jsp?search="+URLEncoder.encode(search,"UTF-8");

    JSONObject newsInfo = new JSONObject();
    newsInfo.put("groupName", newsGroup.groupName);
    newsInfo.put("diskName", newsGroup.defaultDiskMgr.diskName);
    newsInfo.put("windowSize", newsGroup.displayWindow);
    newsInfo.put("firstArticle", newsGroup.firstArticle);
    newsInfo.put("lastArticle", newsGroup.lastArticle);
    newsInfo.put("articleCount", newsGroup.articleCount);
    newsInfo.put("fetched", newsGroup.getIndexSize());
    newsInfo.put("lowestFetched", newsGroup.lowestFetched);
    newsInfo.put("highestToDisplay", newsGroup.lowestFetched+newsGroup.displayWindow);
    newsInfo.put("highestFetched", newsGroup.highestFetched);
    newsInfo.put("totalRawBytes", Stats.getTotalRawBytes());
    newsInfo.put("totalRawBytes", Stats.getTotalRawBytes());
    newsInfo.put("totalFinishedBytes", Stats.getTotalFinishedBytes());
    newsInfo.put("totalFiles", Stats.getTotalFiles());
    newsInfo.put("downloadRate", downloadRate);
    newsInfo.put("actionCount", NewsAction.getActionCount());

%>
<html ng-app="bunchApp">
<head>

    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <link href="photoStyle.css" rel="stylesheet">
    <script type="text/javascript" src="lib/angular.js"></script>
    <script type="text/javascript" src="lib/ui-bootstrap-tpls.min.js"></script>
    <script type="text/javascript" src="lib/jquery.min.js"></script>
    <script type="text/javascript" src="lib/bootstrap.min.js"></script>

    <script>

    function stupidEncode(str) {
        var last = str.length;
        var out = "";
        for (var i=0; i<last; i++) {
            ch = str.charCodeAt(i);
            out = out + String.fromCharCode( (ch/16)%16 + 65, ch%16 + 65 );
        }
        return out;
    }


    var bunchApp = angular.module('bunchApp', ['ui.bootstrap']);
    bunchApp.factory('bunchFactory', function($http) {
        return {
            listBunch: function(filter, window) {
                var url = 'listBunches.jsp?filter='+encodeURIComponent(filter)+'&window='+window;
                console.log("FETCHING: "+url);
                var promise = $http.get(url);
                promise.error(function(msg){
                    alert("error: "+JSON.stringify(msg,null,2));
                });
                return promise;
            },
            listBunches: function(filter, window, callback) {
                var promise = this.listBunch(filter, window);
                promise.success(callback);
                return promise;
            },
            updateSession: function(sessionRec, callback) {
                var promise = $http.post("api/session/foo/boo", sessionRec);
                promise.success( callback );
                promise.error( function(data, status, headers, config) {
                    console.log("the POST failed: "+JSON.stringify(data,null,2));
                    alert("session update failed: "+JSON.stringify(data,null,2));
                });
                return promise;
            },
            batchOperation: function(command, filter, filePath) {
                var url = 'newsBatch.jsp?filter='+encodeURIComponent(filter)
                                       +'&filePath='+encodeURIComponent(filePath)
                                       +'&batchop='+command;
                console.log("BATCH: "+url);
                var promise = $http.get(url);
                promise.error(function(msg){
                    alert("error: "+JSON.stringify(msg,null,2));
                });
                return promise;
            }
        }
    });
    bunchApp.controller('bunchCtrl', function ($scope, $http, bunchFactory, $timeout) {
        $scope.showTop = false;
        $scope.session = <% APIHandler.getSessionJSON(request).write(out,2,0); %>;
        if(typeof(Storage) == "undefined") {
            alert("Sorry, your browser does not support web storage...");
        }
        $scope.storeSessionInfo = function() {
            sessionStorage.photoSettings = JSON.stringify($scope.photoSettings);
        };
        $scope.readSessionInfo = function() {
            if (sessionStorage.photoSettings) {
                $scope.photoSettings = JSON.parse(sessionStorage.photoSettings);
                $scope.photoSettings.loadCount++;
                $scope.storeSessionInfo();
            }
            else {
                $scope.photoSettings = {loadCount: 1, window: 50000, sort: "ID"};
                $scope.storeSessionInfo();
            }
        };
        $scope.readSessionInfo();


        $scope.pageSize = 20;
        $scope.zingFolder = "<%JavaScriptWriter.encode(out,zingFolder);%>";
        $scope.zingPat = "<%JavaScriptWriter.encode(out,zingPat);%>";
        $scope.recs = new Array();
        $scope.filteredRecs = new Array();
        $scope.offset = <%=start%>;
        $scope.thisPath = "<%JavaScriptWriter.encode(out, go);%>&start=<%=start%>";
        $scope.search = "<% JavaScriptWriter.encode(out, search); %>";
        $scope.showId = false;
        if (!$scope.photoSettings.showState) {
            $scope.photoSettings.showState = {};
            $scope.photoSettings.showState[0] = true;
            $scope.photoSettings.showState[1] = true;
            $scope.photoSettings.showState[2] = true;
            $scope.photoSettings.showState[3] = true;
            $scope.photoSettings.showState[4] = true;
            $scope.photoSettings.showState[5] = true;
            $scope.photoSettings.showState[6] = true;
            $scope.photoSettings.showState[7] = false;
            $scope.photoSettings.showState[8] = true;
            $scope.photoSettings.showState[9] = true;
            $scope.photoSettings.colTrim = 40;
            $scope.photoSettings.filter = "";
            $scope.photoSettings.sort = "ID";
            $scope.photoSettings.window = 100000;
            $scope.storeSessionInfo();
        }
        $scope.newsInfo = <% newsInfo.write(out,2,0); %>;
        $scope.discardBefore = $scope.newsInfo.lowestFetched + 10000;




        $scope.nextPage = function() {
            if ($scope.offset < $scope.recs.length-$scope.pageSize) {
                $scope.offset+=$scope.pageSize;
            }
            else {
                $scope.offset=$scope.recs.length-$scope.pageSize;
            }
            $scope.pickNewSearchValue();
        };
        $scope.prevPage = function() {
            if ($scope.offset > $scope.pageSize) {
                $scope.offset-=$scope.pageSize;
            }
            else {
                $scope.offset=0;
            }
            $scope.pickNewSearchValue();
        };
        $scope.$watch('photoSettings.filter', function(newVal, oldVal) {
            if (newVal || oldVal) {
                $scope.storeSessionInfo();
                $scope.rereadData();
            }
        });
        $scope.setWindow = function(newWindow) {
            $scope.photoSettings.window = newWindow;
            $scope.storeSessionInfo();
            $scope.rereadData();
        }
        $scope.toggleShow = function (opt) {
            $scope.photoSettings.showState[opt] = !$scope.photoSettings.showState[opt];
            $scope.storeSessionInfo();
            $scope.findSearchValueOffset();
        }
        $scope.toggleTrim = function () {
            if ($scope.photoSettings.colTrim == 40) {
                $scope.photoSettings.colTrim = 120;
            }
            else {
                $scope.photoSettings.colTrim = 40;
            }
            $scope.storeSessionInfo();
        }
        $scope.toggleId = function () {
            $scope.photoSettings.showId = !$scope.photoSettings.showId;
            $scope.storeSessionInfo();
        }
        $scope.toggleSender = function () {
            $scope.photoSettings.showSender = !$scope.photoSettings.showSender;
            $scope.storeSessionInfo();
        }
        $scope.pickNewSearchValue = function() {
            console.log("pickNewSearchValue");
            if ($scope.filteredRecs.length<$scope.filteredRecs.length) {
                $scope.offset = 0;
            }
            if ($scope.offset > $scope.filteredRecs.length) {
                $scope.offset = $scope.filteredRecs.length - $scope.pageSize;
            }
            if ($scope.offset < 0) {
                $scope.offset = 0;
            }
            if ($scope.offset > $scope.filteredRecs.length-4) {
                $scope.search = $scope.filteredRecs[$scope.filteredRecs.length-1].digest;
            }
            else {
                $scope.search = $scope.filteredRecs[$scope.offset+4].digest;
            }
            $scope.thisPath = "<%JavaScriptWriter.encode(out, go);%>&start="+ $scope.offset;
        }
        $scope.firstPage = function() {
            $scope.offset=0;
            $scope.pickNewSearchValue();
        };
        $scope.lastPage = function() {
            $scope.offset= $scope.filteredRecs.length - $scope.pageSize;
            if ($scope.offset<0) {
                $scope.offset = 0;
            }
            $scope.pickNewSearchValue();
        };
        $scope.sortDigest = function() {
            $scope.photoSettings.sort = "digest";
            $scope.storeSessionInfo();
            $scope.findSearchValueOffset();
        }
        $scope.sortSize = function() {
            $scope.photoSettings.sort = "size";
            $scope.storeSessionInfo();
            $scope.findSearchValueOffset();
        }
        $scope.sortRecent = function() {
            $scope.photoSettings.sort = "recent";
            $scope.storeSessionInfo();
            $scope.findSearchValueOffset();
        }
        $scope.sortID = function() {
            $scope.photoSettings.sort = "ID";
            $scope.storeSessionInfo();
            $scope.findSearchValueOffset();
        }
        $scope.findSearchValueOffset = function() {
            $scope.calcFiltered();
            var dispArray = $scope.filteredRecs;
            var length = dispArray.length;
            var best = "";
            var newOffset = -1;
            var altOffset = -1;
            for(var j = 0; j < length; j++) {
                var rec = dispArray[j];
                var dig = rec.digest;
                if (dig == $scope.search) {
                    newOffset = j;
                }
                else if (dig < $scope.search) {
                    if (dig > best) {
                        best = dig;
                        altOffset = j;
                    }
                }
            }
            if (newOffset < 0) {
                newOffset = altOffset;
                $scope.search = best;
            }
            if (newOffset<4) {
                $scope.offset = 0;
            }
            else {
                $scope.offset = newOffset - 4;
            }
        }
        $scope.calcFiltered = function() {
            console.log("calcFiltered "+$scope.photoSettings.sort);
            if ($scope.photoSettings.sort == "digest") {
                $scope.recs.sort( function(a, b){
                    return ( a.digest > b.digest )? 1 : -1;
                });
            }
            else if ($scope.photoSettings.sort == "size") {
                $scope.recs.sort( function(a, b){
                    return ( b.count - a.count );
                });
            }
            else if ($scope.photoSettings.sort == "recent") {
                $scope.recs.sort( function(a, b){
                    return ( b.lastTouch - a.lastTouch );
                });
            }
            else if ($scope.photoSettings.sort == "ID") {
                $scope.recs.sort( function(a, b){
                    return (a.minId > b.minId)? 1 : -1;
                });
            }
            else {
                console.log("DONT recognize sort: ", $scope.recs.sort)
            }
            var dispArray = new Array();
            var length = $scope.recs.length;
            for(var j = 0; j < length; j++) {
                var rec = $scope.recs[j];
                if (!$scope.photoSettings.showState[rec.state]) {
                    continue;
                }
                if (rec.digest.indexOf($scope.photoSettings.filter) > -1) {
                    dispArray.push(rec);
                }
                else if (rec.template.indexOf($scope.photoSettings.filter) > -1) {
                    dispArray.push(rec);
                }
                else if (rec.sender.indexOf($scope.photoSettings.filter) > -1) {
                    dispArray.push(rec);
                }
            }
            $scope.filteredRecs = dispArray;
        }

        $scope.getFiltered = function() {
            if ($scope.recs.length==0) {
                return [];
            }
            var dispArray = $scope.filteredRecs;
            length = dispArray.length;
            for(var j = 0; j < length; j++) {
                var rec = dispArray[j];
                $scope.annotateSpecial(rec);
            }
            dispArray = dispArray.slice($scope.offset);
            return dispArray;
        }
        $scope.isMarked = function(rec) {
            if ($scope.session.zingFolder != rec.folderLoc) {
                return false;
            }
            for (var idx=0; idx<rec.patts.length; idx++) {
                if (rec.patts[idx] == $scope.session.zingPat) {
                    return true;
                }
            }
            return false;
        }
        $scope.isMarkFolder = function(rec) {
            return ($scope.session.zingFolder == rec.folderLoc);
        }
        $scope.markThis = function(rec) {
            var postData = {zingFolder: rec.folderLoc, zingPat: rec.patts[0]};
            bunchFactory.updateSession(postData, function(data) {
                $scope.session = data;
            });
        }
        $scope.markFolder = function(rec) {
            var postData = {zingFolder: rec.folderLoc};
            bunchFactory.updateSession(postData, function(data) {
                $scope.session = data;
            });
        }
        $scope.stripChars = function(strval) {
            var resVal = "";
            var needsDot = false;
            for (var i=0; i<strval.length; i++) {
                var ch = strval.charAt(i);
                if ( (ch>='a' && ch<='z') || (ch>='A' && ch<='Z') 
                    || (ch>='0' && ch<='9') || ch=='_' || ch=='$') {
                        if (needsDot) {
                            resVal = resVal + '.';
                            needsDot = false;
                        }
                        resVal = resVal + ch;
                    }
                else if (ch!=' ') {
                    needsDot = true;
                }
            }
            return resVal;
        }
        $scope.setPath = function(bunch) {
            var newBunch = {};
            newBunch.key = bunch.key;
            newBunch.template = bunch.template;
            
            newBunch.folderLoc = $scope.session.destVec[0];
            console.log("Before fix: ", newBunch.template)
            $scope.fixTemplateWithoutSave(newBunch);
            console.log("After fix: ", newBunch.template)
            $scope.saveBunch(newBunch);
        }
        $scope.defaultPath = function(bunch) {
            var newBunch = {};
            newBunch.key = bunch.key;
            newBunch.template = bunch.template;
            
            newBunch.folderLoc = bunch.folderLoc;
            console.log("Before fix: ", bunch.folderLoc)
            $scope.fixTemplateWithoutSave(newBunch);
            console.log("Before fix: ", bunch.folderLoc)
            $scope.saveBunch(newBunch);
        }
        $scope.fixTemplateWithoutSave = function(newBunch) {
            var template = $scope.stripChars(newBunch.template);
            console.log("Working On XXX: ", template);
            var pos = template.indexOf(".jpg");
            //if (pos<=0) {
            //    pos = template.indexOf(".rar");
            //    if (pos<=0) {
            //        return;
            //    }
            //}
            var tail = template.substring(pos+4);
            if (tail.length==4 && tail[0]==='$' && tail[2]==='$') {
                //this is the $3$4 case
                template = template.substring(0,pos+4);
            }
            else if (tail.length==6 && tail[0]==='.' && tail[1]==='$' 
                     && tail[3]==='.' && tail[4]==='$') {
                //this is the .$3.$4 case
                template = template.substring(0,pos+4);
            }
            else if (tail.length==6  && tail[1]==='$' && tail[4]==='$' ) {
                //this is the 1$31$4 case
                template = template.substring(0,pos+4) + "." + tail.substring(0,3);
            }
            else if (tail.length==8  && tail[2]==='$' && tail[6]==='$' ) {
                //this is the .1$3.1$4 case
                template = template.substring(0,pos+4) + "." + tail.substring(1,4);
            }
            console.log("POLISHED: "+template);
            if (template=="$0.jpg" || template=="$1.jpg" || template=="$2.jpg") {
                
                var timestamp = new Date().getTime();
                var ch1 = String.fromCharCode(97 + (timestamp%26));
                var ch2 = String.fromCharCode(97 + ((timestamp/26)%26));
                template = "$d" + ch1 + ch2 + "-" + template;
                console.log("CONVERTED: "+ template);
            }
            var pos = template.indexOf(".of.$");
            if (pos>0) {
                template = template.substring(0,pos)+".jpg";
            }
            newBunch.template = template;
        }
        $scope.fixTemplate = function(bunch) {
            var newBunch = {};
            newBunch.key = bunch.key;
            newBunch.template = bunch.template;
            $scope.fixTemplateWithoutSave(newBunch);
            $scope.saveBunch(newBunch);
        }
        $scope.annotateSpecial = function(bunch) {
            if ($scope.showKiller(bunch)) {
                bunch.special = "HIDE";
                bunch.specialOp = 7;
            }
            else if (!bunch.hasTemplate) {
                bunch.special = "BIT";
                bunch.specialOp = 9;
            }
            else if (bunch.state<=1) {
                bunch.special = "Seek";
                bunch.specialOp = 2;
            }
            else if (bunch.state==3) {
                bunch.special = "Down";
                bunch.specialOp = 4;
            }
            else if (bunch.state==5) {
                bunch.special = "Complete";
                bunch.specialOp = 6;
            }
            return [];
        }

        $scope.showKiller = function(bunch) {
            var template = bunch.template;
            if (bunch.digest.startsWith("Re: ")) {
                return true;
            }
			if (bunch.state<3) {
				return false;
			}
            if (bunch.template.indexOf(".par")>0) {
                return true;
            }
            if (bunch.template.indexOf(".PAR")>0) {
                return true;
            }
            if (bunch.template.indexOf(".nzb")>0) {
                return true;
            }
            if (bunch.template.indexOf(".sfv")>0) {
                return true;
            }
            return false;
        }
        $scope.changeState = function(bunch, newState) {
            var newBunch = {};
			if (newState==9 && !bunch.hasTemplate) {
				$scope.fixTemplate(bunch);
				$scope.defaultPath(bunch);
			}
            newBunch.key = bunch.key;
            newBunch.state = newState;
            $scope.saveBunch(newBunch);
        }
		$scope.changeSpecial = function(bunch) {
			if (bunch.specialOp<100) {
				$scope.changeState(bunch, bunch.specialOp);
			}
			else if (bunch.specialOp==100) {
				$scope.setPath(bunch);
			}
			else if (bunch.specialOp==200) {
				$scope.fixTemplate(bunch);
			}
		}
        $scope.saveBunch = function(bunch) {
            postURL = "api/b="+bunch.key;
            postdata = JSON.stringify(bunch);
            console.log("ASKING: "+postdata);
            $http.post(postURL ,postdata)
            .success( function(data) {
                console.log("GOT BACK: "+JSON.stringify(data));
                var swap = [];
                $scope.filteredRecs.map( function(item) {
                    if (item.key != bunch.key) {
                        swap.push(item);
                    }
                    else {
                        swap.push(data);
                    }
                });
                $scope.filteredRecs = swap;
            })
            .error( function(data, status, headers, config) {
                console.log("saveBunch ERROR", data);
                alert("ERROR: "+JSON.stringify(data));
            });
        }
        $scope.rereadData = function() {
            bunchFactory.listBunches($scope.photoSettings.filter, $scope.photoSettings.window, function(data) {
                $scope.recs = data;
                $scope.calcFiltered();
                $scope.findSearchValueOffset();
            });
            $timeout( $scope.rereadData, 60000 );
        }

        //now actually get the data
        $scope.rereadData();

        $scope.updateMsg = "";
        $scope.fetch =  {
            start: <%=newsGroup.lowestToDisplay%>,
            end: <%= newsGroup.lowestToDisplay+newsGroup.displayWindow %>,
            step:31 }
        $scope.fetchMoreNews = function() {
            var count = Math.trunc(($scope.fetch.end - $scope.fetch.start)/$scope.fetch.step);
            var url = "newsFetch.jsp?command=Refetch&start="+$scope.fetch.start
                +"&count="+count+"&step="+$scope.fetch.step;
            $scope.opCommand(url);
        }
        $scope.fillGaps = function() {
            var url = "newsFetch.jsp?command=FillGaps&start="+$scope.fetch.start
                +"&end="+$scope.fetch.end+"&gap="+$scope.fetch.step;
            $scope.opCommand(url);
        }
        
        $scope.opCommand =  function(url) {
            console.log("REQUESTING: "+url);
            $http.get(url).success(function(data) {
                $scope.updateMsg = "success: "+data;
            }).error(function(data){
                $scope.updateMsg = "error: "+data;
                alert("error: "+data);
            });
        }
        $scope.recalcStats = function() {
            var url = "newsFetch.jsp?command=Recalc%20Stats";
            $scope.opCommand(url);
        }
        $scope.scheduledSave = function() {
            var url = "newsFetch.jsp?command=Scheduled%20Save";
            $scope.opCommand(url);
        }
        $scope.foo = function(data) {
            return stupidEncode(data);
        }


      $scope.toggled = function(open) {
        $log.log('Dropdown is now: ', open);
      };

      $scope.toggleDropdown = function($event) {
        $event.preventDefault();
        $event.stopPropagation();
        $scope.status.isopen = !$scope.status.isopen;
      };
      
      $scope.batchOpList = [
          {val:"nothing",disp:"Do Nothing"},
          {val:"bit",disp:"Download a few of the files"},
          {val:"seek",disp:"Seek those that need it."},
          {val:"default",disp:"Set path for those that do not have path"},
          {val:"store",disp:"Set path for all in Selection"},
          {val:"download",disp:"Download those that need it."},
          {val:"complete",disp:"Mark All Completed"},
          {val:"hide",disp:"Hide All in Selection"},
          {val:"clear",disp:"Reset All to initial state"}
          ];
      $scope.batchOp = "nothing";
      $scope.batchPath = "";
      $scope.doBatch = function() {
          bunchFactory.batchOperation($scope.batchOp, $scope.photoSettings.filter, $scope.session.zingFolder)
          .success( function(data) {
              alert("batch operation successful "+JSON.stringify(data,null,2));
              $scope.rereadData();
          });
      }
      
    });

    bunchApp.filter('encode', function() {
        return window.encodeURIComponent;
    });

    bunchApp.filter('stupid', function() {
        return stupidEncode;
    });


    bunchApp.filter('btoa', function() {
        return function (str) {
            return window.btoa(encodeURIComponent(escape(str)));
        }
    });

    bunchApp.filter('atob', function() {
        return function(str) {
            return unescape(decodeURIComponent(window.atob(str)));
        }
    });


    </script>
</head>
<body ng-controller="bunchCtrl">
<h3>News Browser <a href="main.jsp">
    <img src="home.gif" border="0"></a> ({{newsInfo.actionCount}} <a href="tasks.jsp" target="_blank">tasks</a> {{session.actionCount}}) -
    {{newsInfo.diskName}}
    <% if (!NewsGroup.connect) {%>
       (-- NOT CONNECTED --)
    <% } %> </h3>

<div ng-show="!showTop">
<button ng-click="showTop=true">Show</button>   Search:  {{search}}
</div>
<div ng-show="showTop" class="menuBox">
<button ng-click="showTop=false">Hide</button> <span style="color:red;">{{updateMsg}}</span>
<div>
    Window Size: {{photoSettings.window}}
    <button ng-click="setWindow(10000);showTop=false">10</button>
    <button ng-click="setWindow(25000);showTop=false">25</button>
    <button ng-click="setWindow(50000);showTop=false">50</button>
    <button ng-click="setWindow(100000);showTop=false">100</button>
    <button ng-click="setWindow(200000);showTop=false">200</button>
    <button ng-click="setWindow(500000);showTop=false">500</button>
(<%=allPatts.size()%> of <%=initialBunches%>)
<a href="listBunches.jsp?filter={{photoSettings.filter | encode}}&window={{photoSettings.window}}">test fetch</a>
</div>

Start: <input name="start" type="text" value="<%=newsGroup.lowestToDisplay%>" size="10" ng-model="fetch.start"/>
End: <input name="count" type="text" size="10" ng-model="fetch.end">
Step: <input name="step" type="text" size="5"  ng-model="fetch.step">
<button ng-click="fetchMoreNews()">Fetch More News</button> &nbsp;
<button ng-click="recalcStats()">Recalc Stats</button> {{(fetch.end-fetch.start)/fetch.step}}
<ul>
  <li>News Group: <b>{{newsInfo.groupName}}</b></li>
  <li>Disk Name:  {{newsInfo.diskName}} </li>
  <li>Zing:  {{session.zingFolder}}/{{session.zingPat}}</li>
  <li>Server Range: {{newsInfo.firstArticle|number}} - {{newsInfo.lastArticle|number}}</li>
  <li>Server Count: {{newsInfo.articleCount|number}}</li>
  <li>Fetched Range: {{newsInfo.lowestFetched|number}} - {{newsInfo.highestFetched|number}}</li>
  <li>Fetch Count: {{newsInfo.fetched|number}}</li>
  <li>Display Range: {{newsInfo.lowestFetched|number}} - {{newsInfo.highestToDisplay|number}}</li>
  <li>Display Window: {{newsInfo.windowSize|number}} is {{photoSettings.window|number}} </li>
  <li>Total Raw Bytes: {{newsInfo.totalRawBytes|number}}</li>
  <li>Total Finished Bytes:{{newsInfo.totalFinishedBytes|number}}</li>
  <li>Total Files: {{newsInfo.totalFiles|number}}</li>
  <li>Download Rate: {{newsInfo.downloadRate|number}} bytes/second</li>

</ul>
<button ng-click="scheduledSave()">Scheduled Save</button>
    <a href="newsGaps.jsp?limit=100&step=23&thresh={{fetch.step}}&begin={{newsInfo.lowestFetched}}&highest={{newsInfo.lowestFetched+photoSettings.window}}">
    <button>Find-Gaps in {{photoSettings.window}}</button></a> 
    <input name="step" type="text" size="5"  ng-model="fetch.step">
    <button ng-click="fillGaps()">Fill-Gaps</button>

<form action="newsFetch.jsp">
<input type="hidden" name="go" value="news.jsp?start=<%=start%>">
<input type="submit" name="command" value="Save">
<input type="submit" name="command" value="Close">
<br/>
<br/>
<input type="submit" name="command" value="Discard Articles"> Older Than:
<input type="text" name="earlyLimit" ng-model="discardBefore"> 
    about {{discardBefore-newsInfo.lowestFetched | number}} records
</form>

<input type="text" name="filter" ng-model="photoSettings.filter">
<input type="text" name="checkSize" ng-model="filteredRecs.length"><br/>
<button ng-click="doBatch()">Batch Op {{filteredRecs.length}}</button>
<select ng-model="batchOp" ng-options="op.val as op.disp for op in batchOpList"></select>
{{session.zingFolder}}



</div>

<button ng-click="toggleShow(0)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[0]"> New </button>
<button ng-click="toggleShow(1)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[1]"> Interested </button>
<button ng-click="toggleShow(2)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[2]"> Active-Seek </button>
<button ng-click="toggleShow(3)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[3]"> Seeked </button>
<button ng-click="toggleShow(4)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[4]"> Active-Down </button>
<button ng-click="toggleShow(5)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[5]"> Down </button>
<button ng-click="toggleShow(6)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[6]"> Completed </button>
<button ng-click="toggleShow(7)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[7]"> Hidden </button>
<button ng-click="toggleShow(8)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[8]"> ??? </button>
<button ng-click="toggleShow(9)" class="btn btn-sm">
    <input type="checkbox" ng-model="photoSettings.showState[9]"> Bit </button>
    
    
<br/>

<br/>
Filter: <input ng-model="photoSettings.filter">
     <img ng-click="firstPage()" src="ArrowFRev.gif"/>
     <img ng-click="prevPage()" src="ArrowBack.gif"/>{{offset}}/{{filteredRecs.length}}
     <img ng-click="nextPage()" src="ArrowFwd.gif"/>
     <img ng-click="lastPage()" src="ArrowFFwd.gif"/>
     <button ng-click="rereadData()">Refresh</button>

<hr/>
<table>
  <tr>
     <td></td>
     <td></td>
     <td><img ng-click="toggleTrim()" ng-show="photoSettings.colTrim!=40" src="removeicon.gif" width="12">
         <img ng-click="toggleTrim()" ng-show="photoSettings.colTrim!=120" src="addicon.gif" width="12">
         <img ng-hide="photoSettings.sort=='digest'" ng-click="sortDigest()" src="glyphicons-407-sort-by-order.png" width="12">
         <img ng-show="photoSettings.sort=='digest'" ng-click="sortDigest()" src="glyphicons-407-sort-active.png" width="12"></td>
     <td></td>
     <td><img ng-hide="photoSettings.sort=='size'" ng-click="sortSize()" src="glyphicons-407-sort-by-order.png"
         width="12"><img ng-show="photoSettings.sort=='size'" ng-click="sortSize()" src="glyphicons-407-sort-active.png"
         width="12"></td>
     <td><img ng-hide="photoSettings.sort=='recent'" ng-click="sortRecent()" src="glyphicons-407-sort-by-order.png"
         width="12"><img ng-show="photoSettings.sort=='recent'" ng-click="sortRecent()" src="glyphicons-407-sort-active.png"
         width="12"></td>
     <td></td>
     <td ng-show="photoSettings.showId"><img src="removeicon.gif" ng-click="toggleId()" width="12"> ID
         <img ng-hide="photoSettings.sort=='ID'" ng-click="sortID()" src="glyphicons-407-sort-by-order.png" width="12">
         <img ng-show="photoSettings.sort=='ID'" ng-click="sortID()" src="glyphicons-407-sort-active.png" width="12">
     </td>
     <td ng-hide="photoSettings.showId"><img src="addicon.gif" ng-click="toggleId()" width="12"></td>
     <td ng-show="photoSettings.showSender"><img src="removeicon.gif" ng-click="toggleSender()" width="12"> Sender</td>
     <td ng-hide="photoSettings.showSender"><img src="addicon.gif" ng-click="toggleSender()" width="12"></td>
  </tr>

  <tr ng-repeat="rec in getFiltered() | limitTo: pageSize"
      class="{{rec.digest==search ? 'trSelected':''}}">
            <td class="{{isMarked(rec) ? 'cellPicked' :  ''}}">
              <div class="dropdown">
                <button class="btn btn-default dropdown-toggle" type="button" id="menu1" data-toggle="dropdown">
                    <span class="caret"></span></button>
                <ul class="dropdown-menu" role="menu" aria-labelledby="menu1">
                  <li role="presentation"><a role="menuitem" ng-click="markThis(rec)">Mark Row</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="setPath(rec)">Set PATH</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="fixTemplate(rec)">Fix ZIP Template</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="changeState(rec,9)">Get A Bit</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="changeState(rec,2)">Seek All</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="changeState(rec,4)">Download All</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="changeState(rec,6)">Mark Complete</a></li>
                  <li role="presentation"><a role="menuitem" ng-click="changeState(rec,7)">Hide</a></li>
                </ul>
              </div>
            </td>
     <td class="{{isMarked(rec) ? 'cellPicked' :  ''}}">
         <a href="" ng-click="markThis(rec)">
             <img ng-show="{{rec.hasTemplate}}" src="pattSelect.gif">
         </a>
     </td>
     <td style="{{'background-color: '+ (rec.color ? rec.color : 'white')}};">
         <div>
             <a href="newsDetail2.jsp?start={{offset}}&d={{rec.digest|encode}}&f={{rec.sender|encode}}">
                {{rec.digest|limitTo:photoSettings.colTrim}}
             </a></td>
         </div>
     <td>
         <button ng-click="changeSpecial(rec)">{{rec.special}}</button>
     </td>
     <td style="text-align: right;">{{rec.count}}</td>
     <td class="{{isMarkFolder(rec) ? 'cellPicked' :  ''}}">
         <img ng-src="{{rec.folderStyle}}" title="{{rec.folderLoc}}" ng-click="markFolder(rec)">
     </td>
     <td style="{{rec.cTotal>0 && rec.cTotal-rec.cDown==0 ? 'text-align: right;background-color: lightgreen;' : 'text-align: right;'}}">
     {{rec.cDown}}+{{rec.cComplete-rec.cDown}}+{{rec.cTotal-rec.cComplete}} </td>
     <td ng-show="photoSettings.showId">{{rec.minId|number}} - {{rec.maxId|number}}</td>
     <td ng-hide="photoSettings.showId"></td>
     <td ng-show="photoSettings.showSender" style="background-color:gray;color:white"> {{rec.sender}} </td>
     <td ng-hide="photoSettings.showSender" style="border:solid 2px lightgray;"><a href="newsPatterns.jsp?d={{rec.digest|encode}}">P</a>
         <a href="api/b={{rec.key}}">X</a></td>
     <td ng-show="rec.hasTemplate">
         <a href="newsFiles.jsp?start={{offset}}&d={{rec.digest|encode}}&f={{rec.sender|encode}}">
            {{rec.template}}
         </a>
     </td>
  </tr>
</table>

<hr/>

<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>
<br/>


</body>
</html>


