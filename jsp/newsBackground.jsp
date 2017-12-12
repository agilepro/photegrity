<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.PrintWriter"
%><%@page import="java.io.Reader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
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

    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsSession newsSession = null;

    if (newsGroup==null)
    {
        throw new Exception("news does not seem to be initialized");
    }

%>
<html>
<body>
<h3>News Background Processing,   <a href="news.jsp" target="_blank">News Page</a></h3>

<%
    NewsAction.markForThisThread();
    out.flush();
    int limit = 150;
    while (limit> 0 && NewsAction.isMarkedForThisThread()) {

        limit--;
        NewsAction act = NewsAction.pullFromQueueOrNull();
        if (act==null) {
            if (newsSession!=null) {
                out.write("\n<br/>Waiting...");
                out.flush();
                newsSession.disconnect();
                newsSession=null;
            }
            Thread.sleep(1000);
            continue;
        }

        limit -= 9;
        try {
            if (newsSession==null) {
                out.write("\n<br/>Starting up...");
                out.flush();
                newsSession = newsGroup.session;
                newsSession.connect();
            }
            act.perform(out, newsSession);
        }
        catch (Exception e) {
            newsSession=null;
            String msg = e.toString();
%>
<hr/>
<p><b>Error: <% HTMLWriter.writeHtml(out,msg); %></b></p>
<pre>
<% out.flush(); %>
<% e.printStackTrace(new PrintWriter(out)); %>
</pre>
<hr/>
<%
            if (msg.contains("Unable to authenticate")) {
                out.write("\nSleeping 60 seconds...<br/>");
                out.flush();
                //sleep for 60 seconds when getting the unauthenticate problem
                Thread.sleep(60000);
            }
        }
        out.flush();
        if (!NewsAction.isMarkedForThisThread()) {
            //this prevents the script below from being sent when some
            //other thread has taken over the processing
            %><p><b>Giving up processing to another thread .... Stopping</b></p><%
            out.flush();
            return;
        }
    }

%>
<script>
    window.location = "newsBackground.jsp";
</script>


