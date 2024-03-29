<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.FracturedFileName"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.TagInfo"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PosPat"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "show.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }


    // **** query?
    //    g(xyz)  find all images with matching tags
    //    p(xyz)  find all images with matching pattern
    //    s(#)    get from storage area #
    String symbol = UtilityMethods.reqParam(request, pageName, "symbol");
    PosPat pp = locateOrCreate(symbol);
    DiskMgr dm = pp.getDiskMgr();
    String requestURL = request.getQueryString();

    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");

    // **** sort in a given order?
    String order = UtilityMethods.defParam(request, "o", "name");
    String orderParam = "&o="+order;

    // **** show pictures?
    String pict = request.getParameter("pict");
    if (pict == null)
    {
        pict = UtilityMethods.getSessionString(session, "selPict", "no");
    }
    else
    {
        session.setAttribute("selPict", pict);
    }

    String listName = UtilityMethods.getSessionString(session, "listName", "");
    int thumbsize = 100;
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);
    int pageSize = UtilityMethods.getSessionInt(session, "listSize", 20);

    int rowMax = pageSize;

    boolean groupSize = false;
    boolean groupNum = false;
    if (pict.equals("group"))
    {
        if (order.equals("size"))
        {
            groupSize = true;
        }
        else
        {
            groupNum = true;
            order = "num";
        }
    }
    boolean showPict = (pict.equals("yes"));
    boolean allPict = (pict.equals("all"));
    String pictParam = "";
    if (groupSize || groupNum)
    {
        pictParam = "&pict=group";
        rowMax = 6;
    }
    else if (showPict)
    {
        pictParam = "&pict=yes";
        rowMax = 6;
    }
    else if (allPict)
    {
        pictParam = "&pict=all";
        pageSize = columns * rows;
        rowMax = rows;
    }

    Vector[] rowVectors = new Vector[rowMax];

    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }

    String query = "g(" + dm.diskName + ")e(" + pp.getPattern() + ")";

    String queryNoOrder = "showpp.jsp?symbol="+URLEncoder.encode(symbol,"UTF8");
    String queryOrder = queryNoOrder+"&o="+order+pictParam;
    String thisPage = queryOrder +"&min="+dispMin;

    String queryOrderPart="BOGUS";
    String queryOrderNoMin="BOGUS";

    String lastPath = "";
    Hashtable diskMap = new Hashtable();
    Vector<File> imageFileList = getMatchingFiles(pp);

    int totalCount = -1;
    String locationPartNoMin = URLEncoder.encode(query,"UTF8")+"&o="+order;
    String locationPartWithMin = queryOrderNoMin+"&min="+dispMin;
    int recordCount = imageFileList.size();

///////////////////////////////////////

    int rowNum = -1;
    int colNum = 9999;
    int nextStart = 0;
    int lastSize = -1;

    for (File child : imageFileList)
    {
        String fileName = child.getName();
        FracturedFileName ffn = FracturedFileName.parseFile(fileName);
        int value = UtilityMethods.safeConvertInt(ffn.numPart);
        totalCount++;

        //if you have not reached the start image, then skip
        if (totalCount < dispMin)
        {
            continue;
        }
        //if you have all the rows, then skip forward (so statistics are over fullset)
        if (rowNum >= rowMax) {
            continue;
        }

        //if this image causes things to go to the next row, and that
        //is too many rows, then nextStart will be the image that caused
        //this, and nextStart will be the right image to start next time with
        nextStart = totalCount;

        //now determine if we need a new row
        if (groupNum)
        {
            if (lastSize != value)
            {
                rowNum++;
                lastSize = value;
            }
        }
        else if (groupSize)
        {
            if (lastSize != (int)child.length())
            {
                rowNum++;
                lastSize = (int)child.length();
            }
        }
        else if (showPict)
        {
            rowNum++;
        }
        else if (allPict)
        {
            colNum++;
            if (colNum>=columns)
            {
                rowNum++;
                colNum = 0;
            }
        }
        else
        {
            rowNum++;
        }

        if (rowNum<0 || rowNum >= rowMax)
        {
            continue;
        }

        Vector<File> row = rowVectors[rowNum];
        if (row==null)
        {
            row = new Vector<File>();
            rowVectors[rowNum] = row;
        }

        row.add(child);
    }%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Show <%=dispMin%> / <%=recordCount%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5FF">
