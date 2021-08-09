<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounter" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PosPat" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.io.Writer" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>
<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String diskName = UtilityMethods.reqParam(request, "diskinfo.jsp", "n");
    int option = UtilityMethods.defParamInt(request, "o", 0);
    String temp = request.getParameter("detail");
    boolean detail = (temp != null);
    diskName = diskName.toLowerCase();
    DiskMgr mgr = DiskMgr.getDiskMgr(diskName);
    String thisUrl = "diskinfo.jsp?n="+diskName;
    String query = "g("+URLEncoder.encode(diskName,"UTF8")+")";
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Disk '<%= diskName %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<h3>Disk '<%= diskName %>'


[<a href="delEmptyDirs.jsp?n=<%=diskName%>">clean</a>]
<a href="main.jsp"><img src="home.gif" border="0"></a>
</h3>
<table><tr>
   <td>
      <a href="show.jsp?q=<%=query%>">S</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=query%>">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=query%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=query%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=query%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=query%>">I</a>
   </td></tr>
</table>
<table width="300">
<tr align="right"><td></td><td>Count</td><td>Size</td></tr>
<tr align="right"><td>Extra</td><td><%= mgr.extraCount %></td><td><%= mgr.extraSize %></td></tr>
</table>

<%
    int suppcount = 0;
    int actualSuppCount = 0;
    int notSuppCount = 0;
   // Hashtable suppmap = new Hashtable();
    String[] dirArray = new String[1000];

%>

<img src="bar.jpg" border="0"><br>
<h3><a href="diskinfo.jsp?n=<%=URLEncoder.encode(diskName, "UTF-8")%>&o=0">Tags</a>
    <a href="diskinfo.jsp?n=<%=URLEncoder.encode(diskName, "UTF-8")%>&o=1">Patterns</a>
    <a href="diskinfo.jsp?n=<%=URLEncoder.encode(diskName, "UTF-8")%>&o=2">Directories</a>
    <a href="diskinfo.jsp?n=<%=URLEncoder.encode(diskName, "UTF-8")%>&o=3">Info</a></h3>
<ul>
<%
    if (option==0) {
        for (String key : mgr.getTagList()) {
            if (key.length() == 0) {
                continue;
            }
            int count = mgr.getTagCount(key);

            %><li><a href="show.jsp?q=g(<%=URLEncoder.encode(key,"UTF8")%>)"><%=key%></a>: (<%=count%>)
            <%
            for (DiskMgr dm : DiskMgr.getAllDiskMgr()) {
                if (dm.diskName.equals(diskName)) {
                    continue;
                }
                int count2 = dm.getTagCount(key);
                if (count2 > 0) {
                    out.write(" &nbsp; &nbsp; ");
                    HTMLWriter.writeHtml(out, dm.diskName);
                    out.write(":");
                    out.write(Integer.toString(count2));
                }
            }
        }
    }
    else if (option ==1) {
        out.write("<p>");
        for (PosPat pp : PosPat.getAllEntries()) {
            if (diskName.equals(pp.getDiskMgr().diskName)) {
                String key = pp.getPattern();
                int count = pp.getImageCount();

            %>&nbsp; (<a href="show.jsp?q=<%=URLEncoder.encode("p("+key+")","UTF8")%>"><%=key%></a>:<%=count%>) <%
            }
        }
        out.write("</p>");
    }
    else if (option==2) {
        out.write("<p>");
        printDirs(out,mgr.mainFolder);
        out.write("</p>");
    }
    else if (option==3) {
        %><table>
        <tr><td>diskName</td>
            <td><%=mgr.diskName%></td>
        </tr>
        <tr><td>mainFolder</td>
            <td><%=mgr.mainFolder%></td>
        </tr>
        <tr><td>mainFolder</td>
            <td><%=mgr.mainFolder%></td>
        </tr>
        </table><%
    }
%>
</ul>
<img src="bar.jpg" border="0"><br>
<a href="main.jsp"><img src="home.gif" border="0"></a>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>
<%!

public void printDirs(Writer out, File baseDir)
    throws Exception
{
    HTMLWriter.writeHtml(out,baseDir.toString());
    out.write("<br/>\n");
    out.flush();
    for (File cfile : baseDir.listFiles()) {
        if (cfile.isDirectory()) {
            printDirs(out, cfile);
        }
    }
}
%>
