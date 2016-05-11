<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.Writer" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Vector" %>
<%@page import="java.util.Collections" %>
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

    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String[] tagArray = request.getParameterValues("tag");

    if (tagArray==null || tagArray.length==0) {
        String tags = UtilityMethods.reqParam(request, "taglist.jsp", "t");
        tagArray = tags.split(",");
    }


    String thisUrl = "taglist.jsp?"+combineParams("tag", tagArray);

    StringBuffer queryq = new StringBuffer();

    List<PosPat> vPosPats = PosPat.getAllEntries();
    for (String oneTag : tagArray) {
        vPosPats = PosPat.filterByTag(vPosPats, oneTag);
        queryq.append("g("+oneTag+")");
    }

    Vector<String> narrowTags = new Vector<String>();
    for (PosPat example : vPosPats) {
        for (String fTag : example.getPathTags()) {
            if (!narrowTags.contains(fTag)) {
                narrowTags.add(fTag);
            }
        }
    }
    Collections.sort(narrowTags);

    String queryOrderPart = URLEncoder.encode(queryq.toString(), "UTF8");
    int pageSize = UtilityMethods.getSessionInt(session, "listsize", 100);


%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Tags: <%writeArray(out, tagArray);%></TITLE></HEAD>
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
Tags <%writeArray(out, tagArray);%>
</td>
<td>SimilarTo(
<%   for (String nTag : tagArray) {
        out.write("<a href=\"masterGroups.jsp?s=");
        UtilityMethods.writeURLEncoded(out, nTag);
        out.write("\">");
        HTMLWriter.writeHtml(out, nTag);
        out.write("</a> ");
     }
%>)
</td>
</tr></table>

<table>
<tr><td colspan="6"><img src="bar.jpg" border="0"></td></tr>
<%
    boolean found = false;
    String lastPath = "";
    int limit = 100;
    for (PosPat pp : vPosPats) {

        if (--limit<0) {
            break;
        }

        DiskMgr dm = pp.getDiskMgr();

        String query = "g(" + dm.diskName + ")e(" + pp.getPattern() + ")";


%>
    <tr><td bgcolor=#FFEE88>
        <a href="showpp.jsp?symbol=<%UtilityMethods.writeURLEncoded(out, pp.getSymbol());%>"><% HTMLWriter.writeHtml(out, pp.getPattern()); %>_</a></td><td><%= pp.getImageCount() %></td>
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
            for (String tag : pp.getPathTags()) {
                if (tag.equals(dm.diskName)) {
                    continue;
                }
                String url = "taglist.jsp?" + combineParams("tag", tagArray) + "&tag=" + URLEncoder.encode(tag);

                %><a href="<%=url%>">
                <%HTMLWriter.writeHtml(out, tag);%>
                </a>, <%
            }
        %>
        </td>
        <td></td>
    </tr>
<%
    }
%>


</table>
<hr/>
<p>Remove:
<%   for (String elimTag : tagArray) {
        StringBuffer others = new StringBuffer();
        for (String other : tagArray) {
            if (!other.equals(elimTag)) {
                if (others.length()>0) {
                    others.append(",");
                }
                others.append(other);
            }
        }
        if (others.length()>0) {
            out.write("<a href=\"taglist.jsp?t=");
            UtilityMethods.writeURLEncoded(out, others.toString());
            out.write("\">");
            HTMLWriter.writeHtml(out, elimTag);
            out.write("</a> ");
        }
     }
%>
</p>
<p>Narrow to:
<%
    for (String tagx : narrowTags) {
        boolean foundd = false;
        for (String exclude : tagArray) {
            if (exclude.equalsIgnoreCase(tagx)) {
                foundd=true;
            }
        }
        if (foundd) {
            continue;
        }
        String url = "taglist.jsp?" + combineParams("tag", tagArray) + "&tag=" + URLEncoder.encode(tagx);
        %><a href="<%=url%>">
        <%HTMLWriter.writeHtml(out, tagx);%></a>, <%
    }

%></p>
<p>Directly to:
<%
    for (String tagx : narrowTags) {
        %><a href="taglist.jsp?tag=<%UtilityMethods.writeURLEncoded(out, tagx);%>">
        <%HTMLWriter.writeHtml(out, tagx);%></a>, <%
    }

%></p>
<a href="main.jsp"><img src="home.gif" border="0"></a>
</BODY>
</HTML>
<%!

    public String combineParams(String name, String[] vals) throws Exception  {
        StringBuffer sb = new StringBuffer();
        boolean notFirst = false;
        for (String val : vals) {
            if (notFirst) {
                sb.append("&");
            }
            notFirst = true;
            sb.append(name);
            sb.append("=");
            sb.append( URLEncoder.encode(val, "UTF-8") );
        }
        return sb.toString();
    }

    public void writeArray(Writer out, String[] vals) throws Exception  {
        for (String val : vals) {
            HTMLWriter.writeHtml(out, val);
            out.write(" ");
        }
    }


%>
