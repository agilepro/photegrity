<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }


    NewsGroup nGroup = NewsGroup.getCurrentGroup();
    NewsSession ns = nGroup.session;

%>
<html>
<body>
<h3>News Browser</h3>

<hr/>

<p> Getting Group:
<% if (nGroup!=null) { %>
Got <%=nGroup.groupName%>
<% } else { %>
Failed
<% return;
   } %>
</p>

<p> first article: <%= nGroup.firstArticle %> </p>
<p> last article: <%= nGroup.lastArticle %> </p>
<p> article count: <%= nGroup.articleCount  %> </p>


<%
    int i=10;
    long lastArticle = nGroup.lastArticle+1;
    while (--i > 0)
    {
%>
<hr/>
<%
        lastArticle--;
        ArticlePointer pointer = new ArticlePointer();
        NewsArticle art = nGroup.getArticleOrNull(lastArticle);
        if (art==null)
        {
            %><p>Unable to select article <%=lastArticle%></p>
            <%
            continue;
        }
%>


<ul><li>article number: <%= art.getNumber()  %> </li>
<li> Subject: <% HTMLWriter.writeHtml(out, art.getHeaderSubject()); %> </li>
<li> From: <% HTMLWriter.writeHtml(out, art.getHeaderFrom()); %> </li>
<li> Date: <% HTMLWriter.writeHtml(out, art.getHeaderDate()); %> </li></ul>
<hr/>
<%
    }
%>
<p>disconnecting.</p>
<%   ns.disconnect();  %>
<p>That is all!</p>
</body>
</html>

