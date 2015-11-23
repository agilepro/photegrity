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
<style>
table
{
    table-layout:fixed;
    text-align:right;
    font:12px arial,sans-serif;
}
td
{
    padding:5;
}
</style>
<body>

<h3>Statistics</h3>

<table>
<%
long tRaw = 0;
long tFin = 0;
long tDur = 0;
long tFileCount = 0;
Vector<File> newsFileList = DiskMgr.getNewsFiles();
for (File newsFile : newsFileList)  {
    File folder = newsFile.getParentFile();
    for (File child : folder.listFiles()) {
        if (child.getName().endsWith(".stats")) {
            long newRaw = 0;
            long newFin = 0;
            long newDur = 0;
            long newFileCount = 0;
            FileInputStream fis = new FileInputStream(child);
            Reader content = new InputStreamReader(fis, "UTF-8");
            List<String> vals = CSVHelper.parseLine(content);
            while (vals!=null) {
                long tstamp = UtilityMethods.safeConvertLong(vals.get(0));
                if (tstamp>=0) {
                    newRaw += UtilityMethods.safeConvertLong(vals.get(1));
                    newDur += UtilityMethods.safeConvertLong(vals.get(3));
                    long finAmt = UtilityMethods.safeConvertLong(vals.get(2));
                    newFin += finAmt;
                    if (finAmt>0) {
                        newFileCount++;
                    }
                }
                vals = CSVHelper.parseLine(content);
            }
            content.close();
            fis.close();
            %><tr><td><%=child.getParentFile().getName()%></td>
                <td><%=String.format( "%,d", newRaw)%></td>
                <td><%=String.format( "%,d", newFin)%></td>
                <td><%=String.format( "%,d", newDur)%></td>
                <td><%=String.format( "%,d", newFileCount)%></td></tr>
            <%
            tRaw += newRaw;
            tFin += newFin;
            tDur += newDur;
            tFileCount += newFileCount;

        }
    }
}



%><tr><td>TOTAL</td><td><%=String.format( "%,d", tRaw)%></td>
    <td><%=String.format( "%,d", tFin)%></td>
    <td><%=String.format( "%,d", tDur)%></td>
    <td><%=String.format( "%,d", tFileCount)%></td></tr>
</table>

</body>
</html>


