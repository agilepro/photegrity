<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounterIgnoreCase"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.LocalMapping"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
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
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
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
    String selPatt = UtilityMethods.reqParam(request, "News Files Listing", "selPatt");
    String thisPage = "newsFilePatt.jsp?d="+URLEncoder.encode(dig,"UTF-8")+"&f="+URLEncoder.encode(f,"UTF-8")+"&selPatt="+URLEncoder.encode(selPatt,"UTF-8");

    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig, f);

    boolean hasData = bunch.hasTemplate();

    List<NewsFile> files = new Vector<NewsFile>();

    long minArtNo = 999999999L;
    long maxArtNo = 0;

    if (hasData) {
        List<NewsFile> files2 = bunch.getFiles();
        for (NewsFile nff : files2) {
            if (selPatt.equalsIgnoreCase(nff.getPattern())) {
                files.add(nff);
                for (NewsArticle na : nff.getArticles()) {
                    if (na.articleNo<minArtNo) {
                        minArtNo = na.articleNo;
                    }
                    if (na.articleNo>maxArtNo) {
                        maxArtNo = na.articleNo;
                    }
                }
            }
        }
    }
    else {
        //create an empty vector
    }

//figure out if there is a mapping or not
    PosPat tempPP = bunch.getPosPat(selPatt);
    LocalMapping map = LocalMapping.getMapping(tempPP);
    boolean isMapped = (map!=null && map.enabled);
    PosPat  permPP = tempPP;
    if (map!=null) {
        permPP = map.dest;
    }

    DiskMgr tempDiskMgr = tempPP.getDiskMgr();
    DiskMgr permDiskMgr = permPP.getDiskMgr();

    File tempFolder = tempPP.getFolderPath();
    File permFolder = permPP.getFolderPath();
    if (!permFolder.exists()) {
        permFolder.mkdirs();
    }

    File   displayFolder = permPP.getFolderPath();
    String displayPatt   = permPP.getPattern();

    File[] tempChildren = tempFolder.listFiles();
    File[] permChildren = permFolder.listFiles();
    if (tempChildren==null) {
        tempChildren = new File[0];
    }
    if (permChildren==null) {
        permChildren = new File[0];
    }

    String tempRelPath = tempPP.getLocalPath();
    String permRelPath = permPP.getLocalPath();


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
    ImageInfo.parsePathTags(tagCache, displayFolder.toString());

    String mapSymbol = permPP.getSymbol();
    int slashPos = mapSymbol.lastIndexOf("/")+1;
    String mapPos = mapSymbol.substring(0,slashPos);
    String mapPatt = mapSymbol.substring(slashPos);

%>
<html>
<body>
<h3>News Files Listing  <%=queueMsg%></h3>
<p><a href="news.jsp?<%=startPart%>">News</a>
 | <a href="newsFiles.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Files</a>
 | <a href="newsDetail2.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Articles</a>
 | <a href="newsPatterns.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Patterns</a></p>

<table><tr><td>Bunch Subject: </td><td bgcolor="<%=bunch.getStateColor()%>"><%
    HTMLWriter.writeHtml(out, bunch.digest);