<table width="600"><tr><td>
<table><tr>
   <td bgcolor="#FF0000">
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>" title="Analyze this query">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderNoMin%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderNoMin%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
      <a href="startGrid.jsp?q=<%=queryOrderPart%>">Row</a>
   </td><td>
      <a href="compare.jsp">Compare</a>
   </td></tr>
</table>
<table>
    <tr><td colspan="7"><img src="bar.jpg"></td></tr>
    <tr valign="top"><td colspan="7">
        <table><tr><td>
            <a href="main.jsp"><img src="home.gif" border="0"></a>
            <a href="sel.jsp?set=1" target="sel1">1</a>
            <a href="sel.jsp?set=2" target="sel2">2</a>
            <a href="sel.jsp?set=3" target="sel3">3</a>
            <a href="sel.jsp?set=4" target="sel4">4</a>
            <a href="sel.jsp?set=5" target="sel5">5</a>
        </td><td>
        <a href="<%=queryOrder%>&min=<%=prevPage%><%=pictParam%>"><img src="ArrowBack.gif" border="0"></a>
        <%=dispMin%> / <%=recordCount%>
        <a href="<%=queryOrder%>&min=<%=nextStart%><%=pictParam%>"><img src="ArrowFwd.gif" border="0"></a>
        <%
            if (!groupSize && !groupNum)
                {
        %><a href="<%=queryNoOrder%><%=orderParam%>&pict=group&min=<%=dispMin%>"><img src="radio_off.png" border="0">Grouped</a> <%
    }
         else
         {
 %><img src="radio_on.png" border="0">Grouped <%
    }
         if (!showPict)
         {
 %><a href="<%=queryNoOrder%><%=orderParam%>&pict=yes&min=<%=dispMin%>"><img src="radio_off.png" border="0">Images</a> <%
    }
         else
         {
 %><img src="radio_on.png" border="0">Images <%
    }
         if (!allPict)
         {
 %><a href="<%=queryNoOrder%><%=orderParam%>&pict=all&min=<%=dispMin%>"><img src="radio_off.png" border="0">All</a> <%
    }
         else
         {
 %> <img src="radio_on.png" border="0">All <%
    }
         if (showPict || allPict || groupSize || groupNum)
         {
 %><a href="<%=queryNoOrder%><%=orderParam%>&pict=no&min=<%=dispMin%>"><img src="radio_off.png" border="0">Namelist</a> <%
    }
         else
         {
 %> <img src="radio_on.png" border="0">Namelist <%
    }
 %>
        </td><td>
        </td></tr></table>
    </td></tr>
