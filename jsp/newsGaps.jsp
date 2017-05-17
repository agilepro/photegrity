<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsBunch"
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


%>
<html>
<head>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls.min.js"></script>
    <link href="photoStyle.css" rel="stylesheet">
</head>
<body>
<h3><a href="news.jsp">News</a> Gaps <a href="main.jsp"><img src="home.gif" border="0"></a></h3>

<table><tr><form action="newsGaps.jsp">
<td>begin: <input type="text" name="begin" value="<%=begin%>"></td>
<td>highest: <input type="text" name="highest" value="<%=highest%>"></td>
<td><%=highest-begin%></td>
</tr><tr>
<td>limit: <input type="text" name="limit" value="<%=limit%>"></td>
<td>thresh: <input type="text" name="thresh" value="<%=thresh%>"></td>
</tr><tr>
<td>step: <input type="text" name="step" value="<%=step%>"></td>
<td><input type="submit" value="Search"></td>
</tr></table>

<ul>
<%

    if (pos<begin) {
        pos = begin;
    }
    %><li>Starting at <%=pos%></li><%
    long gapStart = 0;
    long fetchStart = 0;
    boolean inGap = false;
    long totalFetched = 0;
    long totalGap = 0;
    long stepSize = step;


    while (limit>0 && pos<highest) {

        boolean avail = newsGroup.hasArticle(pos);
        if (avail && inGap) {

            long gapSize = pos-gapStart;
            totalGap += gapSize;
            if (gapSize > thresh) {

                long steps = gapSize/stepSize - 1;
                long remainder = gapSize - (steps*stepSize);
                long start = gapStart + remainder/2;

                %><li>Gap <%= (gapSize) %>
                <a href="newsFetch.jsp?start=<%=start%>&step=<%=stepSize%>&count=<%=steps%>&command=Refetch">
                Refetch from <%=gapStart%> to <%=pos%>  in <%=steps%> steps</a></li><%
                limit--;
            }
            fetchStart = pos;
            inGap = false;

        }
        else if (!avail && !inGap) {

            totalFetched += pos-fetchStart;
            inGap = true;
            gapStart = pos;

        }
        if (avail) {
            %><li><%=pos%></li><%
        }

        if (pos>= newsGroup.lastArticle) {
            %><li>Last article in NewsGroup object: <%=newsGroup.lastArticle%></li><%
            break;
        }

        pos++;

    }
    if (limit>0 && inGap) {

        long gapSize = highest-gapStart;
        totalGap += gapSize;
        if (gapSize > thresh) { 

            long steps = gapSize/stepSize - 1;
            long remainder = gapSize - (steps*stepSize);
            long start = gapStart + remainder/2;

            %><li>Gap <%= (gapSize) %>
            <a href="newsFetch.jsp?start=<%=start%>&step=<%=stepSize%>&count=<%=steps%>&command=Refetch">
            Refetch from <%=gapStart%> to <%=highest%>  in <%=steps%> steps</a></li><%
            limit--;
        }
    }

    if (limit>0) {
        %><li>That is all up to <%=pos%></li><%
    }
    else {
        %><li>STOPPED SHORT by limit at <%=pos%></li><%
    }
%>

<hr/>

    <li>ENTIRE RANGE at <%= (stepSize) %>
    <a href="newsFetch.jsp?start=<%=begin%>&step=<%=stepSize%>&count=<%=entireRange%>&command=Refetch">
    Refetch from <%=begin%> to <%=(begin + (stepSize*entireRange))%>  in <%=entireRange%> steps of <%=stepSize%> size each</a></li>
</ul>
<hr/>

<hr/>
Total Fetched <%=totalFetched%> - Total Gap <%=totalGap%>  - Percent read <%= (totalFetched*10)/(totalFetched+totalGap+1) %>%
</body>
</html>


