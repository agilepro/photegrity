<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="java.util.Enumeration"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.photegrity.NewsGroup"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String hangOut = UtilityMethods.getSessionString(session, "hangOut", "");
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    int colInt = UtilityMethods.getSessionInt(session, "columns", 3);
    int imageNum = UtilityMethods.getSessionInt(session, "imageNum", 3);
    
    //starts news background processing if needed
    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    boolean groupLoaded = (newsGroup.defaultDiskMgr!=null);
    if (!groupLoaded) {
        Vector<File> files = DiskMgr.getNewsFiles();
        File parentFile = files.get(0);
        boolean connect = false;
        if (!parentFile.exists()) {
            throw new Exception("The news file path is not valid!:  "+parentFile);
        }
        newsGroup.openNewsGroupFile(parentFile, connect);
    }

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>JSP Test</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">

<style>
.bigtable {
    width:800px;
    background-color: #FDF5E6;
}
.bigtable tr:hover {
    background-color: #ffffff;
}
</style>


<table>
<tr><td><H1><img src="homeBig.gif" border="0">Photo Browser</H1></td><td> &nbsp;  &nbsp;  &nbsp;
<a href="<%= hangOut %>" title="return to the place you saved to hang out at">HangOut</a> - -
<a href="Logout.jsp">Logout</a> - -
<a href="sel.jsp?set=1" target="sel1">1</a>
<a href="sel.jsp?set=2" target="sel2">2</a>
<a href="sel.jsp?set=3" target="sel3">3</a>
<a href="sel.jsp?set=4" target="sel4">4</a>
<a href="sel.jsp?set=5" target="sel5">5</a>
<a href="compare.jsp">Compare</a>
<a href="news.jsp">News</a>
</td></tr>
</table>
<table><tr>
<form action="masterGroups.jsp" method="get">
  <td><input type="text" name="s" value="">
  <input type="submit" value="Tag"></td>
</form>
<form action="masterPatts.jsp" method="get">
  <td><input type="text" name="s" value="">
  <input type="submit" value="Pattern">
<% if (ImageInfo.unsorted) {%>(Unsorted)<%} %></td>
</form></tr></table>

<table><tr>
<form action="emptyTrash.jsp" method="get">
  <td><input type="submit" value="Empty Trash">
  <input type="hidden" name="refreshAll" value="true"></td>
</form>
<form action="clearCache.jsp" method="get">
  <td><input type="submit" value="Clear Cache"></td>
</form>
<form action="saveCache.jsp" method="get">
  <td><input type="submit" value="Save Cache"></td>
</form>
<form action="config.jsp" method="get">
  <td><input type="submit" value="Configure"></td>
</form>
<form action="compare.jsp" method="get">
  <td><input type="submit" value="Compare"></td>
</form>
<form action="selection.jsp" method="get">
  <td><input type="submit" value="Show Selection"></td>
</form>
<form action="clearCache.jsp" method="get">
  <td><input type="submit" value="Recalc All">
  <input type="hidden" name="refreshAll" value="true"></td>
