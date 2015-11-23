<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.UtilityMethods"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    if (DiskMgr.archivePaths == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    int colInt = UtilityMethods.getSessionInt(session, "columns", 3);
    int imageNum = UtilityMethods.getSessionInt(session, "imageNum", 3);

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>JSP Test</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td><H1><img src="home.gif"></H1></td><td> &nbsp;  &nbsp;  &nbsp;
<a href="Logout.jsp">Logout</a> - -
<a href="sel.jsp?set=1" target="sel1">1</a>
<a href="sel.jsp?set=2" target="sel2">2</a>
<a href="sel.jsp?set=3" target="sel3">3</a>
<a href="sel.jsp?set=4" target="sel4">4</a>
<a href="sel.jsp?set=5" target="sel5">5</a>
- -
<a href="compare.jsp">Compare</a>
</td></tr>
</table>
<table><tr><td colspan="2">
<form action="masterGroups.jsp" method="get">
  <input type="text" name="s" value="">
  <input type="submit" value="Tag">
</form></td><td colspan="2">
<form action="masterPatts.jsp" method="get">
  <input type="text" name="s" value="">
  <input type="submit" value="Pattern">
<% if (ImageInfo.unsorted) {%>(Unsorted)<%} %>
</form></td></tr><tr>
<td><form action="selection.jsp" method="get">
  <input type="submit" value="Show Selection">
</form></td>
<td><form action="clearCache.jsp" method="get">
  <input type="submit" value="Clear Cache">
</form></td>
<td><form action="saveCache.jsp" method="get">
  <input type="submit" value="Save Cache">
</form></td>
<td><form action="config.jsp" method="get">
  <input type="submit" value="Configure">
</form></td>
<td><form action="compare.jsp" method="get">
  <input type="submit" value="Compare">
</form></td>
<td><form action="clearCache.jsp" method="get">
  <input type="submit" value="Recalc All">
  <input type="hidden" name="refreshAll" value="true">
</form></td>
</tr></table>
<form action="sizeDups.jsp" method="get">
  <input type="submit" value="Show Duplicates">
  Start Number: <input type="text" name="p" value="">
</form>
<hr><table width="400">
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
        out.write(mgr.diskName);
        if (!mgr.isLoaded) {
            %></b></td><td><a href="loaddisk.jsp?n=<%UtilityMethods.writeURLEncoded(out,mgr.diskName);%>"
                               title="Load into memory disk named
                               <%HTMLWriter.writeHtml(out, mgr.diskName);%>"><img src="load.gif"></a> &nbsp;<%
        }
        else {
            %></b></td><td> &nbsp;  &nbsp;  &nbsp;  &nbsp;<%
        }
        out.write("<a href=\"diskinfo.jsp?n=");
        UtilityMethods.writeURLEncoded(out,mgr.diskName);
        out.write("\">info</a>&nbsp;\n");

        // what is the purpose of this???
        HTMLWriter.writeHtml(out, mgr.mainFolder.toString().substring(0,1));
        out.write(" <a href=\"show.jsp?q=g(");
        UtilityMethods.writeURLEncoded(out,mgr.diskName);
        out.write(")\">S</a>\n");
        out.write("<a href=\"analyzeQuery.jsp?q=g(");
        UtilityMethods.writeURLEncoded(out,mgr.diskName);
        out.write(")\">A</a>\n");
        out.write("<a href=\"xgroups.jsp?q=g(");
        UtilityMethods.writeURLEncoded(out,mgr.diskName);
        out.write(")\">T</a>\n");
        out.write("<a href=\"allPatts.jsp?q=g(");
        UtilityMethods.writeURLEncoded(out,mgr.diskName);
        out.write(")\">P</a>\n");
        out.write("<a href=\"queryManip.jsp?q=g(");
        UtilityMethods.writeURLEncoded(out,mgr.diskName);
        out.write(")\">M</a>\n");
            %></td><td><%
        if (mgr.isChanged) {
            %> * <%
        }
        %></td>
        <td> <%= mgr.extraCount %> </td>
        <td> <%= mgr.extraSize/1000000 %>M </td>
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
  Local Path: <input type="text" name="pict" value="<%UtilityMethods.writeURLEncoded(out,localPath);%>"><br>
  Thumbnail Size: <input type="text" name="thumbsize" value="<%=thumbsize%>"><br>
  Columns: <input type="text" name="columns" value="<%=colInt%>"><br>
  ImageNum: <input type="text" name="imageNum" value="<%=imageNum%>"><br>
  <input type="hidden" name="go" value="main.jsp">
</form>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</body>
</HTML>
