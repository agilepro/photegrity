<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
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


    String artno     = UtilityMethods.reqParam(request, "News Match Action", "artno");
    String cmd       = UtilityMethods.reqParam(request, "News Match Action", "cmd");
    String go        = UtilityMethods.defParam(request, "go", "newsMatch.jsp?artno="+artno);

    long artnoLong = Long.parseLong(artno);
    NewsArticle art = (NewsArticle) newsGroup.getArticleOrNull(artnoLong);

    if (art==null) {
        throw new Exception("newsOneAction can't find the article ("+artno+")?  Or somthing else is wrong.");
    }

    NewsBunch npatt = newsGroup.getBunch(art.getDigest(), art.getHeaderFrom());

    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector<String>();
        session.setAttribute("destVec", destVec);
    }

    if ("Use This Path".equals(cmd)) {
        String dest = UtilityMethods.reqParam(request, "News Match Action", "p");
        npatt.changeFolder(dest, true);
        int destSize = destVec.size();
        for (int i=0; i<destSize; i++) {
            if (dest.equalsIgnoreCase(destVec.get(i))) {
                destVec.remove(i);
                break;
            }
        }
        destVec.insertElementAt(dest, 0);
    }
    else if ("Set Tags".equals(cmd)) {
        String extraTags = UtilityMethods.defParam(request, "extraTags", "");
        npatt.extraTags = extraTags;
    }
    else if ("Set Ignore".equals(cmd)) {
        String ignoreTags = UtilityMethods.defParam(request, "ignoreTags", "");
        session.setAttribute("ignoreTags", ignoreTags);
    }

    response.sendRedirect(go);%>
