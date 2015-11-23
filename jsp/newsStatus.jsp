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
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();

    int start = UtilityMethods.defParamInt(request, "start", 0);
    int next = start + 20;
    int prev = start - 20;
    if (prev<0) {
        prev = 0;
    }
    String hide = UtilityMethods.defParam(request, "hide", "y");
    boolean isHidden = "y".equals(hide);
    String hidePart = "";
    List<NewsBunch> allPatts;
    if (isHidden) {
        allPatts = NewsGroup.getUnhiddenBunches();
    }
    else {
        hidePart = "&hide=n";
        allPatts = NewsGroup.getAllBunches();
    }
    String sort = UtilityMethods.defParam(request, "sort", "patt");
    String sortPart = "";
    boolean showID = false;
    if ("id".equals(sort)) {
        NewsBunch.sortByArticleId(allPatts);
        sortPart = "&sort=id";
        showID = true;
    } else if ("count".equals(sort)) {
        NewsBunch.sortByCount(allPatts);
        sortPart = "&sort=count";
    } else {
        NewsBunch.sortByPattern(allPatts);
    }
    String filter = (String) session.getAttribute("filter");




</body>
</html>