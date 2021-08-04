<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.PosPat"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.photegrity.MongoDB"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.lang.Exception"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Arrays"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Comparator"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Random"
%><%@page import="java.util.Vector"
%><%@page import="java.util.List"
%><%@page import="java.util.ArrayList"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.JavaScriptWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    String pageName = "allPatts.jsp";
    long starttime = System.currentTimeMillis();

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String query = UtilityMethods.reqParam(request, pageName, "q");
    String order = UtilityMethods.defParam(request, "o", "name");

    // DETERMINE the sort order
    String po    = UtilityMethods.defParam(request, "po", "size");
    boolean sortBySize = po.equals("size");
    String poPart = "po=patt";
    if (sortBySize) {
        poPart = "po=size";
    }


    int dispMin  = UtilityMethods.defParamInt(request, "min", 0);

    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    int imageNum = UtilityMethods.getSessionInt(session, "imageNum", 3);
    int rows = (UtilityMethods.getSessionInt(session, "pageSize", 20));
    String iChoice = (String) session.getAttribute("iChoice");
    if (iChoice==null)
    {
        iChoice = "*,*,*";
    }

    String thisBaseURL = "allPatts.jsp?q="+URLEncoder.encode(query,"UTF8");
    String thisPageURL = thisBaseURL + "&min=" + dispMin + "&" + poPart;
    boolean showImages = (request.getParameter("img")!=null);
    String pictParam = "";
    String imgPart = "";
    if (showImages) {
        thisPageURL += "&img=1";
        pictParam = "&img=1";
        rows = (rows+1)/imageNum;
        imgPart = "img=1";
    }
    rows=4;

    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + rows;
    int prevPage = dispMin - rows;
    if (prevPage < 0) {
        prevPage = 0;
    }

    HashCounter groupCount = new HashCounter();
    HashCounter pattCount = new HashCounter();
    HashCounter symbolCount = new HashCounter();

    MongoDB mongo = new MongoDB();
    mongo.queryStatistics(query, groupCount, pattCount, symbolCount);
    mongo.close();

    List<String> sortedPatterns = new ArrayList<String>();
    for (String symbol : symbolCount.sortedKeys()) {
        sortedPatterns.add(symbol);
    }
    sortGroupsByCount(sortedPatterns, symbolCount);
    
    String[] colors = {"#FDF5E6", "#FEF9F5"};

    Random rand = new Random(System.currentTimeMillis());
    int imageLimit = 30;

    String queryOrderPart = URLEncoder.encode(query,"UTF8")+"&o="+order;
    String queryOrderFull = queryOrderPart+"&min="+dispMin;

    int maxpagestart = sortedPatterns.size() - rows;
    if (maxpagestart<0)
    {
        maxpagestart=0;
    }

    int[] imgChoices = new int[imageNum];
    int commaPos = iChoice.indexOf(",");
    int startPos = 0;
    int choiceCnt = 0;
    while (choiceCnt<imageNum && commaPos>0)
    {
        String piece = iChoice.substring(startPos, commaPos);
        if ("*".equals(piece))
        {
            imgChoices[choiceCnt] = -1;
        }
        else
        {
            imgChoices[choiceCnt] = safeConvertInt(piece);
        }
        choiceCnt++;
        startPos = commaPos+1;
        commaPos = iChoice.indexOf(",", startPos);
    }
    while (choiceCnt<imageNum)
    {
        imgChoices[choiceCnt] = -1;
        choiceCnt++;
    }

    String zingpat = (String) session.getAttribute("zingpat");
    if (zingpat==null) {
        zingpat = "";
    }
    
    String lastPatternName = "";
    JSONObject allPatterns = symbolCount.getJSON();


%>


<html ng-app="fileApp">
<head>
    <meta charset="UTF-8">
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls-0.12.0.js"></script>
    <TITLE>P <%=dispMin%>/<%=sortedPatterns.size()%> <%= query %></TITLE>
    
    <style>
    .spacy tr td {
        padding:3px;
    }
    </style>
</head>

