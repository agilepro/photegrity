<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.TagInfo" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounter" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
%><jsp:include page="PasswordPanel.jsp" flush="true"/><%
    return;
    }

    // get session variables
    String fromDisk = UtilityMethods.getSessionString(session, "fromDisk", "");
    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");

    String pattern = UtilityMethods.reqParam(request, "group.jsp", "g");
    if (pattern == null) {
        pattern = "aa";
    }
    else {
        pattern = pattern.toLowerCase();
    }
    String order = UtilityMethods.defParam(request, "o", "name");


    Vector vGroups = TagInfo.getAllTagsStartingWith(pattern);
    Enumeration e = vGroups.elements();


    String pict = request.getParameter("pict");
    if (pict == null) {
        pict = UtilityMethods.getSessionString(session, "groupPict", "none");
    }
    else {
        session.setAttribute("groupPict", pict);
    }
    boolean showPict = pict.equals("show");
    boolean onlyPict = pict.equals("only");
    int pageSize = UtilityMethods.getSessionInt(session, "listsize", 100);

    if (showPict || onlyPict) {
        pageSize=20;
    }
    String pictParam = "&pict="+pict;

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }

    String urlGroup = "group.jsp?g="+URLEncoder.encode(pattern,"UTF8");
    String urlGroupOrder = urlGroup + "&o=" + order;
    String urlGroupOrderMin = urlGroupOrder + "&min=" + dispMin;

    Hashtable allPaths = new Hashtable();
    HashCounter pathCount = new HashCounter();
%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head><title>Tag '<%=pattern%>' Start <%=dispMin%></title></head>
<body BGCOLOR="#FDF5E6">
<table><tr><td>
   GroupList '<%=pattern%>'
</td><td>
<form action="selectGroup.jsp" method="get" target="suppwindow">
    <input type="submit" value="select entire group">
    <input type="hidden" name="g" value="<%=pattern%>">
    </form>
</td></tr></table>

    <a href="main.jsp"><img src="home.gif" border="0"></a>
    SimilarTo: <a href="masterGroups.jsp?s=<%=URLEncoder.encode(pattern,"UTF8")%>">(<%=pattern%>)</a>
    TagList: <a href="taglist.jsp?t=<%=URLEncoder.encode(pattern,"UTF8")%>">(<%=pattern%>)</a><br/>

<img src="bar.jpg">
<table>
<tr>
<th>Name</th><th>Loaded</th><th>- - - -</th><th>On Disks</th>
</tr>

<%
    boolean found = false;
    while (e.hasMoreElements()) {
        TagInfo gi = (TagInfo) e.nextElement();
        String gname = gi.tagName;
        String encodedQuery = "g("+URLEncoder.encode(gname,"UTF8")+")&o="+order;
        String specialColor = "";
        if (pattern.equalsIgnoreCase(gname)) {
            specialColor = " bgcolor=\"#FFFF88\"";
            found = true;
        }
%>
        <tr<%=specialColor%>><td>
        <a href="group.jsp?g=<%=URLEncoder.encode(gname,"UTF8")%>"><%=gname%></a>
        </td><td><%= gi.getCount() %></td><td>
        <a href="show.jsp?q=<%=encodedQuery%>">S</a>
        <a href="analyzeQuery.jsp?q=<%=encodedQuery%>">A</a>
        <a href="xgroups.jsp?q=<%=encodedQuery%>">T</a>
        <a href="allPatts.jsp?q=<%=encodedQuery%>">P</a>
        <a href="queryManip.jsp?q=<%=encodedQuery%>">M</a>
        </td><td>
<%

        for (DiskMgr dm : DiskMgr.getAllDiskMgr()) {
            String encodedSubQuery = "g("+URLEncoder.encode(gname,"UTF8")+")g("+URLEncoder.encode(dm.diskName,"UTF8")+")&o="+order;
            int count2 = dm.getTagCount(gname);
            if (count2 > 0) {
                %><%=dm.diskName%>:<%=count2%>
                <a href="show.jsp?q=<%=encodedSubQuery%>">S</a> &nbsp;
                <a href="diskinfo.jsp?n=<%=dm.diskName%>"><img src="info.png" border="0"></a>
                <%
                if (!dm.isLoaded) {
                    %><a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(urlGroupOrderMin,"UTF8")%>"
                          title="Load into memory disk named <%=dm.diskName%>"><img src="load.gif" border="0"></a> <%
                }
                %><br><%
            }
        }
%>
        </td></tr>
<%
     }
     if (!found) {
        String gname = pattern;
        String encodedQuery = "g("+URLEncoder.encode(gname,"UTF8")+")&o="+order;
%>
        <tr bgcolor="#FFFF88"><td>
        <a href="show.jsp?q=<%=encodedQuery%>"><%=gname%></a>
        </td><td>0</td><td>
        S A G P M
        </td><td>
<%
        for (DiskMgr dm : DiskMgr.getAllDiskMgr()) {
            int count2 = dm.getTagCount(gname);
            if (count2 > 0) {
                %><%=dm.diskName%>:<%=count2%>
                <a href="diskinfo.jsp?n=<%=dm.diskName%>"><img src="info.png" border="0"></a> <%
                if (!dm.isLoaded) {
                    %><a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(urlGroupOrderMin,"UTF8")%>"
                          title="Load into memory disk named <%=dm.diskName%>"><img src="load.gif" border="0"></a> <%
                }
                %><br><%
            }
        }
%>
        </td></tr>
<%
     }
%>
</table>
<table>
<tr><td colspan=17><img src="bar.jpg" border="0"></td></tr>
</table>
<br>
<table><tr>
<td>
<form action="group.jsp" method="get">
  <input type="text" name="g" value="<%=pattern%>">
  <input type="submit" value="Refresh Another List of Tags">
</form></td>
</tr></table>
<a href="main.jsp"><img src="home.gif" border="0"></a>
<a href="selection.jsp">Display Selection</a>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</body>
</html>
