<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsSession"
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
%><%@page import="org.workcast.streams.HTMLWriter"
%><%@page import="org.workcast.json.JSONObject"
%><%@page import="org.workcast.json.JSONArray"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";
    String groupName = "alt.binaries.pictures.erotica.latina";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    groupName = newsGroup.getName();


    String dig = UtilityMethods.reqParam(request, "News Details Page", "d");
    String sort= UtilityMethods.defParam(request, "sort", "dig");
    String start= UtilityMethods.defParam(request, "start", "0");
    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    String thisPage = "newsDetail2.jsp?"+startPart+"&d="+URLEncoder.encode(dig,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig);
    List<NewsArticle> articles = bunch.getArticles();

    if (articles.size() == 0) {
        throw new Exception("Unable to get any articles for ("+dig+")");
    }

    if ("dig".equals(sort)) {
        NewsArticle.sortByDigest(articles);
    }
    else {
        NewsArticle.sortByNumber(articles);
    }

    String template = bunch.getTemplate();
    if (template==null || template.length()==0) {
        template = tokenFill(bunch.digest);
    }
    String folder = bunch.getFolderLoc();
    boolean folderExists = bunch.hasFolder();

    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector<String>();
        session.setAttribute("destVec", destVec);
    }
    while (destVec.size()>8) {
        destVec.remove(8);
    }

    //set up the location that files automatically go to for Cover, Flogo, etc.
    String prefFolder = "";
    if (destVec.size()>0) {
        prefFolder = destVec.get(0);
    }

    String zingpat = (String) session.getAttribute("zingpat");

    String queueMsg = "("+NewsAction.getActionCount()+" tasks)";

    //need a sample article to deal with
    NewsArticle firstArticle = articles.get(0);
    String fromUser = firstArticle.optionValue[1];

    JSONArray allArts = new JSONArray();
    for (NewsArticle art : articles) {
        JSONObject jobj = new JSONObject();
        jobj.put("num", art.articleNo);
        jobj.put("from", art.getHeaderFrom());
        jobj.put("subject", art.getHeaderSubject());
        jobj.put("dig", art.getHeaderSubject());
        jobj.put("fileName", art.getFileName());
        jobj.put("viz", art.isOnDisk());
        String localPath = "";
        File filePathX = art.getFilePath();
        if (filePathX!=null) {
            DiskMgr dm = DiskMgr.findDiskMgrFromPath(filePathX);
            localPath = dm.diskName + "/" + dm.getOldRelativePathWithoutSlash(filePathX);
        }
        jobj.put("localPath", localPath);
        allArts.put(jobj);
    }

%>
<html ng-app="photoApp">
<head>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>

    <script>
    var photoApp = angular.module('photoApp', []);
    photoApp.controller('photoCtrl', function ($scope) {
        $scope.recs = <% allArts.write(out);%>;
        $scope.thisPath = "<%=thisPage%>";
    });
</script>
</head>
<body ng-controller="photoCtrl">
<h3>News Articles Details  <%=queueMsg%> <a href="newsDetail2.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>">#1</a></h3>
<p><a href="news.jsp?<%=startPart%>">News</a>
   | <font color="red">Articles</font>
   | <a href="newsFiles.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>">Files</a>
   | <a href="newsPatterns.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>">Patterns</a>
   | <a href="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>&sort=num">Sort_by_Number</a>
   | <a href="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>&sort=dig">Sort_by_Subject</a></p>

<table><tr><td>Pattern: </td><td bgcolor="<%=bunch.getStateColor()%>"><%
    HTMLWriter.writeHtml(out, tokenFill(bunch.digest));