<script>
var fileApp = angular.module('fileApp', []);
fileApp.controller('fileCtrl', function ($scope, $http) {
    $scope.templatePattern = "<%JavaScriptWriter.encode(out,lastPatternName);%>";
    $scope.allPatterns = <%allPatterns.write(out,2,2);%>;
    
    $scope.randomName= function() {
        var rez = "";
        while (rez.length<14) {
            rez = rez + String.fromCharCode(Math.random()*26 + 97);
        }
        $scope.templatePattern = rez;
        console.log("RANDOM", rez);
    }
    $scope.clearSpaces = function() {
        var rez = "";
        for (var i = 0; i < $scope.templatePattern.length; i++) {
          var ch = $scope.templatePattern[i];
          if (ch!=' ') {
              rez = rez.concat(ch);
          }
        }
        $scope.templatePattern = rez;
        console.log("clearSpaces", rez);
    }

});
</script>

<body ng-controller="fileCtrl">
<table><tr><td>

<table><tr>
   <td>
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderPart%>">T</a>
   </td><td bgcolor="#FF0000">
      <a href="allPatts.jsp?q=<%=queryOrderPart%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
      <a href="startGrid.jsp?q=<%=queryOrderPart%>&min=<%=dispMin%>">Grid</a>
   </td><td>
      <%HTMLWriter.writeHtml(out,query);%>   #<%= symbolCount.size() %> -
      <img src="pattSelect.gif"> [<%HTMLWriter.writeHtml(out,zingpat);%>]
   </td></tr>
</table>
<a href="main.jsp"><img src="home.gif" border="0"></a>
<a href="allPatts.jsp?q=s(1)">1</a>
<a href="allPatts.jsp?q=s(2)">2</a>
<a href="allPatts.jsp?q=s(3)">3</a>
        <a href="allPatts.jsp?q=<%=queryOrderPart%>&min=0<%=pictParam%>&<%=poPart%>">
            <img src="ArrowFRev.gif" border="0"></a>
        <a href="allPatts.jsp?q=<%=queryOrderPart%>&min=<%=prevPage%><%=pictParam%>&<%=poPart%>">
            <img src="ArrowBack.gif" border="0"></a>
        <%= dispMin %> / <%= sortedPatterns.size() %>
        <a href="allPatts.jsp?q=<%=queryOrderPart%>&min=<%=dispMax%><%=pictParam%>&<%=poPart%>">
            <img src="ArrowFwd.gif" border="0"></a>
        <a href="allPatts.jsp?q=<%=queryOrderPart%>&min=<%= maxpagestart %><%=pictParam%>&<%=poPart%>">
            <img src="ArrowFFwd.gif" border="0"></a>
<%
    String extBase = thisBaseURL + "&min=" + dispMin;
    if (showImages) {
        %><a href="<%=extBase%>&<%=poPart%>">NoImages</a> &nbsp;<%
    } else {
        %><a href="<%=extBase%>&img=1&<%=poPart%>">Images</a> &nbsp;<%
    }
    if (sortBySize) {
        %><a href="<%=extBase%>&<%=imgPart%>&po=patt">Sort By Pattern</a><%
    } else {
        %><a href="<%=extBase%>&<%=imgPart%>&po=size">Sort By Size</a><%
    }
