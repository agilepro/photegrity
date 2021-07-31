<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.NewsArticle"
%><%@page import="com.purplehillsbooks.photegrity.NewsFile"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.NewsSession"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.text.DecimalFormat"
%><%@page import="java.util.ArrayList"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "newsGroupList.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    NewsSession newsSession = NewsSession.getNewsSession();

    String query = UtilityMethods.defParam(request, "query", "");

    boolean wasConnected = false; //newsSession.isConnected;
%> 
<html>
<body>
<h3>News Gaps <a href="main.jsp"><img src="home.gif" border="0"></a></h3>

<table><tr><form action="newsGroupList.jsp">
<td>query: <input type="text" name="query" value="<% HTMLWriter.writeHtml(out, query); %>"></td>
<td><input type="submit" value="Go"></td>
<td>Use wildcards like '*a*' to find usergroups with 'a' in the name</td>
</form>
</tr></table>
<hr>

<ul>
<%

    if (query.length()>0) {
        if (!wasConnected) {
            newsSession.connect();
        }

        NNTPClient ntc = newsSession.client;
        NewsgroupInfo ngiList[] = ntc.listNewsgroups(query);

        if (ngiList==null) {
            ngiList = new NewsgroupInfo[0];
        }
        Hashtable<String,NewsgroupInfo>  cache = new Hashtable<String,NewsgroupInfo>();
        Vector<String> list = new Vector<String>();
        for (NewsgroupInfo ngi : ngiList) {
            if (ngi.getArticleCount()<100000) {
                continue;
            }
            String name = ngi.getNewsgroup();
            list.add(name);
            cache.put(name, ngi);
        }
        out.write("Got "+list.size()+" records back");
        Collections.sort(list);
        for (String newsName : list) {
            NewsgroupInfo ngi = cache.get(newsName);
            out.write("<li>");
            HTMLWriter.writeHtml(out, ngi.getNewsgroup());
            out.write(" - ");
            DecimalFormat myFormatter = new DecimalFormat("###,###,###.");
            String output = myFormatter.format(ngi.getArticleCount());
            out.write(output);
            out.write(" - ");
            out.write(" - ");
            out.write(" - ");
        }

        if (!wasConnected) {
            newsSession.disconnect();
        }

    }
    else {

        out.write("Got zero records in response");
    }

%>
</ul>
<hr/>
</body>
</html>