%></td></tr></table>
<ul>
    <form action="newsDetailAction.jsp?dig=<%=URLEncoder.encode(dig, "UTF-8")%>"  name="moveForm" method="post">
    <li>From: <%
        HTMLWriter.writeHtml(out, fromUser);
    %></li>
    <li>Current: <font color="brown"><%
        HTMLWriter.writeHtml(out, folder);
        HTMLWriter.writeHtml(out, bunch.getTemplate());
    %></font>
    </li>
    <li>
    <%
        for (String destVal : destVec) {
    %>
        <input onClick="moveForm.folder.value='<%=destVal%>'"
              type="button" value="<%=destVal%>"/>
    <%
        }
    %>
    </li><li>
    Folder: <input type="text" name="folder" value="<%HTMLWriter.writeHtml(out, folder);%>" size="70">
                    <input type="submit" name="cmd" value="Set And Move Files">
                    <input type="checkbox" name="createIt" value="yes" checked="checked"> Create?
                    <input type="submit" name="cmd" value="Set Without Files">

    </li>
    <li>Template: <input type="text" name="template" value="<%HTMLWriter.writeHtml(out, bunch.getTemplate());%>" size="110">

                <input type="checkbox" name="plusOne" value="true" <% if (bunch.plusOneNumber) {%>checked="checked"<%}%>> Plus One
                </li>
    <li>ExtraTags: <input type="text" name="extraTags" value="<%HTMLWriter.writeHtml(out, bunch.extraTags);%>" size="50">
                <input type="submit" name="cmd" value="Set Tags">
                </li>
    <li>        <input type="submit" name="cmd" value="GetPatt"> |
                <input type="submit" name="cmd" value="SetPattern">
                <input type="submit" name="cmd" value="Cover">
                <input type="submit" name="cmd" value="Flogo">
                <input type="submit" name="cmd" value="Sample">
                <input type="submit" name="cmd" value="SetIndex">
                <input type="submit" name="cmd" value="SetOneIndex">
                AutoPath: <input type="checkbox" name="autopath" value="true" checked="checked">
                Zing: <%HTMLWriter.writeHtml(out, zingpat);%></li>
    <hr/>
    <input type="hidden" name="go" value="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>">

    <input type="hidden" name="start" value="<%=start%>">
    <input type="submit" name="cmd" value="Hide">
    <input type="checkbox" name="delAll" value="delAll"> Delete All
    <input type="submit" name="cmd" value="Get A Bit">
    <%
        if (bunch.pState == NewsBunch.STATE_INITIAL) {

    %><input type="submit" name="cmd" value="Mark Interested"><%

    %><input type="submit" name="cmd" value="Seek Bunch"><%

    %><input type="submit" name="cmd" value="Download All"><%

    %><input type="submit" name="cmd" value="Mark Complete"><%
        }
        else if (bunch.pState == NewsBunch.STATE_INTEREST || bunch.pState == NewsBunch.STATE_GETABIT) {
    %><input type="submit" name="cmd" value="Cancel Interest"><%

    %><input type="submit" name="cmd" value="Seek Bunch"><%
        if (folderExists) {
    %><input type="submit" name="cmd" value="Download All"><%
        }
            else {
    %> need folder <%
        }
    %><input type="submit" name="cmd" value="Mark Complete"><%
        }
        else if (bunch.pState == NewsBunch.STATE_SEEK) {
    %><input type="submit" name="cmd" value="Cancel Seek"><%
        if (folderExists) {
    %><input type="submit" name="cmd" value="Download All"><%
        }
            else {
    %> need folder <%
        }
        }
        else if (bunch.pState == NewsBunch.STATE_SEEK_DONE) {
    %><input type="submit" name="cmd" value="Cancel Interest"><%

    %><input type="submit" name="cmd" value="Seek Bunch"> (seek done)<%
        if (folderExists) {
    %><input type="submit" name="cmd" value="Download All"><%
        }
            else {
    %> need folder <%
        }
    %><input type="submit" name="cmd" value="Mark Complete"><%
        }
        else if (bunch.pState == NewsBunch.STATE_DOWNLOAD) {
    %><input type="submit" name="cmd" value="Seek Bunch"><%

    %><input type="submit" name="cmd" value="Cancel Download"><%
        }
        else if (bunch.pState == NewsBunch.STATE_DOWNLOAD_DONE) {
    %><input type="submit" name="cmd" value="Cancel Interest"><%

    %><input type="submit" name="cmd" value="Seek Bunch"><%

    %><input type="submit" name="cmd" value="Download All"> (download done)<%

    %><input type="submit" name="cmd" value="Mark Complete"><%
        }
        else if (bunch.pState == NewsBunch.STATE_COMPLETE) {
    %><input type="submit" name="cmd" value="Cancel Interest"><%

    %><input type="submit" name="cmd" value="Mark Interested"><%
        }
        else if (bunch.pState == NewsBunch.STATE_HIDDEN) {
    %><input type="submit" name="cmd" value="Mark Interested"> (cancel hidden state) <%
    }
    if (bunch.appearsToNeedSeek(newsGroup)) {
        %> (Appears to need seeking) <%
    }
    else {
        %> (Most headers available) <%
    } %>
    </form>
</ul>
<table>
  <tr ng-repeat="rec in recs">
     <td><a href="newsOne.jsp?artno={{rec.num}}">{{rec.num}}</a> &nbsp; </td>
     <td>{{rec.subject}}</td>
     <td><a href="newsMatch.jsp?artno={{rec.num}}"><img src="search.png"></a>
         <span ng-show="rec.viz"><a href="/photo/photo/{{rec.localPath}}"
               target="photo"><img src="fileExists.png"></a></span>
         <span ng-hide="rec.viz"><a href="newsOneAction.jsp?artno={{rec.num}}&action=Read%20Article"
               target="photo"><img src="downicon.gif"></a></span></td>
     <td>{{rec.fileName}}</td>
  </tr>
</table>
<table>
<p>Displayed {{recs.length}} subject lines, ((pCount)) of them partially complete.</p>
</body>

<%!public String tokenFill(String digest) {

        StringBuffer res = new StringBuffer();
        int count = 0;
        for (int i=0; i<digest.length(); i++) {

            char ch = digest.charAt(i);

            if (ch == NewsArticle.special) {
                res.append("$");
                res.append(Integer.toString(count));
                count++;
            }
            else {
                res.append(ch);
            }

        }
        return res.toString();
    }%>


<script>
    window.setTimeout(function(){window.location="<%=thisPage%>";},60000);
</script>

</html>