%>
<img src="bar.jpg" border="0">
<table class="spacy">
<%
    int row = 0;
    int count = 0;
    lastPatternName = null;
    for (String symbol : sortedPatterns) {
        count++;
        if (count<dispMin) {
            continue;
        }
        if (count>=dispMax) {
            break;
        }

        lastPatternName = symbol;
        String limitedPatternName = symbol;
        String trimmedPattern = symbol.trim();
        String newQuery = URLEncoder.encode(query+"x("+symbol+")","UTF8");
        if (limitedPatternName.length() > 46) {
            limitedPatternName = limitedPatternName.substring(0,45)+"...";
        }
        String thisRowColor = colors[(row++)%2];
        if (zingpat.equals(lastPatternName)) {
            thisRowColor = "#FEF922";
        }
%>
   <tr bgcolor="<%=thisRowColor%>">
   <td><font size="-4" color="#99CC99"><%=count%></font>
   </td>
<%

        if (showImages)
        {
            JSONObject image = new JSONObject();
            int setSize = symbolCount.size();
            %><td width="<%=(thumbsize+10)*imageNum%>"><%
            if ((--imageLimit)>0) {
                if (imageNum >= setSize) {
                    for (int ni = 0; ni<setSize; ni++) {
                        //image = "XXXNOTFINISHED";
%>                  <a href="photo/<%=image.getString("path")%>" target="photo">
                        <img src="thumb/<%=thumbsize%>/<%=image.getString("path")%>" width="<%=thumbsize%>" borderwidth="0" border="0"></a>
<%                  }
                }
                else {
                    boolean[] repeatGuard = new boolean[setSize];
                    for (int ni = 0; ni<imageNum; ni++)
                    {
                        int choice = 0; //findTarget(pi.allImages, imgChoices[ni]);
                        if (choice < 0)
                        {
                            choice = rand.nextInt(setSize);
                        }
                        while (repeatGuard[choice])
                        {
                            choice = rand.nextInt(setSize);
                        }
                        repeatGuard[choice]=true;
                        //image = pi.allImages.elementAt(choice);
%>                  <a href="photo/<%=image.getString("path")%>" target="photo">
                        <img src="thumb/<%=thumbsize%>/<%=image.getString("localPath")%>" width="<%=thumbsize%>" borderwidth="0" border="0"></a>
<%                  }
                }
            }
%>
            </td>
          <td><a href="show.jsp?q=x(<%=URLEncoder.encode(symbol,"UTF8")%>)">
              <%HTMLWriter.writeHtml(out,symbol);%></a><br>
              <%= symbolCount.getCount(symbol) %>
              <a href="show.jsp?q=<%=newQuery%>">S</a>
              <a href="analyzeQuery.jsp?q=<%=newQuery%>">A</a>
              <a href="xgroups.jsp?q=<%=newQuery%>">T</a>
              <a href="queryManip.jsp?q=<%=newQuery%>">M</a>
              <a href="allPatts.jsp?q=<%=newQuery%>">P</a>
              <%= 0 %> - <%= 0 %><br>
              <a href="selectQuery.jsp?q=<%=newQuery%>&o=<%=order%>" target="suppwindow"><img border=0 src="addicon.gif"></a>
              <a href="zing.jsp?pat=<%=URLEncoder.encode(symbol,"UTF8")%>&go=<%=URLEncoder.encode(thisPageURL,"UTF8")%>"
                 title="Select this pattern for use elsewhere"><img src="pattSelect.gif" border="0"></a><br>
            <table border="0"><tr>
<%
            if (symbolCount.getCount(symbol)==1 && image!=null) {
%>
                <form method="get" action="renameFile.jsp">
                <td>
                <input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, image.getString("disk"));%>">
                <input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, image.getString("fileName"));%>">
                <input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"000.cover.jpg");%>">
                <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPageURL);%>">
                <input type="submit" value="cover">
                </td>
                </form>
                <form method="get" action="renameFile.jsp">
                <td>
                <input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, image.getString("disk"));%>">
                <input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, image.getString("fileName"));%>">
                <input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"000.flogo.jpg");%>">
                <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPageURL);%>">
                <input type="submit" value="flogo">
                </td>
                </form>
                <form method="get" action="renameFile.jsp">
                <td>
                <input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, image.getString("disk"));%>">
                <input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, image.getString("fileName"));%>">
                <input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"000.sample.jpg");%>">
                <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPageURL);%>">
                <input type="submit" value="sample">
                </td>
                </form>
                <form method="get" action="renameFile.jsp">
                <td>
                <input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, image.getString("disk"));%>">
                <input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, image.getString("fileName"));%>">
                <input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"!01.jpg");%>">
                <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPageURL);%>">
                <input type="submit" value="Single Index">
                </td>
                </form>
<%
            }
            else {

                if (trimmedPattern.length() != symbol.length()) {
%>
                </td>
                <form action="changeSelection.jsp" method="post">
                <td>
                <input type="submit" value="Trim Pattern">
                <input type="hidden" name="p2" value="<%HTMLWriter.writeHtml(out,trimmedPattern);%>">
                <input type="hidden" name="p1" value="<%HTMLWriter.writeHtml(out,lastPatternName);%>">
                <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
                <input type="hidden" name="dest" value="<%HTMLWriter.writeHtml(out,thisPageURL);%>">
                </td>
                </form>
                <td>
<%
                }
             }
