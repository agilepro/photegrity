<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.TagInfo" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.Thumb" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String query = request.getParameter("q");
    if (query == null) {
        throw new Exception("page needs a 'q' parameter to specify the query");
    }
    String doubleCheck = request.getParameter("doubleCheck");
    boolean reallyDoIt = doubleCheck!=null;
    String dest = request.getParameter("dest");

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Shrink <%HTMLWriter.writeHtml(out,query);%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<h2>Special Function to renumber the Index files</h2>
<ul>
<li>Query: <%HTMLWriter.writeHtml(out,query);%></li>
<%

    boolean workToDo = true;
    int lastNum = 0;
    long totalBefore = 0;
    long totalAfter = 0;

    Vector<ImageInfo> groupImages = new Vector<ImageInfo>();
    groupImages.addAll(ImageInfo.imageQuery(query));

    ImageInfo sample = groupImages.firstElement();
    String testPattern = sample.getPattern();
    boolean foundNegativeZero = false;
    Vector<ImageInfo> workingSet = new Vector<ImageInfo>();

    for (ImageInfo ii : groupImages) {

        if (ii.fileName.indexOf("!")<0) {
            continue;
        }
        out.write("<li> "+ii.value+" - ");
        HTMLWriter.writeHtml(out,ii.fileName);
        out.write("</li>\n");

        if (ii.value==0) {
            foundNegativeZero = true;
        }

        if (!testPattern.equals(ii.getPattern())) {
            throw new Exception("I can not process this query because it contains more than one pattern.  Expected pattern ("+testPattern+") but found image with pattern ("+ii.getPattern()+")");
        }

        workingSet.add(ii);
    }


    if (!foundNegativeZero) {
            %></ul><p><b>No !00 index found!</b></p><ul><%
    } else {
        ImageInfo.sortImagesByNum(workingSet);
        if (reallyDoIt) {
            %></ul><p><b>Now Renaming Files</b></p><ul><%
        } else {
            %></ul><p><b>Proposed Names</b></p><ul><%
        }

        for (ImageInfo ii : workingSet) {

            int newVal = 101 - ii.value;
            String newName = ii.getPattern() + "!" + Integer.toString(newVal).substring(1) + ii.tail;
            out.write("<li> "+ii.value+" - ");
            HTMLWriter.writeHtml(out,ii.fileName);
            if (reallyDoIt) {
                ii.renameFile(newName);
            }
            out.write(" -- ");
            HTMLWriter.writeHtml(out,newName);
            out.write("</li>\n");
        }
    }


%>
</ul>
<p>thst is all</p>
</BODY>
</HTML>
<%!

    static Vector toDoList = new Vector();

%>
