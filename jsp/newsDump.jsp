<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.NewsArticleError"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="java.util.List"
%><%@page import="java.util.Comparator"
%><%@page import="java.util.Collections"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";
    String groupName = "alt.binaries.pictures.erotica.latina";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession newsSession = newsGroup.session;
    groupName = newsGroup.getName();

    List<NewsArticle> articles = newsGroup.getArticles();
    Collections.sort(articles, new authSubComp2());

    long artno = UtilityMethods.defParamLong(request, "artno", newsGroup.firstArticle);

    String highlight = UtilityMethods.defParam(request, "high", "XYZZY");
    String encodedHighlight = URLEncoder.encode(highlight,"UTF-8");


%>
<html>
<head>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls.min.js"></script>
    <link href="photoStyle.css" rel="stylesheet">
    
<script>

function getArticles(start, length) {
    var step = 1;
    if (length>30) {
        step = Math.floor(length/8);
        length = Math.floor(length/step);
    }
    var theUrl = "newsFetch.jsp?start="+start+"&step="+step+"&count="+length+"&command=UnError";
    var xmlHttp = new XMLHttpRequest();
    xmlHttp.open( "GET", theUrl, false ); // false for synchronous request
    xmlHttp.send( null );
    return xmlHttp.responseText;
}

</script>
    
    
    
</head>
<body>
<h3><a href="news.jsp">News</a> Dump - <a href="newsDump.jsp?artno=<%=artno-100%>&high=<%=encodedHighlight%>"><%=artno-100%></a>
 and <a href="newsDump.jsp?artno=<%=artno+100%>&high=<%=encodedHighlight%>"><%=artno+100%></a></h3>

<table>

<%
    int count = 0;
    int limit = 100;
    long position = artno;
    for (NewsArticle art : articles)
    {
        if (art.articleNo < artno) {
            continue;
        }
        if (limit-- < 0) {
            break;
        }
        if (position < art.articleNo) {
            int total = (int) (art.articleNo-position);
            int step = 1;
            if (total>30) {
                step = (int) total/8;
                total = (int) total/step;
            }
            int totalDivTen = total/10;
            int totalDivHundred = total/100;

            %>
            <tr><td style="color:gray;"><%=position%></td>
                <td style="cursor:pointer"><a onclick="getArticles(<%=position%>,<%=total%>)">get</a> <%= art.articleNo-position %></td>
                <%displayError(out,newsGroup,position);%>
                </tr>
        <%
            position++;
        }
        while (position < art.articleNo) {
            %><tr><td style="color:gray;"><%=position%></td><td></td>
            <%displayError(out,newsGroup,position);%>
            </tr><%
            position++;
        }
        position = art.articleNo+1;
        String thisFrom = art.getHeaderFrom();
        String thisSubj = art.getHeaderSubject();
        String thisDig = art.getDigest();
%>
<tr><td><a href="newsOne.jsp?artno=<%=art.getNumber()%>"><%=art.getNumber()%></a> &nbsp; </td>
<td></td>
<td><% writeCareful(out, thisSubj, highlight); %> </td></tr>
<%
    }
%>
</table>
<p>Displayed <%=count%> matching subject lines.</p>
</body>
</html>

<%!

    public void writeCareful(Writer out, String s, String highlight)
        throws Exception
    {
        boolean isHighlight = (s.indexOf(highlight)>=0);
        if (isHighlight) {
            out.write("<span style=\"background-color: yellow;\">");
        }
        //out.write("["+s.length()+"]");
        for (int i=0; i<s.length(); i++)
        {
            char ch = s.charAt(i);
            if (ch == '<')
            {
                out.write("&lt;");
            }
            else if (ch == '>')
            {
                out.write("&gt;");
            }
            else if (ch == '&')
            {
                out.write("&amp;");
            }
            else if (ch == '"')
            {
                out.write("&quot;");
            }
            else if (ch == ' ')
            {
                out.write("_");
            }
            else if (ch == (char)9635)
            {
                out.write(ch);
            }
            else if (ch < ' ' || ch > 127)
            {
                out.write(Integer.toString((int)ch));
            }
            else
            {
                out.write(ch);
            }
        }
        if (isHighlight) {
            out.write("</span>");
        }
    }

    public void displayError(Writer out, NewsGroup ng, long artNo) throws Exception {
        NewsArticleError nae = ng.getError(artNo);
        if (nae==null) {
            out.write("<td style=\"color:red;\">untried</td>");
        }
        else {
            out.write("<td style=\"color:lightblue;\">");
            out.write(nae.status());
            out.write("</td>");
        }
    }


    class authSubComp2 implements Comparator<NewsArticle> {
        public authSubComp2() {

        }

        public int compare(NewsArticle o1, NewsArticle o2) {
            NewsArticle na1 = o1;
            NewsArticle na2 = o2;
            if (o1.articleNo < o2.articleNo) {
                return -1;
            }
            else {
                return 1;
            }
        }
    }


%>