</form>
</tr></table>
<hr><table class="bigtable">
<%
    Hashtable ht = DiskMgr.getDiskList();
    if (ht==null) {
        throw new Exception("ah-ha!  this is the odd case");
    }
    Enumeration e3 = HashCounter.sort(ht.keys());
    long totalextrasize = 0;
    long totalFileCount = 0;

    while (e3.hasMoreElements()) {

        String key = (String) e3.nextElement();
        DiskMgr mgr = (DiskMgr) ht.get(key);
        totalextrasize += mgr.extraSize/1000;
        totalFileCount += mgr.extraCount;
        out.write("<tr align=\"right\"><td align=\"left\"><b>");
        HTMLWriter.writeHtml(out, mgr.diskName);
        if (mgr.loadingNow) {
            %></b></td><td><a href="loaddisk.jsp?n=<%UtilityMethods.writeURLEncoded(out, mgr.diskName);%>&dest=main.jsp"
                  title="Load into memory disk named <%HTMLWriter.writeHtml(out, mgr.diskName);%>"><img src="loadplus.gif" border="0"></a> &nbsp;<%
        }
        else {
            %></b></td><td><a href="loaddisk.jsp?n=<%UtilityMethods.writeURLEncoded(out, mgr.diskName);%>&dest=main.jsp"
                  title="Load into memory disk named <%HTMLWriter.writeHtml(out, mgr.diskName);%>"><img src="load.gif" border="0"></a> &nbsp;<%
        }
        out.write("<a href=\"diskinfo.jsp?n=");
        UtilityMethods.writeURLEncoded(out, mgr.diskName);
        out.write("\"><img src=\"info.png\" border=\"0\"></a>&nbsp;\n");
        out.write(" <a href=\"show.jsp?q=");
        UtilityMethods.writeURLEncoded(out, getQuery(mgr.diskName));
        out.write("\">S</a>\n");
        out.write("<a href=\"analyzeQuery.jsp?q=");
        UtilityMethods.writeURLEncoded(out, getQuery(mgr.diskName));
        out.write("\">A</a>\n");
        out.write("<a href=\"xgroups.jsp?q=");
        UtilityMethods.writeURLEncoded(out, getQuery(mgr.diskName));
        out.write("\">T</a>\n");
        out.write("<a href=\"allPatts.jsp?q=");
        UtilityMethods.writeURLEncoded(out, getQuery(mgr.diskName));
        out.write("\">P</a>\n");
        out.write("<a href=\"queryManip.jsp?q=");
        UtilityMethods.writeURLEncoded(out, getQuery(mgr.diskName));
        out.write("\">M</a>\n");
            %></td><td><%
        if (mgr.isChanged) {
            %> * <%
        }
        %></td>
        <td> <%= mgr.extraCount %> </td>
        <td> <%= mgr.extraSize/1000000 %>M &nbsp;</td>
        <td align="left"> <%HTMLWriter.writeHtml(out, mgr.mainFolder.toString());%> </td>
     </tr><%
    }


%>
</table>
<table>
<tr align="right"><td>    </td><td>
   <font color="#666699"><%= totalFileCount %> files &nbsp; </font></td><td>    </td><td>
   <font color="#666699"><%= totalextrasize %>K &nbsp; </font></td></tr>
</table>
<hr>
<form action="diskinfo.jsp" method="get">
  <input type="submit" value="Show Disk Info">
  Disk Name: <input type="text" name="n" value="">
</form>
<form action="readdisk.jsp" method="get">
  <input type="submit" value="Scan Disk">
  Disk Name: <input type="text" name="n" value="">
  Path: <input type="text" name="p" value="">
</form>
<form action="setPict.jsp" method="get">
  <input type="submit" value="Set Image Location">
  Local Path: <input type="text" name="pict" value="<%HTMLWriter.writeHtml(out, localPath);%>"><br>
  Thumbnail Size: <input type="text" name="thumbsize" value="<%=thumbsize%>"><br>
  Columns: <input type="text" name="columns" value="<%=colInt%>"><br>
  ImageNum: <input type="text" name="imageNum" value="<%=imageNum%>"><br>
  <input type="hidden" name="go" value="main.jsp">
</form>
<table><tr>
<form action="sizeDups.jsp" method="get">
  <td><input type="submit" value="Show Duplicates">
  Start Number: <input type="text" name="p" value=""></td>
</form>
</tr></table>

<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</body>
</HTML>

<%!

public String getQuery(String diskName) {
    StringBuilder sb = new StringBuilder();
    int pos = diskName.indexOf(".");
    int start = 0;
    while (pos > start) {
        String part = diskName.substring(start,pos).trim();
        sb.append("g(").append(part).append(")");
        start = pos+1;
        pos = diskName.indexOf(".", start);
    }
    sb.append("g(").append(diskName.substring(start)).append(")");
    String x = sb.toString();
    return x;
}

%>