%></td></tr></table>
<ul>
    <form action="newsDetailAction.jsp?dig=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>" name="moveForm" method="post">
    <input type="hidden" name="selPatt" value="<%HTMLWriter.writeHtml(out, selPatt);%>">
    <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
    <li>Current: <font color="brown"><%
        HTMLWriter.writeHtml(out, displayFolder.toString());
        HTMLWriter.writeHtml(out, bunch.getTemplate());
        %></font>
    </li>
    <li><input type="submit" name="cmd" value="Download All Patt">
        <input type="submit" name="cmd" value="Download Available Patt"></li>
    <li>
    Local Temp Loc: <a href="showpp.jsp?symbol=<% UtilityMethods.writeURLEncoded(out, tempPP.getSymbol()); %>">
        <% HTMLWriter.writeHtml(out, tempPP.getSymbol()); %></a>
    -

    <a href="pattern.jsp?g=<% UtilityMethods.writeURLEncoded(out, selPatt); %>&o=name&min=0&showBunches=yes">Bunches</a>
    </li>
    <li>
    <% if (map==null) { %>
    No mapping exists

    <% } else if(!map.enabled) { %>
    Mapped: <a href="showpp.jsp?symbol=<% UtilityMethods.writeURLEncoded(out, permPP.getSymbol()); %>">
        <% HTMLWriter.writeHtml(out, permPP.getSymbol()); %></a> but NOT enabled

    <% } else { %>
    Mapped to <a href="showpp.jsp?symbol=<% UtilityMethods.writeURLEncoded(out, permPP.getSymbol()); %>">
        <% HTMLWriter.writeHtml(out, permPP.getSymbol()); %></a>   <b><font color="red">ENABLED</font></b>

    <% } %>
    </li>
    <li>
    Map to: <input type="text" name="mapPos" value="<% HTMLWriter.writeHtml(out, mapPos); %>" size="50">
      <input type="text" name="mapPatt" value="<% HTMLWriter.writeHtml(out, mapPatt); %>" size="20">
    <% if (!isMapped) {%><input type="submit" name="cmd" value="Set Mapping"><% } %>
    <% if (!isMapped) {%><input type="submit" name="cmd" value="Enable Mapping"><% } %>
    <% if (isMapped) {%><input type="submit" name="cmd" value="Disable Mapping"><% } %>
    <% if (isMapped) {%><input type="submit" name="cmd" value="Revert Files"><% } %>
    </li>
    </form>


    <li> Pattern:  <%
    out.write("<a href=\"pattern2.jsp?g="+URLEncoder.encode(selPatt,"UTF-8")+"\">");
    HTMLWriter.writeHtml(out, selPatt);
    out.write("</a>, ");
    out.write("<a href=\"pattern2.jsp?g="+URLEncoder.encode(permPP.getPattern(),"UTF-8")+"\">");
    HTMLWriter.writeHtml(out, permPP.getPattern());
    out.write("</a>, ");
    out.write("Tags: ");
    StringBuffer tagsWithCommas = new StringBuffer();
    StringBuffer tagsWithPlus = new StringBuffer();
    boolean needComma = false;
    for (String tagName : tagCache.sortedKeys()) {
        if (needComma) {
            tagsWithCommas.append(',');
            tagsWithPlus.append("+");
        }
        needComma = true;
        tagsWithCommas.append(tagName);
        tagsWithPlus.append(tagName);
        out.write("<a href=\"taglist.jsp?t="+URLEncoder.encode(tagName,"UTF-8")+"\">");
        HTMLWriter.writeHtml(out, tagName);
        out.write("</a>, ");
    }
    out.write("<a href=\"taglist.jsp?t="+URLEncoder.encode(tagsWithCommas.toString(),"UTF-8")+"\">");
    HTMLWriter.writeHtml(out, tagsWithPlus.toString());
    out.write("</a>, ");
    %></li>
</ul>
<table>

