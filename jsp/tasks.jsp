<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.Stats"
%><%@page import="bogus.UtilityMethods"
%><%@page import="org.workcast.streams.CSVHelper"
%><%@page import="java.io.File"
%><%@page import="java.io.Reader"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.InputStreamReader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="java.util.Stack"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "stats.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

%>

<html>
<head>
    <link href="lib/bootstrap.min.css" rel="stylesheet">
    <script src="lib/angular.js"></script>
    <script src="lib/ui-bootstrap-tpls.min.js"></script>
    <link href="photoStyle.css" rel="stylesheet">
</head>
<body>

<h3>Current Tasks <%=NewsAction.getActionCount()%></h3>

<table>
<%

out.flush();
int count = 0;
for (NewsAction na : NewsAction.getAllActions()) {
    count++;
    out.write("\n<tr><td>");
    out.write(Integer.toString(count));
    out.write("</td><td>");
    out.write(na.getStatusViewTimed());
    out.write("</td></tr>");
}


%>
</table>

</body>
</html>


