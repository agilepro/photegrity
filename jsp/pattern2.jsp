<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.List" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.PosPat" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.HashCounter" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.UtilityMethods"
%><%@page import="org.workcast.streams.HTMLWriter"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (DiskMgr.archivePaths == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pattern = UtilityMethods.reqParam(request, "pattern2.jsp", "g");
    String queryOrderPart = URLEncoder.encode("p("+pattern+")", "UTF8");


    Hashtable allPaths = new Hashtable();
    HashCounter pathCount = new HashCounter();
    List<PosPat> vPatterns = PosPat.findAllPattern(pattern);

    int pageSize = UtilityMethods.getSessionInt(session, "listsize", 100);

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }

    String sortOrder = UtilityMethods.defParam(request, "o", "name");
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
      <a href="startGrid.jsp?q=<%=queryOrderPart%>&min=0">Row</a>
   </td><td>
      <a href="startGrid.jsp?q=<%=queryOrderPart%>&min=0&mode=grid">Grid</a>
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
    for (PosPat pp : vPatterns) {

        DiskMgr dm = pp.getDiskMgr();

        String query = "g(" + dm.diskName + ")e(" + pattern + ")";


%>
    <tr><td bgcolor=#FFEE88>
        <a href="showpp.jsp?symbol=<%UtilityMethods.writeURLEncoded(out, pp.getSymbol());%>"><% HTMLWriter.writeHtml(out, pp.getPattern()); %>_</a></td><td><%= pp.getImageCount() %></td>
        <td bgcolor=#EEEEFF>
        <% if (!dm.isLoaded) {
                    %><a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(thisUrl,"UTF8")%>"
                         title="Load into memory disk named <%=dm.diskName%>">
                         <img src="<%if(dm.loadingNow){%>loadplus.gif<%}else{%>load.gif<%}%>" border="0"></a>  <%
           } else {%>
           <a href="show.jsp?q=<%UtilityMethods.writeURLEncoded(out, query);%>">S</a>
           <a href="startGrid.jsp?q=<%UtilityMethods.writeURLEncoded(out, query);%>&min=0">R</a>
           <a href="queryManip.jsp?q=<%UtilityMethods.writeURLEncoded(out, query);%>">M</a>
           <%}%>
        </td>
        <td><%= pp.getDiskMgr().diskName %>:<%= pp.getLocalPath() %></td>
        <td>
        <%
            for (String tag : pp.getPathTags()) {
                String q2 = query + "g("+tag+")";
                if (tag.equals(dm.diskName)) {
                    continue;
                }
                %>
                <a href="taglist.jsp?t=<%UtilityMethods.writeURLEncoded(out, tag);%>"><%
                HTMLWriter.writeHtml(out, tag);
                %></a>, <%
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
<a href="pattern.jsp?g=<%UtilityMethods.writeURLEncoded(out, pattern);%>&o=name&min=0&showBunches=yes">Bunches</a>
<a href="showDups.jsp?q=p(<%UtilityMethods.writeURLEncoded(out, pattern);%>)">Show Dups</a>
<a href="startGrid.jsp?q=<%=queryOrderPart%>&min=0&mode=dups">Grid All Selected</a>
</BODY>
</HTML>