<%
    int pCount = 0;
    int count = 0;
    String lastFNPatt = "";
    int lastFNNum = 0;
    if (!hasData) {
        %><font color="red"><b>- - - no data to show: needs the template to be set - - - </b></font><%
    }
    else for (NewsFile nf : files)
    {
        String tempFileName = nf.getFileName();
        String permFileName = permPP.translateFileName(tempFileName);

        File tempFullPath = new File(tempFolder, tempFileName);
        File permFullPath = new File(permFolder, permFileName);

        File tempActualFile = NewsFile.isInList(tempFileName, tempChildren);
        File permActualFile = NewsFile.isInList(permFileName, permChildren);

        if (tempActualFile!=null) {
            tempFileName = tempActualFile.getName();
        }
        if (permActualFile!=null) {
            permFileName = permActualFile.getName();
        }

        String bestName = permFileName;

        int fnNum = nf.getSequenceNumber();
        String fnPatt = nf.getPattern();
        boolean skippedSomething = (!fnPatt.equalsIgnoreCase(lastFNPatt) || lastFNNum+1 != fnNum );
        lastFNPatt = fnPatt;
        lastFNNum = fnNum;

        File filePath = nf.getFilePath();

        String downURL = "newsDetailAction.jsp?fileName="+URLEncoder.encode(tempFileName,"UTF-8")
              +"&go="+URLEncoder.encode(thisPage,"UTF-8")
              +"&cmd=GetFile&dig="+URLEncoder.encode(dig,"UTF-8");
        boolean downloading = nf.isMarkedDownloading();

        boolean needSave = permFolder.exists() && permActualFile==null;
        if (skippedSomething) {
            %><tr><td></td><td><hr/></td></tr><%
        }
%>
<tr>
<td><a href="newsFileDelete.jsp?fn=<%=URLEncoder.encode(tempFileName,"UTF-8")%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>&dig=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>"><img src="trash.gif"></a> </td>
<td><% HTMLWriter.writeHtml(out, tempFileName); %> &nbsp; </td>
<td><% if (tempActualFile!=null) {
        %><a href="/photo/photo/<%HTMLWriter.writeHtml(out,tempDiskMgr.diskName);%>/<%HTMLWriter.writeHtml(out,tempRelPath);%><%HTMLWriter.writeHtml(out,tempFileName);%>"
            target="photo"  title="<%HTMLWriter.writeHtml(out,tempFullPath.toString());%>"><img src="fileExists.png"></a><%
       } %>
<td><% HTMLWriter.writeHtml(out, permFileName); %> &nbsp; </td>
<td> <%
    if (needSave) {
        %><a href="<%=downURL%>">save</a><%
    }
    %></td><td><%

    Exception em = nf.getFailMsg();
    if (downloading) {
        %><a href="<%=downURL%>"><img src="downloading.png"></a><%
    } else if (permActualFile!=null) {
        %><a href="/photo/photo/<%HTMLWriter.writeHtml(out,permDiskMgr.diskName);%>/<%HTMLWriter.writeHtml(out,permRelPath);%><%HTMLWriter.writeHtml(out,permFileName);%>"
            target="photo"  title="<%HTMLWriter.writeHtml(out,permFullPath.toString());%>"><img src="fileExists.png"></a><%
    } else if (em!=null) {
        %>ERROR<%
    } else if (nf.isComplete()) {
        %>complete<%
    } else {
        pCount++;
        %>PARTIAL<%
    } %></td>
<td> <%
    if (permActualFile!=null) {
        if (permActualFile.length()>225000) {
        %><font color="red"><%= permActualFile.length() %></font><%
        }
        else {
        %><%= permActualFile.length() %><%
        }
    }
    else {
        %><%= nf.partsAvailable() %> / <%= nf.partsExpected() %><%
    } %>
</td>
<td> &nbsp; |
    <a href="debugFile.jsp?artno=<%=nf.getSampleArticleNum()%>"><img src="debug-icon.png" title="Debug this file object"></a>
    <a href="newsMapMatch.jsp?artno=<%=nf.getSampleArticleNum()%>">Match</a>
</td>
</tr>
<%      if (em!=null) { %>
            <tr><td colspan="10"> &nbsp; &nbsp; &nbsp;
                <font color="darkpink"><% HTMLWriter.writeHtml(out,em.toString());%>
                </font>
            </td>
            </tr>
<%      }

        count++;
    }

%>
</table>
<table>
<tr>
<td>Displayed <%=count%> files, <%=pCount%> of them partially complete.   Seek extent = <%=bunch.seekExtent%></td>
<td>
    <form action="newsDetailAction.jsp?dig=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>" name="moveForm2" method="post">
        <input type="hidden" name="go" value="<%=thisPage%>">
        <input type="submit" name="cmd" value="DoubleExtent">
    </form>
</td>
</tr>
<tr>
<td>min <%=minArtNo%>, max <%=maxArtNo%>,
<a href="newsFetch.jsp?start=<%=minArtNo%>&step=1&count=<%=(maxArtNo-minArtNo)%>&command=Refetch">
Fetch <%=(maxArtNo-minArtNo)%> Interior Articles</a>
<a href="newsFetch.jsp?start=<%=minArtNo%>&step=1&count=<%=(maxArtNo-minArtNo)%>&command=UnError">(ERR)</a>
<a href="newsFetch.jsp?start=<%=minArtNo-200%>&step=1&count=200&command=Refetch">Fetch 200 earlier Articles</a>
<a href="newsFetch.jsp?start=<%=maxArtNo%>&step=1&count=200&command=Refetch">Fetch 200 later Articles</a>
</body>


<script>
    window.setTimeout(function(){window.location="<%=thisPage%>";},60000);
</script>

</html>

