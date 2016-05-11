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
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.NewsBunch" %>
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

    // get session variables
    String fromDisk = UtilityMethods.getSessionString(session, "fromDisk", "");
    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");
    String delDup = UtilityMethods.getSessionString(session, "delDup", "");


    String pattern = UtilityMethods.defParam(request, "g", "aa");
    String queryOrderPart = URLEncoder.encode("p("+pattern+")", "UTF8");
    String sortOrder = UtilityMethods.defParam(request, "o", "name");
    boolean showBunches = "yes".equals(UtilityMethods.defParam(request, "showBunches", "no"));


    Hashtable allPaths = new Hashtable();
    HashCounter pathCount = new HashCounter();
    Vector vPatterns = ImageInfo.getAllPatternsStartingWith(pattern);
    Enumeration e = vPatterns.elements();

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

    String thisUrl = "pattern.jsp?g="+URLEncoder.encode(pattern,"UTF8")+"&o="+sortOrder+"&min="+dispMin;

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
<tr><td><img src="bar.jpg" border="0"></td></tr>
<%
    boolean found = false;
    String lastPath = "";
    while (e.hasMoreElements()) {

        PatternInfo pi = (PatternInfo) e.nextElement();
        if (!pi.pattern.equalsIgnoreCase(pattern)) {
            continue;
        }

        found = true;
        Hashtable groupMap = new Hashtable();
        Hashtable diskMap = new Hashtable();

        int[] missingTable = new int[2000];
        for (int k=0; k<2000; k++) {
            missingTable[k] = 0;
        }

%>
    <tr><td bgcolor=#FFEE88>
        <table><tr><td><h3><%= pi.pattern %> (<%= pi.count %>) </h3></td>
        <td>
<%
        for (DiskMgr dm : DiskMgr.getAllDiskMgr()) {
            int count2 = dm.getPatternCount(pi.pattern);
            if (count2 > 0) {
                %> &nbsp; <%=dm.diskName%>:<%=count2%> <%
                if (!dm.isLoaded) {
                    %><a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(thisUrl,"UTF8")%>"
                         title="Load into memory disk named <%=dm.diskName%>"><img src="load.gif" border="0"></a>  <%
                }
                %><br><%
            }
        }
%>
            </td>
        </tr></table>
    </td></tr>
<%
        Vector sortedImages = new Vector();
        sortedImages.addAll(pi.allImages);
        ImageInfo.sortImages(sortedImages, sortOrder);
        Enumeration e2 = sortedImages.elements();
        int totalCount=-1;
        while (e2.hasMoreElements()) {

            totalCount++;
            ImageInfo ii = (ImageInfo)e2.nextElement();
            if (diskMap.containsKey(ii.diskMgr.diskName)) {
                Integer prevVal = (Integer)diskMap.get(ii.diskMgr.diskName);
                diskMap.put(ii.diskMgr.diskName, new Integer(prevVal.intValue()+1));
            }
            else {
                diskMap.put(ii.diskMgr.diskName, new Integer(1));
            }
            String pp = ii.getRelativePath();
            if (pp.equals(lastPath)) {
                pp = "";
            }
            else {
                lastPath = pp;
            }
            if (ii.value < 1000) {
                missingTable[1000+ii.value]++;
            }
            for (String tagName : ii.getTagNames()) {
                if (tagName.length() > 0) {
                    if (groupMap.containsKey(tagName)) {
                        Integer prevVal = (Integer)groupMap.get(tagName);
                        groupMap.put(tagName, new Integer(prevVal.intValue()+1));
                    }
                    else {
                        groupMap.put(tagName, new Integer(1));
                    }
                }
                else {
                    throw new Exception("Got tag with zero length string");
                    // should print out some sort of warning here
                }
            }
            String location = ii.diskMgr.diskName+":"+ii.getRelativePath();
            allPaths.put(location, ii.getFullPath());
            pathCount.increment(location);
        }

        %><tr><td>Contains: &nbsp; <%

        int i=0;
        while (i<2000 && missingTable[i] == 0) {
            i++;
        }
        int rstart = i;
        int rend = i;
        while (i<2000) {
            while (i<2000 && missingTable[i]>0) {
                rend = i;
                i++;
            }
            if (i == 2000) {
                out.write(Integer.toString(rstart-1000));
                out.write("-1000+");
                break;
            }
            if (rstart < rend) {
                out.write(Integer.toString(rstart-1000));
                out.write("-");
                out.write(Integer.toString(rend-1000));
                out.write(", ");
            }
            else {
                out.write(Integer.toString(rstart-1000));
                out.write(", ");
            }


            while (i<2000 && missingTable[i]==0) {
                i++;
            }
            if (i == 2000) {
                break;
            }
            rstart = i;
        }

%>
    </td></tr><tr><td>Missing: &nbsp; <%

        i=0;
        while (i<2000 && missingTable[i]==0) {
            i++;
        }
        int min = i;
        int max = i;
        while (i<2000) {
            while (i<2000 && missingTable[i]>0) {
                max = i;
                i++;
            }
            if (i == 2000) {
                break;
            }
            int starts = i;
            while (i<2000 && missingTable[i]==0) {
                i++;
            }
            if (i == 2000) {
                break;
            }
            if (starts < i-1) {
                out.write("" + (starts-1000) + "-" + (i-1001) + ", ");
            }
            else {
                out.write("" + (starts-1000) + ", ");
            }
        }

        out.write("<br>Min: " + (min-1000) + "  Max: " + (max-1000));
        Enumeration e3 = diskMap.keys();
        while (e3.hasMoreElements()) {
            String disk1 = (String) e3.nextElement();
            Integer num = (Integer) diskMap.get(disk1);
            Enumeration e4 = diskMap.keys();
            while (e4.hasMoreElements()) {
                String disk2 = (String) e4.nextElement();
                if (!disk2.equals(disk1)) {

%>              {move <%=num.intValue()%> <%= disk1 %>--&gt;<%= disk2 %>} &nbsp;
<%
                }
            }
        }

%>
    </td></tr><tr><td>Duplicate: &nbsp; <%

        i=0;
        while (i<2000 && missingTable[i]<2) {
            i++;
        }
        int dstart = i;
        int dend = i;
        while (i<2000) {
            while (i<2000 && missingTable[i]>1) {
                dend = i;
                i++;
            }
            if (i == 2000) {
                out.write("" + (dstart-1000) + "-999+");
                break;
            }
            if (dstart < dend) {
                out.write("" + (dstart-1000) + "-" + (dend-1000) + ", ");
            }
            else {
                out.write("" + (dstart-1000) + ", ");
            }
            while (i<2000 && missingTable[i]<=1) {
                i++;
            }
            if (i == 2000) {
                break;
            }
            dstart = i;
        }
%>
    </td></tr>
    </table>
    <img src="bar.jpg" border="0">
    <table><%

        out.flush();
        if (showBunches) {
            List<NewsBunch>  matches = NewsGroup.findBunchesWithPattern(pattern);
            for (NewsBunch aBunch : matches) {
                int countTotal=aBunch.fileTotal;
                int countComplete=aBunch.fileComplete;
                int countDown=aBunch.fileDown;

                %>
                <tr><td bgcolor="<%=aBunch.getStateColor()%>">
                        <a href="newsFilePatt.jsp?d=<%=URLEncoder.encode(aBunch.digest,"UTF8")%>&selPatt=<%=URLEncoder.encode(pattern,"UTF8")%>">
                        <% HTMLWriter.writeHtml(out, aBunch.digest); %></a></td>
                    <td>
                      <%=countDown%>+<%=countComplete-countDown%>+<%=countTotal-countComplete%>
                    </td>
                    <td>
                        <% HTMLWriter.writeHtml(out, aBunch.getFolderLoc()); %><% HTMLWriter.writeHtml(out, aBunch.getSampleFileName()); %>
                        </td></tr>
                <%
                out.flush();
            }
            if (matches.size()==0) {
                out.write("<tr><td>No bunches for pattern: ");
                HTMLWriter.writeHtml(out, pattern);
                out.write("</td></tr>");
            }
        }
        else {
            %><tr><td>Click to <a href="<%=thisUrl%>&showBunches=yes">Show Bunches</a></td></tr><%
        }


    %></table>
    <img src="bar.jpg" border="0">
    <table>
<%
     }
     if (!found) {
%>
        <tr bgcolor=#BBBBFF><td>
        Exact "<%=pattern%>":
<%
        for (DiskMgr dm : DiskMgr.getAllDiskMgr()) {
            int count2 = (Integer) dm.getPatternCount(pattern);
            if (count2 > 0) {
                %> &nbsp; <%=dm.diskName%>:<%=count2%> <%
                if (!dm.isLoaded) {
                    %>(<a href="loaddisk.jsp?n=<%=dm.diskName%>&dest=<%=URLEncoder.encode(thisUrl,"UTF8")%>"
                          title="Load into memory disk named <%=dm.diskName%>"><img src="load.gif" border="0"></a>)  <%
                }
            }
        }
%>      </td></tr>
        <tr><td><img src="bar.jpg" border="0"></td></tr>
<%
    }
    e = vPatterns.elements();
    while (e.hasMoreElements()) {

        PatternInfo pi = (PatternInfo) e.nextElement();
        if (!pi.pattern.equalsIgnoreCase(pattern)) {
%>
    <tr><td bgcolor=#EEEEAA>
        <b>See: <a href="pattern.jsp?g=<%= URLEncoder.encode(pi.pattern,"UTF8") %>">
                <%= pi.pattern %></a> (<%= pi.count %>) </b>
    </td></tr>
<%
        }
    }

%>
<tr><td>
Show: [<a href="show.jsp?q=<%=queryOrderPart%>t()&min=0">Identical Sizes</a>]
[<a href="showDups.jsp?q=<%=queryOrderPart%>">Identical Numbers</a>]
[<a href="startGrid.jsp?q=<%=queryOrderPart%>&min=0&mode=grid">All Grid</a>]
</td></tr>
<tr><td>
<img src="bar.jpg" border="0">

</td></tr></table>
<a href="main.jsp"><img src="home.gif" border="0"></a>
</BODY>
</HTML>
