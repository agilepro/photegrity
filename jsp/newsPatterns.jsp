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
%><%@page import="org.workcast.streams.HTMLWriter"
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
    String thisPage = "newsPatterns.jsp?d="+URLEncoder.encode(dig,"UTF-8")+"&f="+URLEncoder.encode(f,"UTF-8");

    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig, f);

    boolean hasData = bunch.hasTemplate();

    List<NewsFile> files = null;

    if (hasData) {
        files = bunch.getFiles();
    }
    else {
        //create an empty vector
        files = new Vector<NewsFile>();
    }

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
%>
<html>
<body>
<h3>News Files Patterns <%=queueMsg%></h3>
<p><a href="news.jsp?<%=startPart%>">News</a>
 | <a href="newsDetail2.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Articles</a>
 | <a href="newsFiles.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Files</a>
 | <font color="red">Patterns</font></p>

<table><tr><td>Bunch Subject: </td><td bgcolor="<%=bunch.getStateColor()%>"><%
    HTMLWriter.writeHtml(out, bunch.digest);
%></td></tr></table>
<ul>
    <form action="newsDetailAction.jsp?dig=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>" name="moveForm" method="post">
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
    Folder: <input type="text" name="folder" value="<%HTMLWriter.writeHtml(out, folder);%>" size="50">
                    <input type="submit" name="cmd" value="Set And Move Files">
                    <input type="checkbox" name="createIt" value="yes" checked="checked"> Create?
                    <input type="submit" name="cmd" value="Set Without Files">

    </li>
    <li>Template: <input type="text" name="template" value="<%HTMLWriter.writeHtml(out, bunch.getTemplate());%>" size="50">

                <input type="checkbox" name="plusOne" value="true" <% if (bunch.plusOneNumber) {%>checked="checked"<%}%>> Plus One
                <br/>
                <input type="submit" name="cmd" value="GetPatt"> |
                <input type="submit" name="cmd" value="SetPattern">
                <input type="submit" name="cmd" value="Cover">
                <input type="submit" name="cmd" value="Flogo">
                <input type="submit" name="cmd" value="Sample">
                <input type="submit" name="cmd" value="SetIndex">
                <input type="submit" name="cmd" value="SetOneIndex">
                AutoPath: <input type="checkbox" name="autopath" value="true" checked="checked">
                Zing: <%HTMLWriter.writeHtml(out, zingpat);%>
                <%
                if (bunch.isYEnc) {
                    %> - (yEnc)<%
                } else {
                    %> - (NOT yEnc)<%
                }
                %><button type="submit" name="cmd" value="YEnc">change</button>
                </li>
    <hr/>
    <%
        if (bunch.pState==NewsBunch.STATE_ERROR) {
            out.write("<li>Error: <font color=\"deeppink\">"+bunch.failureMessage.toString()+"</font></li>");
        }
    %>
    <input type="hidden" name="go" value="<%=thisPage%>">
    <input type="submit" name="cmd" value="Delete All & Hide">
    <%
        if (bunch.pState == NewsBunch.STATE_INITIAL) {
    %><input type="submit" name="cmd" value="Mark Interested"><%

    %><input type="submit" name="cmd" value="Seek Bunch"><%

    %><input type="submit" name="cmd" value="Download All"><%

    %><input type="submit" name="cmd" value="Mark Complete"><%
        }
        else if (bunch.pState == NewsBunch.STATE_INTEREST || bunch.pState == NewsBunch.STATE_ERROR) {
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
                %><input type="submit" name="cmd" value="Mark Complete"><%
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
                %><input type="submit" name="cmd" value="Mark Complete"><%
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
    }
    if (bunch.shrinkFiles) {
        %><input type="submit" name="cmd" value="Don't Shrink"><%
    }
    else {
        %><input type="submit" name="cmd" value="Do Shrink"><%
    }
    %></form>
    </ul>
    <table>
    <tr></td>Pattern</td></tr>
    <%
    Vector<PosPat> bunchPosPats = bunch.getPosPatList();
    PosPat.sortByPattern(bunchPosPats);
    for (PosPat ppp : bunchPosPats) {
        String ppp_patt = ppp.getPattern();
        out.write("<tr><td><a href=\"pattern2.jsp?g="+URLEncoder.encode(ppp_patt,"UTF-8")+"\">");
        HTMLWriter.writeHtml(out, ppp_patt);
        out.write("</a></td><td><A href=\"pattern.jsp?g="+URLEncoder.encode(ppp_patt,"UTF-8"));
        out.write("&showBunches=yes\">Bunches</a></td><td>");
        PosPat pp = bunch.getPosPat(ppp_patt);
        LocalMapping map = LocalMapping.getMapping(pp);
        boolean jaMap = (map!=null && map.enabled);
        if (jaMap) {
            %><a href="newsFilePatt.jsp?d=<%=UtilityMethods.URLEncode(dig)
            %>&f=<%=UtilityMethods.URLEncode(f)%>&selPatt=<%=UtilityMethods.URLEncode(ppp_patt)
            %>"><img src="fileMapped.png"></a></td>
            <td><%
            HTMLWriter.writeHtml(out, map.dest.getSymbol());
        } else {
            %><a href="newsFilePatt.jsp?d=<%=UtilityMethods.URLEncode(dig)
            %>&f=<%=UtilityMethods.URLEncode(f)%>&selPatt=<%=UtilityMethods.URLEncode(ppp_patt)
            %>"><img src="fileUnmapped.png"></a><%
        }
        out.write("</td></tr>");
    }
    %>
    <form action="taglist.jsp" method="get">
    <li>
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

    </li>
    </form>
</ul>



<script>
    window.setTimeout(function(){window.location="<%=thisPage%>";},60000);
</script>

</body>
</html>

