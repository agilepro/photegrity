<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.List" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.PosPat" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounter" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
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

    // get session variables
    String fromDisk = UtilityMethods.getSessionString(session, "fromDisk", "");
    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");
    String delDup = UtilityMethods.getSessionString(session, "delDup", "");


    String pattern = UtilityMethods.defParam(request, "g", "aa");
    String queryOrderPart = URLEncoder.encode("p("+pattern+")", "UTF8");
    String sortOrder = UtilityMethods.defParam(request, "o", "name");


    Hashtable allPaths = new Hashtable();
    HashCounter pathCount = new HashCounter();
    List<PosPat> vPatterns = PosPat.getAllEntries();
    List<PosPat> foundPatts = new Vector<PosPat>();

    String lastPatt = "\r";  //impossible match
    int limit = 30;
    PosPat lastPat = null;
    for (PosPat onePat : vPatterns) {

        String thisPattern = onePat.getPattern();
        if (thisPattern.length()<4) {
            continue;
        }
        if (!onePat.getDiskMgr().isLoaded) {
            continue;
        }
        if (lastPatt.equalsIgnoreCase(thisPattern)) {
            if (lastPat!=null) {
                foundPatts.add(lastPat);
                lastPat = null;
            }
            foundPatts.add(onePat);
            if (--limit < 0) {
                break;
            }
        }
        else {
            lastPatt = thisPattern;
            lastPat = onePat;
        }
    }

    int pageSize = UtilityMethods.getSessionInt(session, "listsize", 100);

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }

    String thisUrl = "pattern2.jsp?g="+URLEncoder.encode(pattern,"UTF8")+"&o="+sortOrder+"&min="+dispMin;

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Pattern '<%=pattern%>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table><tr><td>

<table><tr>
<td><a href="main.jsp"><img src="home.gif" border="0"></a></td>
   <td>
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td>
      <a href="startGrid.jsp?q=<%=queryOrderPart%>&min=0">R</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderPart%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderPart%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
Patterns starting with '<%=pattern%>'
</td>
<td><a href="masterPatts.jsp?s=<%=URLEncoder.encode(pattern,"UTF8")%>">SimilarTo(<%=pattern%>)</a>
    <% if (ImageInfo.unsorted) {%>(Unsorted)<%} %></td>
</tr></table>

<table>
<tr><td colspan="6"><img src="bar.jpg" border="0"></td></tr>
<%
    boolean found = false;
    String lastPath = "";
    for (PosPat pp : foundPatts) {

        DiskMgr dm = pp.getDiskMgr();
        String pppat = pp.getPattern();

        String query = "g(" + dm.diskName + ")e(" + pppat + ")";


%>
    <tr><td bgcolor=#FFEE88>
        <a href="pattern.jsp?g=<%UtilityMethods.writeURLEncoded(out, pppat);%>">(<% HTMLWriter.writeHtml(out, pppat); %>)</a></td><td><%= pp.getImageCount() %></td>
        <td bgcolor=#EEEEFF>
        <% if (!dm.isLoaded) {
                    %><a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(thisUrl,"UTF8")%>"
                         title="Load into memory disk named <%=dm.diskName%>"><img src="load.gif" border="0"></a>  <%
           } else {%>
           <a href="show.jsp?q=<%UtilityMethods.writeURLEncoded(out, query);%>">S</a>
           <a href="startGrid.jsp?q=<%UtilityMethods.writeURLEncoded(out, query);%>&min=0">R</a>
           <a href="queryManip.jsp?q=<%UtilityMethods.writeURLEncoded(out, query);%>">M</a>
           <%}%>
        </td>
        <td><%= pp.getDiskMgr().diskName %>:<%= pp.getLocalPath() %></td>
        <td>
        <%
            for (String tag : pp.getTags()) {
                String q2 = query + "g("+tag+")";
                if (tag.equals(dm.diskName)) {
                    continue;
                }
                %>
                <a href="show.jsp?q=<%UtilityMethods.writeURLEncoded(out, q2);%>"><%HTMLWriter.writeHtml(out, tag);%></a>, <%
            }
        %>
        </td>
        <td></td>
    </tr>
<%
    }
%>


</table>
<a href="main.jsp"><img src="home.gif" border="0"></a>
</BODY>
</HTML>
