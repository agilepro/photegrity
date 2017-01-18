<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.UUDecoderStream"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.OutputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="org.workcast.streams.MemFile"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    String ignoreTags = (String) session.getAttribute("ignoreTags");
    if (ignoreTags==null) {
        ignoreTags = "";
        session.setAttribute("ignoreTags", ignoreTags);
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession ns = newsGroup.session;

    String artno     = UtilityMethods.reqParam(request, "News One Page", "artno");
    long artnoInt = Long.parseLong(artno);
    if (!newsGroup.hasArticle(artnoInt)) {
        throw new Exception("The page newsMatch.jsp requires an article number with header that have been downloaded.");
    }
    NewsArticle art = (NewsArticle) newsGroup.getArticleOrNull(artnoInt);
    NewsBunch npatt = newsGroup.getBunch(art.getDigest());
    NewsFile nf = npatt.getFileForArticle(art);

    String url = "newsDetail2.jsp?d="+URLEncoder.encode(art.getDigest(), "UTF-8");
    String thisUrl = "newsMatch.jsp?artno="+artnoInt;

    String  fileName = art.fillTemplate(npatt.getTemplate());


    String[] parts  = NewsBunch.getFileNameParts(fileName);

    String pattern = parts[0];
    String value = parts[1];
    int valueInt = UtilityMethods.safeConvertInt(value);
    if (value.startsWith("!")) {
        valueInt = -valueInt;
    }
    String tail = parts[2];
    String patternLC = pattern.toLowerCase();


    Vector<PatternInfo> piSet = new Vector<PatternInfo>();
    for (PatternInfo pit : ImageInfo.getAllPatternsStartingWith(pattern)) {
        if (pit.pattern.equalsIgnoreCase(pattern)) {
            piSet.add(pit);
        }
    }

    //find the offset in the master pattern list
    Vector<PosPat> allPatts = PosPat.getAllEntries();

    int min = 0;
    int max = allPatts.size();
    while (max - min > 1) {
        int middle = (max+min)/2;
        String item = allPatts.elementAt(middle).getPattern();
        if (pattern.compareToIgnoreCase(item) > 0) {
            min = middle;
        }
        else {
            max = middle;
        }
    }
    String startPart = "search="+URLEncoder.encode(art.getDigest(),"UTF-8");
    Vector<String> allTags = new Vector<String>();

    %>
    <html>
    <body>
    <%
    if (nf!=null && npatt.hasTemplate()) {
        File matchingFile = nf.findMatchingFile();
        if (matchingFile!=null && false) {
            ImageInfo ii = nf.getImageInfo();
            if (ii!=null) {
                for (String tag : ii.getTagNames()) {
                    if (tag.indexOf(".")<0) {
                        //some tags have a dot in them ... long story, ignore them
                        allTags.add(tag);
                    }
                }
            }
        }
        else {
            Vector<PosPat> vpp = npatt.getPosPatList();
            for (PosPat pp : vpp) {
                for (String tag : parseTags(pp.getSymbol())) {
                    if (!allTags.contains(tag)) {
                        allTags.add(tag);
                    }
                }
            }
        }
    }
    for (String t2 : parseTags(npatt.extraTags)) {
        allTags.add(t2);
    }
    for (String t3 : parseTags(ignoreTags)) {
        if (allTags.contains(t3)) {
            allTags.remove(t3);
        }
    }
    Collections.sort(allTags);

    %>
<html>
<head>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls.min.js"></script>
    <link href="photoStyle.css" rel="stylesheet">
</head>
<body>
<h3>News Article Match</h3>
<table><tr><td><a href="news.jsp?<%=startPart%>">News</a></td>
           <td><a href="newsDetail2.jsp?d=<%=URLEncoder.encode(art.getDigest(),"UTF-8")%>">Articles</a></td>
           <td><a href="newsFiles.jsp?d=<%=URLEncoder.encode(art.getDigest(),"UTF-8")%>">Files</a></td>
           <td><a href="newsPatterns.jsp?d=<%=URLEncoder.encode(art.getDigest(),"UTF-8")%>">Patterns</a></td></tr>
           </table>
<hr/>

<ul>
<li> Article number: <%= art.getNumber()  %> </li>
<li> Date: <%= art.getHeaderDate()  %> </li>
<li> SampleFileName: <%  HTMLWriter.writeHtml(out, npatt.getSampleFileName() ); %></li>
<li> Subject: <% HTMLWriter.writeHtml(out, art.getHeaderSubject()); %> </li>
<li> From: <% HTMLWriter.writeHtml(out, art.getHeaderFrom()); %> <% HTMLWriter.writeHtml(out, art.getHeaderDate()); %> </li>
<li> Digest: <a href="<%=url%>"><% HTMLWriter.writeHtml(out, art.getDigest() ); %></a> </li>
<li> FolderLoc: <% HTMLWriter.writeHtml(out, npatt.getFolderLoc() ); %> </li>
<li> FileName: <% HTMLWriter.writeHtml(out, fileName); %>
      <% if (art.buffer!=null) { %> <a href="newsPict.jsp?artno=<%=artnoInt%>" target="photo">BODY</a> <% } %></li>
<li> Pattern:
     <a href="pattern2.jsp?g=<%=URLEncoder.encode(patternLC,"UTF-8")%>"><% HTMLWriter.writeHtml(out, patternLC); %></a>
     Value: <% HTMLWriter.writeHtml(out, value); %>
     Tail: <% HTMLWriter.writeHtml(out, tail); %> </li>

<li> Tags:
<%
    for (String tag : allTags) {
        out.write("<a href=\"group.jsp?g=");
        UtilityMethods.writeURLEncoded(out, tag);
        out.write("\">");
        HTMLWriter.writeHtml(out, tag);
        out.write("</a>, ");
    }
%> </li>
<li> Val<%=value%>:
<%
    for (String tag : allTags) {
        out.write("<a href=\"startGrid.jsp?q=g(");
        UtilityMethods.writeURLEncoded(out, tag);
        out.write(")&min="+value);
        out.write("\">");
        HTMLWriter.writeHtml(out, tag);
        out.write("</a>, ");
    }
                %><br/><%
    for (String tag : allTags) {
        for (String tag2 : allTags) {
            if (tag.compareTo(tag2)>=0) {
                continue;
            }
            out.write("<a href=\"startGrid.jsp?q=g(");
            UtilityMethods.writeURLEncoded(out, tag);
            out.write(")g(");
            UtilityMethods.writeURLEncoded(out, tag2);
            out.write(")&min="+value);
            out.write("\">");
            HTMLWriter.writeHtml(out, tag);
            out.write("+");
            HTMLWriter.writeHtml(out, tag2);
            out.write("</a>, ");
        }
    }
%> </li>
</ul>
<hr/>
    <ul>
    <%
    String thisSymbol = npatt.getFolderLoc() + npatt.getSampleFilePattern();
    for (PosPat pp : PosPat.findAllPattern(pattern)) {
        DiskMgr dm = pp.getDiskMgr();
        String loc = dm.diskName + ":" + pp.getLocalPath();
        int count2 = pp.getImageCount();
        %> <form action="newsMatchAction.jsp"><li><%HTMLWriter.writeHtml(out, pp.getSymbol());%> &nbsp; <%
        if (!dm.isLoaded) {
            %><a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(thisUrl,"UTF8")%>"
                 title="Load into memory disk named <%=dm.diskName%>"><img src="load.gif" border="0"></a>  <%
        }
        else {
            %>  <%
        }
        %> &nbsp; <b><%=count2%></b> <%
        if (thisSymbol.equalsIgnoreCase(pp.getSymbol())) {
            %> (THERE) <%
        }
        else {
            %> Move:
            <input type="hidden" name="artno" value="<%=artnoInt%>"/>
            <input type="hidden" name="cmd" value="Use This Path"/>
            <input type="submit" name="p" value="<% HTMLWriter.writeHtml(out, loc); %>"/>
            <br/><%
        }
        %></li></form><%
    }
    %> </ul><hr/>

        <form action="newsMatchAction.jsp">
        <input type="hidden" name="artno" value="<%=artnoInt%>"/>
        Add Tags: <input type="text" name="extraTags" value="<%HTMLWriter.writeHtml(out, npatt.extraTags);%>" size="50">
        <input type="submit" name="cmd" value="Set Tags">
        </form>

    <hr/>

        <form action="newsMatchAction.jsp">
        <input type="hidden" name="artno" value="<%=artnoInt%>"/>
        Ignore Tags: <input type="text" name="ignoreTags" value="<%HTMLWriter.writeHtml(out, ignoreTags);%>" size="50">
        <input type="submit" name="cmd" value="Set Ignore">
        </form>

    <hr/>
<%
    for (PatternInfo pi : piSet) {

        %>
        <p>Found: "<% HTMLWriter.writeHtml(out, pi.pattern);

        if (!pi.pattern.equals(pattern)) {
            %> <font color="red">Which does not MATCH</font> <%
        }
        %>"</p>
        <%
        Vector<String> examplePaths = new Vector<String>();
        Vector sortedImages = new Vector();
        sortedImages.addAll(pi.allImages);
        ImageInfo.sortImages(sortedImages, "name");
        Enumeration e2 = sortedImages.elements();
        int totalCount=-1;
        int[] missingTable = new int[2000];
        for (int k=0; k<2000; k++) {
            missingTable[k] = 0;
        }
        while (e2.hasMoreElements()) {
            ImageInfo ii = (ImageInfo)e2.nextElement();
            String thisImagePath = ii.diskMgr.diskName +":"+ ii.getRelativePath();
            if (!examplePaths.contains(thisImagePath)) {
                examplePaths.add(thisImagePath);
            }
            if (ii.value < 1000) {
                missingTable[1000+ii.value]++;
            }
            if (valueInt == ii.value) {
                %>Image: <a href="photo/<%=ii.getRelPath()%>" target="photo"><%
                HTMLWriter.writeHtml(out, thisImagePath+ii.fileName);
                %></a>
                  <form action="newsMatchAction.jsp">
                  <input type="hidden" name="artno" value="<%=artnoInt%>"/>
                  <input type="hidden" name="cmd" value="Use This Path"/>
                  <input type="submit" name="p" value="<% HTMLWriter.writeHtml(out, thisImagePath); %>"/>
                  <% if (thisImagePath.equalsIgnoreCase(npatt.getFolderLoc())) { %>
                  <font color="red">ALREADY THERE</font>
                  <% } else if (npatt.hasFolder()) { %>
                  from <% HTMLWriter.writeHtml(out, npatt.getFolderLoc()); %>
                  <% } %>
                  </form><br/><%
            }
        }
        %>Contains: &nbsp; <%

        int i=0;
        while (i<2000 && missingTable[i] == 0) {
            i++;
        }
        int rstart = i;
        int rend = i;
        while (i<2000) {
            while (i<2000 && missingTable[i]>0) {
                rend = i;
                i++;
            }
            if (i == 2000) {
                out.write(Integer.toString(rstart-1000));
                out.write("-1000+");
                break;
            }
            if (rstart < rend) {
                out.write(Integer.toString(rstart-1000));
                out.write("-");
                out.write(Integer.toString(rend-1000));
                out.write(", ");
            }
            else {
                out.write(Integer.toString(rstart-1000));
                out.write(", ");
            }


            while (i<2000 && missingTable[i]==0) {
                i++;
            }
            if (i == 2000) {
                break;
            }
            rstart = i;
        }

%>
    <br/>Missing: &nbsp; <%

        i=0;
        while (i<2000 && missingTable[i]==0) {
            i++;
        }
        min = i;
        max = i;
        while (i<2000) {
            while (i<2000 && missingTable[i]>0) {
                max = i;
                i++;
            }
            if (i == 2000) {
                break;
            }
            int starts = i;
            while (i<2000 && missingTable[i]==0) {
                i++;
            }
            if (i == 2000) {
                break;
            }
            if (starts < i-1) {
                out.write("" + (starts-1000) + "-" + (i-1001) + ", ");
            }
            else {
                out.write("" + (starts-1000) + ", ");
            }
        }

        out.write("<br>Min: " + (min-1000) + "  Max: " + (max-1000));

%>
    <br/>Duplicate: &nbsp; <%

        i=0;
        while (i<2000 && missingTable[i]<2) {
            i++;
        }
        int dstart = i;
        int dend = i;
        while (i<2000) {
            while (i<2000 && missingTable[i]>1) {
                dend = i;
                i++;
            }
            if (i == 2000) {
                out.write("" + (dstart-1000) + "-999+");
                break;
            }
            if (dstart < dend) {
                out.write("" + (dstart-1000) + "-" + (dend-1000) + ", ");
            }
            else {
                out.write("" + (dstart-1000) + ", ");
            }
            while (i<2000 && missingTable[i]<=1) {
                i++;
            }
            if (i == 2000) {
                break;
            }
            dstart = i;
        }
%>
        <hr/>EXAMPLE PATHS<br/><%
        for (String ePath : examplePaths) {
            %><form action="newsMatchAction.jsp">
              <input type="hidden" name="artno" value="<%=artnoInt%>"/>
              <input type="submit" name="p" value="<% HTMLWriter.writeHtml(out, ePath); %>"/>
              <input type="hidden" name="cmd" value="Use This Path"/>
              </form><br/><%

        }

    }


%>

<hr/>
<h3>Pos Pat</h3>
<ul>
<%
    Vector<String> allTags2 = new Vector<String>();
    if (npatt.hasTemplate()) {
        for (PosPat ppp : npatt.getPosPatList()) {
            String ppp_patt = ppp.getPattern();
            %><li><% HTMLWriter.writeHtml(out, ppp.getSymbol());
            List<NewsBunch>  matches = NewsGroup.findBunchesWithPattern(ppp_patt);
            %> (found <%= matches.size() %> bunches with '<%
            HTMLWriter.writeHtml(out, ppp_patt);
            %>') </li>
            <%
            allTags2.addAll(ppp.getTags());
        }
    }

%>
</ul>
<h3><b>Tags</b></h3>
<ul>
<%

    for (String aTag : allTags2) {
        %><li><% HTMLWriter.writeHtml(out, aTag); %></li>
        <%
    }

%>

</ul>
</body>
</html>
<%!

public Vector<String> parseTags(String firstPart) throws Exception {

    Vector<String> res = new Vector<String>();
    if (firstPart==null || firstPart.length()==0) {
        return res;
    }
    int startPos = 0;
    int slashPos = firstPart.lastIndexOf("/");
    if (slashPos>0) {
        firstPart = firstPart.substring(0, slashPos);
    }
    firstPart = firstPart.replaceAll(":", ".");
    firstPart = firstPart.replaceAll("/", ".");
    int dotPos = firstPart.indexOf(".");
    while (dotPos>=startPos) {
        if (dotPos>startPos) {
            res.add(firstPart.substring(startPos,dotPos));
        }
        startPos = dotPos+1;
        dotPos = firstPart.indexOf(".", startPos);
    }
    if (startPos<firstPart.length()) {
        res.add(firstPart.substring(startPos));
    }
    return res;
}

%>




