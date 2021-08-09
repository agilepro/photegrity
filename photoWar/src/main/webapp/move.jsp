<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="java.util.Set" %>
<%@page import="java.util.List" %>
<%@page import="java.util.HashSet" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounterIgnoreCase" %>
<%@page import="com.purplehillsbooks.photegrity.NewsBunch" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.photegrity.MongoDB"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String query = UtilityMethods.reqParam(request, "move.jsp", "q").trim();
    String dest = UtilityMethods.reqParam(request, "move.jsp", "dest").trim();
    String news = UtilityMethods.defParam(request, "news", null);
    boolean moveNews = news!=null;
    HashCounterIgnoreCase newsToUpdate = new HashCounterIgnoreCase();

    dest = DiskMgr.fixSlashes(dest);
    if (!dest.endsWith("/")) {
        dest = dest + "/";
    }

    int colonpos = dest.indexOf(':');
    if (colonpos <= 0) {
        throw new Exception("Parameter 'dest' must have a disk name, colon, and path on that disk, instead received '"+dest+"'.");
    }
    String disk2 = dest.substring(0, colonpos);
    String destPath = dest.substring(colonpos+1);
    DiskMgr dm2 = DiskMgr.getDiskMgr(disk2);
    File destinationFolder = dm2.getFilePath(destPath);

    session.setAttribute("moveDest", dest);

    List<ImageInfo> moveImages = ImageInfo.imageQuery(query);


%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Move <%=query%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=2>
<H1>Move <%=query%></H1>
</td></tr>
<tr><td>Query</td><td><%HTMLWriter.writeHtml(out,query);%></td></tr>
<tr><td>Destination</td><td><%HTMLWriter.writeHtml(out,dest);%></td></tr>
</table>
<hr><ol>
<%


    int lastNum = 0;
    boolean useRelPath = (destPath.equals("*"));
    Set<File> locCleanup = new HashSet<File>();
   

    for (ImageInfo ii : moveImages) {
        
        locCleanup.add(ii.pp.getFolderPath());
        
        out.write("\n<li> ");
        HTMLWriter.writeHtml(out, ii.getFullPath());
        out.write("/");
        HTMLWriter.writeHtml(out, ii.fileName);
        out.write("<br>\n");
        HTMLWriter.writeHtml(out, dm2.mainFolder.getAbsolutePath());
        HTMLWriter.writeHtml(out, destPath);
        out.flush();

        ii = ii.moveImage(dm2, destinationFolder);
        
        locCleanup.add(ii.pp.getFolderPath());
    }
    

    DiskMgr.refreshFolders(locCleanup);

    Vector destVec = (Vector) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
        session.setAttribute("destVec", destVec);
    }
    int vecSize = destVec.size();
    boolean found = false;
    for (int i=0; i<vecSize; i++) {
        if (dest.equalsIgnoreCase((String) destVec.elementAt(i))) {
            destVec.removeElementAt(i);
            break;
        }
    }
    destVec.insertElementAt(dest, 0);
    while (destVec.size() > 16) {
        destVec.removeElementAt(destVec.size()-1);
    }


%>
</ol>
<p><b>All Done</b></p>
<hr>
<a href="main.jsp"><img src="home.gif"></a>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>