</table>
<table>
<%
    //set totalcount back to value of first row
    totalCount = dispMin-1;

    String localPath = pp.getLocalPath();
    String encodedPath = URLEncoder.encode(localPath,"UTF8");
    String encodedDisk = URLEncoder.encode(dm.diskName,"UTF8");

    for (rowNum=0; rowNum<rowMax; rowNum++)
    {
        Vector<File> row = rowVectors[rowNum];
        if (row==null)
        {
            continue;
        }
        out.write("<tr>");
        boolean firstInRow = true;
        for (File child : row)
        {
            totalCount++;
            String location = "";
            String fileName = child.getName();
            FracturedFileName ffn = FracturedFileName.parseFile(fileName);
            String pattern = ffn.prePart;
            String value = ffn.numPart;
            String tail = ffn.tailPart;

            String encodedName = URLEncoder.encode(child.getName(),"UTF8");
            String stdParams = "d="+encodedDisk+"&fn="+encodedName+"&p="+encodedPath;
            String stdAndGo = stdParams+"&go="+encodedPath;
            String newQ = query+"e("+pattern+")";

            String truncName = child.getName();
            if (truncName.length()>30)
            {
                truncName = truncName.substring(0,28)+"...";
            }

            if (groupSize || groupNum)
            {
                if (firstInRow)
                {
                    if (groupSize)
                    {
                        out.write(Long.toString(child.length()));
                    }
                    else
                    {
                        //TODO: figure out the image number, split the name
                        out.write(value);
                    }
                    out.write("</td>");
                }
                out.write("<td>");
%>
                <a href="photo/<%=encodedDisk%>/<%=localPath%><%=fileName%>" target="photo">
                <img src="thumb/100/<%=encodedDisk%>/<%=localPath%><%=fileName%>" width="100" border="0"></a>
                </td><td>
                <a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                    <img border=0 src="addicon.gif" border="0"></a><br/>
                <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                    <img border=0 src="searchicon.gif" border="0"></a><br/>
                <font size="-4" color="#99CC99"><%=value%></font><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="trash.gif" border="0"></a>
                </td><%
                    }
                            else if (showPict)
                            {
                %>
                <td>
                <a href="photo/<%=encodedDisk%>/<%=localPath%><%=fileName%>" target="photo">
                <img src="thumb/100/<%=encodedDisk%>/<%=localPath%><%=fileName%>" width="100" border="0"></a>
                </td>
                <td>
                <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">S</a><br/>
                <a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                    <img border=0 src="addicon.gif" border="0"></a><br/>
                <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                    <img border=0 src="searchicon.gif" border="0"></a><br/>
                <font size="-4" color="#99CC99"><%=value%></font><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="trash.gif" border="0"></a>
                </td><%
                    }
                            else if (allPict)
                            {
                                if (firstInRow && false)
                                {
                                    out.write("<td>Row ");
                                    out.write(Integer.toString(rowNum));
                                    out.write("</td>");
                                }
                %>
                <td>
                <a href="photo/<%=encodedDisk%>/<%=localPath%><%=fileName%>" target="photo">
                <img src="thumb/100/<%=encodedDisk%>/<%=localPath%><%=fileName%>" width="100" border="0"></a>
                </td><td>
                <font size="-4" color="#99CC99"><%=value%></font><br/>
                <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">
                       S</a><br/>
                <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                       <img border=0 src="searchicon.gif" border="0"></a><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="trash.gif" border="0"></a>
                </td>
    <%
        }
                else {
    %>
                <td>
                <a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">S</a>
                <a href="photo/<%=encodedDisk%>/<%=localPath%><%=fileName%>" target="photo">
                    <%=truncName%></a></td>
                <td><a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                    <img border=0 src="searchicon.gif" border="0"></a></td>
                <td bgcolor="#FFCCAA"><%=dm.diskName%></td>
                <td>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
                <img border=0 src="trash.gif" border="0"></a>
                </td>
                <td>(<%
                    if (child.length()>250000) {
                                    out.write("<b><font color=\"red\">"+child.length()+"</font></b>");
                                  } else {
                                    out.write(Long.toString(child.length()));
                                  }
                %>)
    <%
                    //Enumeration eg = ii.tagVec.elements();
                    //while (eg.hasMoreElements()) {
                    //    TagInfo gi = (TagInfo) eg.nextElement();
                    //    HTMLWriter.writeHtml(out, gi.tagName);
                    //    out.write(" \t ");
                    //}
                %>
                </td>
    <%
            }
            firstInRow = false;
        }
        out.write("</tr>");
        out.flush();
    }

    if (nextStart!=0)
    {
        %><tr><td colspan="7">End of page
        <a href="<%=queryOrder%>&min=<%=prevPage%><%=pictParam%>"><img src="ArrowBack.gif" border="0"></a>
        <%= dispMin %> / <%= recordCount %>
        <a href="<%=queryOrder%>&min=<%=nextStart%><%=pictParam%>">
          <img src="ArrowFwd.gif" border="0"></a> next page:  <%=nextStart%></td></tr><%
    }

%>
</table>
<table>
    <tr><td>Sort by:</td>
        <td bgcolor=#EEEEBB colspan="5">
            <a href="<%=queryNoOrder%>&o=name<%=pictParam%>">Name</a>
            <a href="<%=queryNoOrder%>&o=num<%=pictParam%>">Number</a>
            <a href="<%=queryNoOrder%>&o=rand<%=pictParam%>">Random</a>
            <a href="<%=queryNoOrder%>&o=path<%=pictParam%>">Path</a>
            <a href="<%=queryNoOrder%>&o=size<%=pictParam%>">Size</a>
            </td>
        <td>(currently: <%=order%>)</td></tr>