%>


            </tr></table><%
        }
        else {
%>
      <td><%= symbolCount.getCount(symbol) %></td>
      <td><a href="show.jsp?q=x(<%=URLEncoder.encode(symbol,"UTF8")%>)"><%HTMLWriter.writeHtml(out,limitedPatternName);%></a></td>
<%
        if (symbolCount.getCount(symbol)>1) {
%>
      <td><a href="show.jsp?q=<%=newQuery%>">S</a></td>
      <td><a href="analyzeQuery.jsp?q=<%=newQuery%>">A</a>
          <a href="xgroups.jsp?q=<%=newQuery%>">T</a>
          <a href="queryManip.jsp?q=<%=newQuery%>">M</a>
              <a href="allPatts.jsp?q=<%=newQuery%>">P</a></td>
<%
        } else {
            JSONObject image = null; //pi.allImages.elementAt(0);
%>
      <td><a href="photo/<%=image.getString("path")%>" target="photo">D</a></td>
      <td><a href="show.jsp?q=<%=newQuery%>">S</a>
          <a href="xgroups.jsp?q=<%=newQuery%>">T</a>
          <a href="queryManip.jsp?q=<%=newQuery%>">M</a>
          <a href="allPatts.jsp?q=<%=newQuery%>">P</a></td>
<%
        }
%>
      <td><a href="zing.jsp?pat=<%=URLEncoder.encode(symbol,"UTF8")%>&go=<%=URLEncoder.encode(thisPageURL,"UTF8")%>"
             title="Select this pattern for use elsewhere"><img src="pattSelect.gif" border="0"></a></td>
      <td><a href="allPatts.jsp?q=<%=URLEncoder.encode(query+"x("+symbol+")","UTF8")%>">Exclude</a></td>
      <td><%= 0 %> - <%= 0 %></td>
      <td>
<%
        }
        int cxx = 0;
        for (PosPat pp : PosPat.findAllPattern(symbol)){
            String sym = pp.getSymbol();
            if (cxx++>12) {
                out.write("...<br/>\n");
                break;
            }
            if (sym.length()>45) {
                sym = sym.substring(0,45);
            }
            HTMLWriter.writeHtml(out, sym);
            out.write("  ("+pp.getImageCount());
            out.write(")");
            out.write("<img src=\"load.gif\">");
            out.write("<br/>\n");
        }
%>
        </td>
<%
        out.flush();
     }
%>

</table>
<img src="bar.jpg" border="0"><br>
<table>
    <tr><form action="changeSelection.jsp" method="get">
        <td>

        <input type="submit" value="Change">
        to <input type="text" name="p2" ng-model="templatePattern" size="40">
        from <b><%HTMLWriter.writeHtml(out,lastPatternName);%></b>
        <input type="hidden" name="p1" value="<%HTMLWriter.writeHtml(out,lastPatternName);%>">
        <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        <input type="hidden" name="dest" value="<%HTMLWriter.writeHtml(out,thisPageURL);%>">
        </td></form>
        <td><button ng-click="randomName()">Randomize</button>
            <button ng-click="clearSpaces()">ClearSpaces</button></td>
    </tr>
    <tr><form action="changeSelection.jsp" method="get">
        <td>
        <img src="pattSelect.gif" border="0"> Change pattern to
        <input type="submit" name="p2" value="<%HTMLWriter.writeHtml(out,zingpat);%>" size="40">
        or
        <input type="submit" name="p2" value="<%HTMLWriter.writeHtml(out,zingpat);%>!" size="40">
        from <b><%HTMLWriter.writeHtml(out,lastPatternName);%></b>
        <input type="hidden" name="p1" value="<%HTMLWriter.writeHtml(out,lastPatternName);%>">
        <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        <input type="hidden" name="dest" value="<%HTMLWriter.writeHtml(out,thisPageURL);%>">
        </td></form>
    </tr>
