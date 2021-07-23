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
    String dest = request.getParameter("dest");

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Three Digit <%HTMLWriter.writeHtml(out,query);%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<h2>Special Function to make all numbers three digits</h2>
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
    //String testPattern = sample.getPattern();
    boolean foundNegativeZero = false;
    Vector<ImageInfo> workingSet = new Vector<ImageInfo>();

    for (ImageInfo ii : groupImages) {

        if (ii.value<0) {
            //ignore negative for now.
            continue;
        }

        String threeDigit = Integer.toString(1000+ii.value).substring(1);
        int test = Integer.parseInt(threeDigit);
        if (test!=ii.value) {
            throw new Exception("problem with value "+(ii.value)+" got ("+threeDigit+") instead.");
        }
        String potential = ii.getPattern() + threeDigit + ii.tail;
        if (potential.equals(ii.fileName)) {
            continue;
        }

        out.write("<li> Change ");
        HTMLWriter.writeHtml(out,ii.fileName);
        out.write(" - ");
        HTMLWriter.writeHtml(out,potential);
        out.write("</li>\n");

        ii.renameFile(potential);
    }





%>
</ul>
<p>that is all</p>
</BODY>
</HTML>
<%!

    static Vector toDoList = new Vector();

%>
