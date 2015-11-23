<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Vector"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.net.URLEncoder"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String pageName = "manage.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String zingpat = (String) session.getAttribute("zingpat");

    String query = UtilityMethods.reqParam(request, pageName, "q");
    String order = UtilityMethods.defParam(request, "o", "name");
    int offset   = UtilityMethods.defParamInt(request, "min", 0);
    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");

    String showManageImage = UtilityMethods.defParam(request, "show", null);
    if (showManageImage == null) {
        showManageImage = UtilityMethods.getSessionString(session, "showManageImage", "no");
    } else {
        session.setAttribute("showManageImage", showManageImage);
    }
    boolean showImage = showManageImage.equals("yes");

    int bigSize = UtilityMethods.getSessionInt(session, "bigSize", 350);

    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));
    if (order!=null) {
        ImageInfo.sortImages(groupImages, order);
    }
    String fileName = "";
    String diskName = "";
    String path     = "";
    String imageURL = "";
    String thumbURL = "";
    String pattern  = "";
    int iFileSize = -1;
    ImageInfo ii = ImageInfo.getNullImage();
    Vector<String> imageGroups = new Vector<String>();
    boolean nothingToShow = groupImages.size()==0;

    if (nothingToShow) {
        offset = 0;
    }
    else {
        if (offset>=groupImages.size()) {
            offset = groupImages.size()-1;
        }
        ii = (ImageInfo) groupImages.elementAt(offset);
        if (ii == null) {
            //should never get this becuase we tested above for size.
            throw new Exception("No images at position "+offset);
        }
        fileName = ii.fileName;
        diskName = ii.diskMgr.diskNameLowerCase;
        path     = ii.getFullPath();
        imageURL = "photo/"+ii.getRelPath();
        thumbURL = "thumb/"+bigSize+"/"+ii.getRelPath();
        pattern  = ii.getPattern();
        iFileSize = ii.fileSize;
        imageGroups = ii.getTagNames();
    }

    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec==null) {
        destVec = new Vector();
    }
    int vecSize = destVec.size();

    String thisPage = "manage.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+offset;
    String prevPage = thisPage;
    if (offset > 0) {
        prevPage = "manage.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+(offset-1);
    }
    String nextPage = "manage.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+(offset+1);
    String queryOrderPart = URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+offset;
    String queryPlusPattern = URLEncoder.encode(query+"e("+pattern+")","UTF8")+"&o="+order+"&min=0";

    String newGroup = UtilityMethods.getSessionString(session, "newGroup", "");

%>
<HTML>
<HEAD><TITLE>I <%=offset%>, '<%HTMLWriter.writeHtml(out, fileName); %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table><tr>
   <td>
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
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
      <a href="showblack.jsp?q=<%=queryOrderPart%>">Black</a>
   </td><td>

<a href="<%HTMLWriter.writeHtml(out, prevPage);%>"><img src="ArrowBack.gif" border="0"></a>
<%=offset%> / <%= groupImages.size() %>
<a href="<%HTMLWriter.writeHtml(out, nextPage);%>"><img src="ArrowFwd.gif" border="0"></a>
<a href="<%=imageURL%>" target="photo">
    <%HTMLWriter.writeHtml(out, fileName);%>
</a>
   </td></tr>
</table>

<% if (showImage) { %>
<table>
  <tr>
    <td>
      <a href="<%=imageURL%>" target="photo">
        <img src="<%=imageURL%>" height="<%=bigSize%>" border="0">
      </a>
    </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>&show=no">Hide Image</a>
    </td>
  </tr>
</table>
<% } else { %>
[<a href="manage.jsp?q=<%=queryOrderPart%>&show=yes">Show Image</a>]
<% } %>

<table>
<form method="post" action="moveOne.jsp" name="moveOne">
<tr><td>
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
Move to: <input type="text" name="dest" value="<%=moveDest%>" size="70">
<input type="submit" value="Move Image">
</form>
</td>
</tr>
</form>
</table>

Pattern: <%HTMLWriter.writeHtml(out, pattern);%>:
   <a href="show.jsp?q=<%=queryPlusPattern%>">S</a>
   <a href="xgroups.jsp?q=<%=queryPlusPattern%>">T</a>
   <a href="allPatts.jsp?q=<%=queryPlusPattern%>">P</a>
   <a href="queryManip.jsp?q=<%=queryPlusPattern%>">M</a>

<form method="post" action="moveOne.jsp" name="buttons">
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
<input type="hidden" name="dest" value="">
<% for (int i=0; i<vecSize; i++) { %>
<input type="submit" name="butt<%=i%>" value="<%HTMLWriter.writeHtml(out, (String)destVec.elementAt(i));%>"
        onClick="buttons.dest.value=buttons.butt<%=i%>.value">
<input type="button" value="^" onClick="moveOne.dest.value=buttons.butt<%=i%>.value">
<% } %>
</form>
</p>
<img src="bar.jpg"><br>
<a href="main.jsp"><img src="home.gif"></a>
<%
if (showImage) {
    %><a href="manage.jsp?q=<%=queryOrderPart%>&show=no">No Image</a><%
} else {
    %><a href="manage.jsp?q=<%=queryOrderPart%>&show=yes">Show Image</a><%
}

