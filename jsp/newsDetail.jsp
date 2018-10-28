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
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");

    if (true) {
        throw new Exception("deprecated page: newsDetail..jsp");
    }
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";
    String groupName = "alt.binaries.pictures.erotica.latina";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    groupName = newsGroup.getName();


    String dig = UtilityMethods.reqParam(request, "News Details Page", "d");
    String f   = UtilityMethods.reqParam(request, "News Details Page", "f");
    String sort= UtilityMethods.defParam(request, "sort", "dig");
    String start= UtilityMethods.defParam(request, "start", "0");
    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");

    String thisPage = "newsDetail2.jsp?"+startPart+"&d="+URLEncoder.encode(dig,"UTF-8")+"&f="+URLEncoder.encode(f,"UTF-8");

    NewsBunch bunch = newsGroup.getBunch(dig, f);
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
    String fromUser = firstArticle.getHeaderFrom();

%>
<html>
<body>
<h3>News Articles Details  <%=queueMsg%> <a href="newsDetail2.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>">#2</a></h3>
<p><a href="news.jsp?<%=startPart%>">News</a>
   | <font color="red">Articles</font>
   | <a href="newsFiles.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Files</a>
   | <a href="newsPatterns.jsp?d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">Patterns</a>
   | <a href="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>&sort=num">Sort_by_Number</a>
   | <a href="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>&sort=dig">Sort_by_Subject</a></p>

<table><tr><td>Pattern: </td><td bgcolor="<%=bunch.getStateColor()%>"><%
    HTMLWriter.writeHtml(out, tokenFill(bunch.digest));
%></td></tr></table>
<ul>
    <form action="newsDetailAction.jsp?dig=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>"  name="moveForm" method="post">
    <li>From: <%
        HTMLWriter.writeHtml(out, fromUser);
    %></li>
    <li>Current: <font color="brown"><%
        HTMLWriter.writeHtml(out, folder);
        HTMLWriter.writeHtml(out, bunch.getTemplate());
            if (!folderExists) {
                out.write("<input type=\"submit\" name=\"cmd\" value=\"Create Folder\"/>");
            }
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
    <input type="hidden" name="go" value="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig, "UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>">
    <input type="hidden" name="start" value="<%=start%>">
    <input type="submit" name="cmd" value="Hide">
    <input type="checkbox" name="delAll" value="delAll"> Delete All
    <%
        if (bunch.pState == NewsBunch.STATE_INITIAL) {
    %><input type="submit" name="cmd" value="Get A Bit"><%

    %><input type="submit" name="cmd" value="Mark Interested"><%

    %><input type="submit" name="cmd" value="Seek Bunch"><%

    %><input type="submit" name="cmd" value="Download All"><%

    %><input type="submit" name="cmd" value="Mark Complete"><%
        }
        else if (bunch.pState == NewsBunch.STATE_INTEREST || bunch.pState == NewsBunch.STATE_GETABIT) {
    %><input type="submit" name="cmd" value="Get A Bit"><%

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
    %><input type="submit" name="cmd" value="Get A Bit"><%
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

<%
    int count = 0;
    int pCount = 0;

    for (int i=0; i<articles.size(); i++) {
        NewsArticle art = articles.get(i);
        String thisFrom = art.getHeaderFrom();
        String thisSubj = art.getHeaderSubject();
        String thisDig = art.getDigest();
        File filePath = null;
        if (bunch.hasFolder()) {
            filePath = art.getFilePath();
        }


        if (!dig.equals(thisDig))
        {
            continue;
        }
%>
<tr><td><a href="newsOne.jsp?artno=<%= art.getNumber()  %>"><%= art.getNumber()  %></a> &nbsp; </td>
<%
        int j = 0;
        String val = art.getParam(j);
        while (val!=null) {
            out.write("<td align=\"right\">");
            HTMLWriter.writeHtml(out, val);
            out.write(" - </td>");
            val = art.getParam(++j);
        }
%>
<td><%
        if (art.isDownloading) {
            HTMLWriter.writeHtml(out, thisSubj);
            %> </td><td><img src="downloading.png"><%
        }
        else if (art.canServeContent()) {
            out.write("<a href=\"newsPict.jsp?artno="+(art.getNumber())+"\"  target=\"photo\">");
            HTMLWriter.writeHtml(out, thisSubj);
            out.write("</a>");
            %> </td><td><%
        }
        else {
            HTMLWriter.writeHtml(out, thisSubj);
            %> </td><td> <a href="newsOneAction.jsp?artno=<%=art.getNumber()%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">load</a><%
        }
        %></td><td><%
        HTMLWriter.writeHtml(out, art.getFileName());
        //if (art.getFileName().length()>0) {
            %>  <a href="newsMatch.jsp?artno=<%=art.getNumber()%>">Match</a>
            <%
        //}
        if (filePath!=null && filePath.exists()) {
            DiskMgr dm = DiskMgr.findDiskMgrFromPath(filePath);
            String localPath = dm.getOldRelativePathWithoutSlash(filePath);

            %><a href="/photo/photo/<%HTMLWriter.writeHtml(out,dm.diskName);%>/<%HTMLWriter.writeHtml(out,localPath);%>"
               target="photo"  title="<%HTMLWriter.writeHtml(out,filePath.toString());%>"><img src="fileExists.png"></a><%
        }
        %></td></tr><%
        count++;
        if (count>1000) {
            break;
        }
    }

%>
</table>
<p>Displayed <%=count%> subject lines, <%=pCount%> of them partially complete.</p>
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
    window.setTimeout(function(){window.location="newsDetail2.jsp?<%=startPart%>&d=<%=URLEncoder.encode(dig,"UTF-8")%>&f=<%=URLEncoder.encode(f, "UTF-8")%>&sort=<%=sort%>";},60000);
</script>

</html>