</table>

<table>
<tr>
   <form method="post" action="move.jsp">
        <td>
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Move:">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="text" name="dest" value="<%HTMLWriter.writeHtml(out,moveDest);%>">
       </td>
   </form>
   <td> &nbsp; &nbsp; &nbsp; &nbsp;</td>
   <form method="post" action="delete.jsp">
       <td>
            <input type="submit" value="Trash <%= recordCount %>"> &nbsp;
            <input type="submit" value="UnTrash <%= recordCount %>" name="untrash">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="go" value="<%HTMLWriter.writeHtml(out,thisPage);%>">
       </td>
   </form>
</tr>
<tr>
    <form action="selectQuery.jsp" method="get">
        <td> <input type="submit" name="set" value="1">
            <input type="submit" name="set" value="2">
            <input type="submit" name="set" value="3">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="hidden" name="dest" value="show.jsp?<%=requestURL%>">
            &nbsp; &nbsp; <a href="showblack.jsp?q=<%=queryOrderPart%>">Display All On Black</a>
         </td>
    </form>
    <td> &nbsp; &nbsp;  &nbsp; &nbsp;</td>
    <form method="post" action="shrinkAll.jsp" target="_blank">
        <td>
            <input type="submit" value="Shrink <%= recordCount %>">
            <input type="hidden" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="checkbox" name="doubleCheck" value="ok"> check here to be sure
        </td>
    </form>
</tr>
</table>
<table width="600">
    <form method="GET" action="show.jsp">
        <tr width="600"><td width="600">
            <input type="hidden" name="o" value="<%=order%>">
            <input type="submit" value="Search:">
            <input type="text" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="text" size="5" name="min" value="<%=dispMin%>">
        </td></tr>
    </form>
    <form method="GET" action="renumberIndices.jsp">
        <tr width="600"><td width="600">
            <input type="submit" value="Renumber Indices">
            <input type="hidden" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
            <input type="hidden" name="doubleCheck" value="ok">
        </td></tr>
    </form>
    <form method="GET" action="threeDigitNumbers.jsp">
        <tr width="600"><td width="600">
            <input type="submit" value="Three Digit Numbers">
            <input type="hidden" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        </td></tr>
    </form>

<tr><td>
<form action="setPict.jsp" method="get">
  <input type="submit" value="Set">
  Columns: <input type="text" name="columns" size="5" value="<%=columns%>">
  Rows: <input type="text" name="rows" size="5" value="<%=rows%>">
  List: <input type="text" name="listSize" size="5" value="<%=pageSize%>">
  <input type="hidden" name="pict" value="<%=localPath%>">
  <input type="hidden" name="go" value="show.jsp?q=<%=queryOrderPart%>">
</form>
</td></tr></table>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.  </font>
</BODY>
</HTML>

<%!

    public static synchronized PosPat locateOrCreate(String symbol) throws Exception {
        int colonPos = symbol.indexOf(":");
        if (colonPos<=0) {
            throw new Exception("locateOrCreate needs a properly formatted symbol passed in, which has a disk name followed by colon.  Did not find any disk name in: "+symbol);
        }
        String diskName = symbol.substring(0, colonPos);
        DiskMgr dm = DiskMgr.getDiskMgr(diskName);
        int lastSlash = symbol.lastIndexOf("/");
        if (lastSlash<=colonPos) {
            throw new Exception("locateOrCreate needs a properly formatted symbol passed in, which has a pattern preceeded by a slash.  Did not find any pattern in: "+symbol);
        }
        String localPath = symbol.substring(colonPos+1, lastSlash+1);
        String pattern = symbol.substring(lastSlash+1);

        return PosPat.findOrCreate(dm, localPath, pattern);
    }
    public Vector<File> getMatchingFiles(PosPat pp) {
        File folder = pp.getFolderPath();
        String pattern = pp.getPattern();
        int pattLen = pattern.length();
        Vector<File> children = new Vector<File>();
        for (File child : folder.listFiles()) {
            String childName = child.getName();

            if (childName.length()>pattLen && childName.substring(0,pattLen).equalsIgnoreCase(pattern)) {
                children.add(child);
            }
        }
        return children;
    }

%>