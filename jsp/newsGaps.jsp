<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.GapRecord"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    int limit = UtilityMethods.defParamInt(request, "limit", 500);
    int thresh = UtilityMethods.defParamInt(request, "thresh", 2000);
    int step = UtilityMethods.defParamInt(request, "step", 100);
    long begin = UtilityMethods.defParamInt(request, "begin", 0);
    long highest = UtilityMethods.defParamInt(request, "highest", (int) newsGroup.lastArticle);
    long pos = (long) UtilityMethods.defParamInt(request, "pos", (int) newsGroup.firstArticle);

    long entireRange = (highest-begin) / step;

    List<GapRecord> gapList = newsGroup.getGaps(begin, highest);
    GapRecord.sortBySize(gapList);
    

%>
<html ng-app="bunchApp">
<head>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls.min.js"></script>
    <link href="photoStyle.css" rel="stylesheet">
    
<script>
var bunchApp = angular.module('bunchApp', ['ui.bootstrap']);
bunchApp.controller('bunchCtrl', function ($scope, $http, $timeout) {
    $scope.begin = <%=begin%>;
    $scope.highest = <%=highest%>;
    $scope.thresh = <%=thresh%>;
    
    $scope.fillGaps = function() {
        var url = "newsFetch.jsp?command=FillGaps&start="+$scope.begin
            +"&end="+$scope.highest+"&gap="+$scope.thresh;
        $scope.opCommand(url);
    }
    $scope.opCommand =  function(url) {
        console.log("REQUESTING: "+url);
        $http.get(url).success(function(data) {
            console.log("SUCCESS", data);
            $scope.updateMsg = "success: "+data;
        }).error(function(data){
            console.log("FAIL", data);
            $scope.updateMsg = "error: "+data;
            alert("error: "+data);
        });
    }
    
});

</script>
</head>
<body ng-controller="bunchCtrl">
<h3><a href="news.jsp">News</a> Gaps <a href="main.jsp"><img src="home.gif" border="0"></a></h3>

<div style="color:red;">{{updateMsg}}</div>

<table><tr>
<td>begin: <input type="text" name="begin" ng-model="begin"></td>
<td>highest: <input type="text" name="highest" ng-model="highest"></td>
<td>{{highest-begin|number}}</td>
</tr><tr>
<td>thresh: <input type="text" name="thresh" value="<%=thresh%>"></td>
<td><input type="submit" value="Search"></td>
<td><button ng-click="fillGaps()">Fill gaps</button></td>
</tr></table>

<ul>
<%
    for (GapRecord gr : gapList) {
        
        %><li>Gap of <%=gr.sizeOfGap%> occurred <%=gr.countOfGaps%> times</li><%
    }
    if (pos<begin) {
        pos = begin;
    }
    %>
</ul>
<hr/>


</body>
</html>


