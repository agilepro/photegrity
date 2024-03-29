<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.NewsFile"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.PosPat"
%><%@page import="com.purplehillsbooks.photegrity.UUDecoderStream"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
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
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.streams.MemFile"
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
    String expectedDigest = art.getDigest();
    NewsBunch npatt = newsGroup.getBunch(expectedDigest, art.getHeaderFrom());
    NewsFile nf = npatt.getFileForArticle(art);

    String thisUrl = "debugFile.jsp?artno="+artnoInt;

    String headerSubj = art.getHeaderSubject();
    String encodedHeaderSubj = URLEncoder.encode(headerSubj.substring(0,8),"UTF-8");

    //NewsArticle sampleArticle = nf.

%>
<html>
<body>
<h3>Debug NewsFile</h3>

<style>
.spacey tr td {
    padding:3px;
}
</style>

<table>

<tr><td>FileName: </td><td><b><%HTMLWriter.writeHtml(out, nf.getFileName() ); %></b></td></tr>
<tr><td>Pattern: </td><td><b><%HTMLWriter.writeHtml(out, nf.getPattern() ); %></b></td></tr>
<tr><td>Number: </td><td><b><%HTMLWriter.writeHtml(out, Integer.toString(nf.getSequenceNumber()) ); %></b></td></tr>
<tr><td>PosPat: </td><td><b><%HTMLWriter.writeHtml(out, nf.getPosPat().getSymbol() ); %></b></td></tr>
<tr><td>Expected#: </td><td><b><%HTMLWriter.writeHtml(out, Integer.toString(nf.partsExpected()) ); %></b></td></tr>
<tr><td>Available#: </td><td><b><%HTMLWriter.writeHtml(out, Integer.toString(nf.partsAvailable()) ); %></b></td></tr>
<tr><td>Complete: </td><td><b><%if (nf.isComplete()) {%>complete<%}else{%>NOT complete<%}%></b></td></tr>
<tr><td>Downloaded: </td><td><b><%if (nf.isDownloaded()) {%>Downloaded<%}else{%>NOT Downloaded<%}%></b></td></tr>
<tr><td>Marked: </td><td><b><%if (nf.isMarkedDownloading()) {%>Marked for download<%}else{%>NOT Marked for download<%}%></b></td></tr>
<tr><td>Fail: </td><td><b><%if (nf.getFailMsg()!=null) {HTMLWriter.writeHtml(out, nf.getFailMsg().toString() );} %></b></td></tr>
<tr><td>Mapped: </td><td><b><%if (nf.isMapped()) {%>Mapped<%}else{%>NOT Mapped<%}%></b></td></tr>
<tr><td>Bunch Numerator: </td><td><b><%=npatt.numerator%></b></td></tr>

</table>

<table class="spacey">
<%
    int count = 0;
    for (NewsArticle nart: nf.getArticles()) {

        %><tr><td>Art <%=count++%></td>
            <td><a href="newsOne.jsp?artno=<%=nart.getNumber()%>"><%=nart.getNumber()%></a></td>
            <td><a href="newsDump.jsp?artno=<%=nart.getNumber()%>&high=<%=encodedHeaderSubj%>">Dump</a></td>
            <td><%=nart.getMultiFileNumerator()%></td>
            <td><%=nart.getMultiFileDenominator()%></td>
            <td><% if (nart.canServeContent()) { %>[Downloaded]<% } else { %>[Empty]<% } %></td>
            <td><%HTMLWriter.writeHtml(out, nart.getHeaderSubject() ); %></td>
            </tr><%
            
            if (nart.headersChanged) {
                %>
                <tr><td colspan="8"><pre>
                    <%nart.getJSON().write(out,2,2);%>
                </pre></td></tr>
                <%
            }
    }

%>

</body>
</html>