</table>
<a href="main.jsp"><img src="home.gif" border="0"></a>
        <a href="allPatts.jsp?q=<%=queryOrderPart%>&min=<%=prevPage%><%=pictParam%>&<%=poPart%>">
            <img src="ArrowBack.gif" border="0"></a>
        <%= dispMin %> / <%= sortedPatterns.size() %>
        <a href="allPatts.jsp?q=<%=queryOrderPart%>&min=<%=dispMax%><%=pictParam%>&<%=poPart%>">
            <img src="ArrowFwd.gif" border="0"></a>
<%
    if (showImages) {
        %><a href="<%=extBase%>">NoImages</a><%
    } else {
        %><a href="<%=extBase%>&img=1">Images</a><%
    }
%>
</td></tr></table>
<table width="600"><tr width="600"><td width="600">
        <form method="GET" action="allPatts.jsp">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Search:">
            <input type="text" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="text" size="5" name="min" value="<%=dispMin%>">
        </form>
</td></tr><tr><td>
<form action="setPict.jsp" method="get">
  <input type="submit" value="Set">
  Thumbnail Size: <input type="text" name="thumbsize" size="5" value="<%=thumbsize%>">
  Image Num: <input type="text" name="imageNum" size="5" value="<%=imageNum%>">
  Image Choice: <input type="text" name="iChoice" size="5" value="<%=iChoice%>">
  <input type="hidden" name="go" value="<%=thisPageURL%>">
</form>
</td></tr></table>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
</BODY>
</HTML>

<%!public static void sortPatternsByCount(Vector<PatternInfo> patterns)
        throws Exception
    {
        PatternsByCountComparator sc = new PatternsByCountComparator();
        Collections.sort(patterns, sc);
    }


    static class PatternsByCountComparator implements Comparator
    {
        public PatternsByCountComparator() {}

        public int compare(Object o1, Object o2)
        {
            if (!(o1 instanceof PatternInfo)) {
                return -1;
            }
            if (!(o2 instanceof PatternInfo)) {
                return 1;
            }
            if (((PatternInfo)o1).count > ((PatternInfo)o2).count) {
                return -1;
            }
            else if (((PatternInfo)o1).count == ((PatternInfo)o2).count) {
                return 0;
            }
            else {
                return 1;
            }
        }
    }

    public
    static
    void
    sortPatternsByName(Vector<PatternInfo> patterns)
        throws Exception
    {
        PatternsByNameComparator sc = new PatternsByNameComparator();
        Collections.sort(patterns, sc);
    }


    static class PatternsByNameComparator implements Comparator
    {
        public PatternsByNameComparator() {}

        public int compare(Object o1, Object o2)
        {
            if (!(o1 instanceof PatternInfo)) {
                return -1;
            }
            if (!(o2 instanceof PatternInfo)) {
                return 1;
            }
            return ((PatternInfo)o1).pattern.compareToIgnoreCase(((PatternInfo)o2).pattern);
        }
    }

    String x = "0123456789ABCDEF";

    public String myEncode(String v)
    {
        StringBuffer res = new StringBuffer();
        int last = v.length();
        for (int i=0; i<last; i++) {
            char ch = v.charAt(i);
            if (ch < 32 || ch == '(' || ch == ')') {
                addPercent(res, ch);
            }
            else if (ch < 128) {
                res.append(ch);
            }
            else if (ch < 2048) {
                int f = (int)(ch/64) + 128 + 64;
                addPercent(res, f);
                f = (int)(ch%64) + 128;
                addPercent(res, f);
            }
            else {
                int f = (int)(ch/64/64) + 128 + 64 + 32;
                addPercent(res, f);
                f = (int)((ch/64)%64) + 128;
                addPercent(res, f);
                f = (int)(ch%64) + 128;
                addPercent(res, f);
            }
        }
        return res.toString();
    }

    public void addPercent(StringBuffer res, int f)
    {
        res.append('%');
        res.append(x.charAt(f/16));
        res.append(x.charAt(f%16));
    }

    public int findTarget(Vector<JSONObject> imageSet, int targetNo) throws Exception {
        if (targetNo<1)
        {
            return -1;
        }
        int pos = 0;
        for (JSONObject ii : imageSet) {
            if (ii.getInt("value") >= targetNo) {
                return pos;
            }
            pos++;
        }
        return -1;
    }%>
    <%@ include file="functions.jsp"%>