if (ii!=null && ii.diskMgr != null)
{
%>
<table><tr>
<form method="get" action="insertGroup.jsp">
<td><input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
AddGroup: <input type="text" name="newGroup"  value="<%HTMLWriter.writeHtml(out, newGroup);%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, nextPage);%>">
<input type="submit" value="Insert Tag">
</td></form>
<td> &nbsp; &nbsp; &nbsp;</td>
<form method="get" action="deleteOne.jsp">
<td><input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="submit" value="Delete <%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
</td>
</form>
</tr></table>

<table>
<tr>
<form method="get" action="renameFile.jsp">
<td>
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
NewName: <input type="text" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
<input type="submit" value="Rename">
</td>
</form>
</tr>
</table>

<table>
<tr>
<form method="get" action="renameFile.jsp">
<td>
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"000.cover.jpg");%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
<input type="submit" value="Rename: <%HTMLWriter.writeHtml(out, zingpat+"000.cover.jpg");%>">
</td>
</form>

<form method="get" action="renameFile.jsp">
<td>
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"000.flogo.jpg");%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
<input type="submit" value="Rename: <%HTMLWriter.writeHtml(out, zingpat+"000.flogo.jpg");%>">
</td>
</form>
<form method="get" action="renameFile.jsp">
<td>
<input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
<input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
<input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
<input type="hidden" name="newName" size="80" value="<%HTMLWriter.writeHtml(out, zingpat+"000.sample.jpg");%>">
<input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
<input type="submit" value="Rename: <%HTMLWriter.writeHtml(out, zingpat+"000.sample.jpg");%>">
</td>
</form>
</tr>
</table>

<table>
<col width="100">
<col width="600">

<tr>
    <td>Loc:</td>
    <form method="post" action="refreshFolder.jsp">
    <input type="hidden" name="disk" value="<%HTMLWriter.writeHtml(out, diskName);%>">
    <input type="hidden" name="relPath" value="<%HTMLWriter.writeHtml(out, ii.getRelativePath());%>">
    <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
    <td><%HTMLWriter.writeHtml(out, diskName);%>:<%HTMLWriter.writeHtml(out, ii.getRelativePath());%>
    <input type="submit" value="Refresh Folder"></td>
    </form>
</tr>
<tr>
    <td>Tags:</td>
    <td><%
    for (String groupName : imageGroups) {
        %><a href="group.jsp?g=<%=URLEncoder.encode(groupName, "UTF-8")%>"><%
        HTMLWriter.writeHtml(out, groupName);
        %></a>, <%
    }
    %></td>
</tr>
<tr>
    <td>Pattern:</td>
    <td><%HTMLWriter.writeHtml(out, ii.getPattern());%></td>
</tr>
<tr>
    <td>Value:</td>
    <td><%=ii.value%></td>
</tr>
<tr>
    <td>Name:</td>
    <td><%HTMLWriter.writeHtml(out, fileName);%></td>
</tr>
<tr>
  <td>File Size:</td>
  <form method="get" action="shrinkOne.jsp">
  <td>
    <% if (iFileSize>250000) {
                out.write("<b><font color=\"red\">"+iFileSize+"</font></b>");
              } else {
                out.write(Integer.toString(iFileSize));
              }%>
    <input type="hidden" name="d" value="<%HTMLWriter.writeHtml(out, diskName);%>">
    <input type="hidden" name="p" value="<%HTMLWriter.writeHtml(out, path);%>">
    <input type="hidden" name="fn" value="<%HTMLWriter.writeHtml(out, fileName);%>">
    <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out, thisPage);%>">
    <input type="submit" value="Shrink <%HTMLWriter.writeHtml(out, fileName);%>">
</td>
</form>
</tr>
<tr>
    <td>diskName:</td>
    <td><%HTMLWriter.writeHtml(out, ii.diskMgr.diskName);%></td>
</tr>
<tr>
    <td>getFolderPath():</td>
    <td><%HTMLWriter.writeHtml(out, ii.getFolderPath().toString());%></td>
</tr>
<tr>
    <td>getFilePath():</td>
    <td><%HTMLWriter.writeHtml(out, ii.getFilePath().toString());%></td>
</tr>
<tr>
    <td>getFullPath():</td>
    <td><%HTMLWriter.writeHtml(out, ii.getFullPath());%></td>
</tr>
<tr>
    <td>getRelativePath():</td>
    <td><%HTMLWriter.writeHtml(out, ii.getRelativePath());%></td>
</tr>
<tr>
    <td>fileName:</td>
    <td><%HTMLWriter.writeHtml(out, ii.fileName);%></td>
</tr>
<tr>
    <td>getRelPath():</td>
    <td><%HTMLWriter.writeHtml(out, ii.getRelPath());%></td>
</tr>
<tr>
    <td>getPatternSymbol():</td>
    <td><%HTMLWriter.writeHtml(out, ii.getPatternSymbol());%></td>
</tr>
<% } %>
</td>
</tr>
<tr>
    <td>Query:</td>
    <td><%HTMLWriter.writeHtml(out, query);%></td>
</tr>
<tr>
    <td>Offset:</td>
    <td><%=offset%></td>
</tr>
<tr>
    <td>Go:</td>
    <td><%HTMLWriter.writeHtml(out, thisPage);%></td>
</tr>
<tr>
    <td>Thumbnails:</td>
    <td><a target="_blank" href="fillThumbnails.jsp?q=<%=URLEncoder.encode(query,"UTF8")%>">Generate Thumbnails</a></td>
</tr>
<tr>
    <td></td>
    <td><%
    long duration = System.currentTimeMillis() - starttime;
    %>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font></td>
</tr>
</table>
</BODY>
</HTML>