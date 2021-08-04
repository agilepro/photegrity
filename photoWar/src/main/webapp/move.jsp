<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.HashCounterIgnoreCase" %>
<%@page import="com.purplehillsbooks.photegrity.NewsBunch" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
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
    if (!dest.endsWith("/"))
    {
        dest = dest + "/";
    }

    int colonpos = dest.indexOf(':');
    if (colonpos <= 0) {
        throw new Exception("Parameter 'dest' must have a disk name, colon, and path on that disk, instead received '"+dest+"'.");
    }
    String disk2 = dest.substring(0, colonpos);
    String destPath = dest.substring(colonpos+1);
    DiskMgr dm2 = DiskMgr.getDiskMgr(disk2);

    session.setAttribute("moveDest", dest);

    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e = groupImages.elements();
    int recordCount = groupImages.size();

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Move <%=recordCount%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=2>
<H1>Move <%=recordCount%></H1>
</td></tr>
<tr><td>Query</td><td><%HTMLWriter.writeHtml(out,query);%></td></tr>
<tr><td>Destination</td><td><%HTMLWriter.writeHtml(out,dest);%></td></tr>
</table>
<hr><ol>
<%


    int lastNum = 0;
    boolean useRelPath = (destPath.equals("*"));

    while (e.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e.nextElement();
        if (ii == null) {
            throw new Exception ("null image file where lastnum="+lastNum);
        }
        if (moveNews) {
            String srcPosPat = ii.getPatternSymbol();
            newsToUpdate.increment(srcPosPat);
        }

        out.write("\n<li> ");
        HTMLWriter.writeHtml(out, ii.getFullPath());
        out.write("/");
        HTMLWriter.writeHtml(out, ii.fileName);
        out.write("<br>\n");
        HTMLWriter.writeHtml(out, dm2.extraPath);
        HTMLWriter.writeHtml(out, destPath);
        out.flush();

        ii.moveImage(disk2, dm2.extraPath + destPath);

    }

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

    if (moveNews) {
        for (String posPat : newsToUpdate.sortedKeys() ) {
            int slashPos = posPat.lastIndexOf("/");
            if (slashPos>0) {
                String srcLoc = posPat.substring(0,slashPos+1);
                String srcPatt = posPat.substring(slashPos+1);
                out.write("\n<li>Updating News: "+srcLoc+" - "+srcPatt+" - "+dest+"</li>");
                NewsBunch.trackMovedFiles(srcLoc, srcPatt, dest, srcPatt);
            }
        }
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
