<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.GridData"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null)
    {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String pageName = "showGrid.jsp";

    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }
    gData.singleRow = false;
    String query = gData.getQuery();
    Hashtable selectedColumns = gData.getSelectedColumns();




    String requestURL = request.getQueryString();

    String sel = gData.selMode;
    boolean showAll = (sel.equals("all"));
    boolean showSel = (sel.equals("sel"));
    boolean showUnsel = (sel.equals("unsel"));

    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");


    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);
    int pageSize = UtilityMethods.getSessionInt(session, "listSize", 20);

    int rowMax = 4;

    boolean groupSize = false;    //TODO: eliminate
    boolean groupNum = true;    //TODO: eliminate
    String order = "num";     //TODO: eliminate

    Vector rowMap = gData.getRowMap();
    if (showSel)
    {
        rowMap = gData.getSelectedRowMap();
    }

    int r  = UtilityMethods.defParamInt(request, "r", -999999);
    int rowMin = getRowNumberForValueX(r, rowMap);

    //now test if you are off the high end
    if (rowMin==-1)
    {
        //if the set is small, then set to zero
        rowMin = 0;

        //set rowMax from the end if larger than rowMax in set
        if (rowMap.size()>rowMax)
        {
            rowMin = rowMap.size()-rowMax;
        }
    }
    if (rowMin<rowMap.size())
    {
        r = ((Integer)rowMap.elementAt(rowMin)).intValue();
    }

    if (rowMin<0)
    {
        rowMin = 0;
    }

    int nextRow = rowMin + rowMax;
    String nextRowValue = "1000";
    if (nextRow>=rowMap.size())
    {
        nextRow=rowMap.size();
    }
    else
    {
        nextRowValue = rowMap.elementAt(nextRow).toString();
    }
    int prevRow = rowMin - rowMax;
    if (prevRow < 0)
    {
        prevRow = 0;
    }
    String prevRowValue = "0";
    if (prevRow<rowMap.size())
    {
        prevRowValue = rowMap.elementAt(prevRow).toString();
    }


    //Make a vector of Vectors
    Vector grid = gData.getEntireGrid();

    Vector colVec = gData.getColumnMap();

    Enumeration e2 = grid.elements();
    String queryOrder = "startGrid.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrderRow = queryOrder+"&r="+r;
    String lastPath = "";
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8");
    String queryOrderPart = queryOrderNoMin+"&r="+r;
    int recordCount = rowMap.size();

    String thisPage = "showGrid.jsp?r="+r;

///////////////////////////////////////

    int rowNum = -1;
    int colNum = 9999;
    int nextStart = 0;
    int lastSize = -1;


%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Show <%= r %> / <%= recordCount %></TITLE></HEAD>
<BODY BGCOLOR="#FDF5FF">


<table><tr>
   <td bgcolor="#FF0000">
      <a href="show.jsp?q=<%=queryOrderPart%>">S</a>
   </td><td>
      <a href="analyzeQuery.jsp?q=<%=queryOrderPart%>">A</a>
   </td><td>
      <a href="xgroups.jsp?q=<%=queryOrderNoMin%>">T</a>
   </td><td>
      <a href="allPatts.jsp?q=<%=queryOrderNoMin%>">P</a>
   </td><td>
      <a href="queryManip.jsp?q=<%=queryOrderPart%>">M</a>
   </td><td>
      <a href="manage.jsp?q=<%=queryOrderPart%>">I</a>
   </td><td>
      <a href="compare.jsp">Compare</a>
   </td><td>
      <a href="showRow.jsp?r=<%=r%>">Row</a>
   </td><td>
      <a href="showGrid2.jsp?r=<%=r%>">Grid2</a>
   </td></tr>
</table>
<table>
    <tr><td colspan="7"><img src="bar.jpg" border="0"></td></tr>
    <tr valign="top"><td colspan="7">
        <table><tr><td>
            <a href="main.jsp"><img src="home.gif" border="0"></a>
            <a href="sel.jsp?set=1" target="sel1">1</a>
            <a href="sel.jsp?set=2" target="sel2">2</a>
            <a href="sel.jsp?set=3" target="sel3">3</a>
            <a href="sel.jsp?set=4" target="sel4">4</a>
            <a href="sel.jsp?set=5" target="sel5">5</a>
        </td><td>
        <a href="showGrid.jsp?r=<%=prevRowValue%>"><img src="ArrowBack.gif" border="0"></a>
        @<%= r %>, <%= rowMin %> / <%= recordCount %>
        <a href="showGrid.jsp?r=<%=nextRowValue%>"><img src="ArrowFwd.gif" border="0"></a>
        <%

        if (showAll)
        {
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=sel">ShowSelected</a> <%
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=unsel">ShowUnSelected</a> <%
        }
        else if (showSel)
        {
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=all">ShowAll</a> <%
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=unsel">ShowUnSelected</a> <%
        }
        else
        {
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=all">ShowAll</a> <%
            %><a href="toggleColumn.jsp?r=<%=r%>&sel=sel">ShowSelected</a> <%
        }
        %>
        </td><td>
        (<a href="setBound.jsp?r=<%=r%>&op=T&v=-1000"><%=gData.rangeTop%></a>,
        <a href="setBound.jsp?r=<%=r%>&op=B&v=1000"><%=gData.rangeBottom%></a>)
        <%=gData.query%>
        </td></tr></table>
    </td></tr>
</table>
<table>
<%
    //do the top info row
    %><tr><td></td><%
    Enumeration cole = colVec.elements();
    while (cole.hasMoreElements())
    {
        String colLoc = (String) cole.nextElement();
        int num = gData.numberInColumn(colLoc);
        boolean isMarked = gData.isSelected(colLoc);
        if (showSel && !isMarked)
        {
            continue;
        }
        if (showUnsel && isMarked)
        {
            continue;
        }
        int colonPos = colLoc.lastIndexOf("/");
        String thisPattern = colLoc.substring(colonPos+1);
        String newQ = query+"e("+thisPattern+")";

        if (isMarked)
        {
            %><td align="center" bgcolor="yellow"><%
        }
        else
        {
            %><td align="center"><%
        }
        %>(<%=num%>) <%
        %><a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>"
           title="<%HTMLWriter.writeHtml(out,thisPattern);%>">S</a> <%
        %><a href="allPatts.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%> "
           title="<%HTMLWriter.writeHtml(out,thisPattern);%>">P</a></td><td></td><%

    }
    %></tr><%

    for (rowNum=rowMin; rowNum<nextRow; rowNum++)
    {
        if (rowNum>rowMap.size())
        {
            continue;
        }
        int rowQuant = ((Integer)rowMap.elementAt(rowNum)).intValue();
        Vector<ImageInfo> row = (Vector<ImageInfo>) gData.getRow(rowQuant);
        if (row==null)
        {
            throw new Exception("row '"+rowQuant+"' of grid is inexplicably null.");
        }


        %>
        <tr><td<%
             if (rowQuant<gData.rangeTop)
             {
                 %> bgcolor="pink"<%
             }
             else if (rowQuant>gData.rangeBottom)
             {
                 %> bgcolor="cyan"<%
             }
             else
             {
                 %> bgcolor="#FFFFFFFFF"<%
             }
             %> ><a href="setBound.jsp?r=<%=r%>&op=T&v=<%=rowQuant%>">T</a><br/>
                <a href="showGrid.jsp?r=<%=rowQuant%>"><%=rowQuant%></a><br/>
                <a href="setBound.jsp?r=<%=r%>&op=B&v=<%=rowQuant%>">B</a></td>
        <%
        cole = colVec.elements();
        while (cole.hasMoreElements())
        {
            String colLoc = (String) cole.nextElement();
            boolean isMarked = (selectedColumns.get(colLoc)!=null);
            if (showSel && !isMarked)
            {
                continue;
            }
            if (showUnsel && isMarked)
            {
                continue;
            }
            out.write("\n<td width=\"");
            out.write(Integer.toString(thumbsize));
            if (isMarked && false)
            {
                out.write("\" bgcolor=\"yellow");
            }
            out.write("\">");
            boolean foundOne = false;
            String dummyImg = "acquireSet/21Sextury/BlueAngel/blue_angel_100334_21_0005.jpg";
            ImageInfo defImg = gData.defaultImage(colLoc);
            if (defImg != null) {
                dummyImg = defImg.getRelPath();
            }

            for (ImageInfo ii : row)
            {
                String column = "";
                if (!ii.isNullImage())
                {
                    column  = ii.diskMgr.diskName+":"+ii.getRelativePath()+ii.getPattern();
                }
                if (!column.equals(colLoc))
                {
                    continue;
                }
                if (foundOne)
                {
                    %>@<%
                    continue;
                }
                foundOne = true;
                String encodedName = URLEncoder.encode(ii.fileName,"UTF8");
                String encodedPath = URLEncoder.encode(ii.getFullPath(),"UTF8");
                String encodedDisk = URLEncoder.encode(ii.diskMgr.diskName,"UTF8");
                String stdParams = "d="+encodedDisk+"&fn="+encodedName+"&p="+encodedPath;

                String truncName = ii.fileName;
                if (truncName.length()>30)
                {
                    truncName = truncName.substring(0,28)+"...";
                }
                String trashIcon = "trash.gif";
                if (ii.isTrashed)
                {
                    trashIcon = "delicon.gif";
                }

    %>
                <a href="photo/<%=ii.getRelPath()%>" target="photo">
                <img src="thumb/<%=thumbsize%>/<%=ii.getRelPath()%>" width="<%=thumbsize%>" border="0"></a>
                </td><td><a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                    <img border=0 src="addicon.gif"></a><br/>

                <font size="-4" color="#99CC99"><%=ii.value%></font><br/>
                <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF8")%>">
                   <img border=0 src="<%=trashIcon%>"></a>
    <%
            }
            if (!foundOne)
            {
                out.write("<img style=\"opacity:0.2\" src=\"thumb/100/");
                HTMLWriter.writeHtml(out, dummyImg);
                out.write("\" width=\""+thumbsize+"\" border=\"0\"></td><td width=\"20\">");
            }
            out.write("</td>");
        }
        %><td> &nbsp;  &nbsp; [<%=rowNum%>]</td><%
        out.write("\n</tr>");
        out.flush();
    }

    //now make the exclude row

    {
        out.write("\n<tr><td>X</td>");
        cole = colVec.elements();
        while (cole.hasMoreElements())
        {
            String colLoc = (String) cole.nextElement();
            boolean isMarked = (selectedColumns.get(colLoc)!=null);
            if (showSel && !isMarked)
            {
                continue;
            }
            if (showUnsel && isMarked)
            {
                continue;
            }
            String excludQuery = query + "b(" + colLoc + ")";
            %>
            <td align="center"><a href="startGrid.jsp?q=<%=URLEncoder.encode(excludQuery,"UTF8")%>&min=<%=r%>">X</a></td><td></td><%
        }

        out.write("\n</tr>");
    }

    {
        out.write("\n<tr><td>X</td>");
        cole = colVec.elements();
        while (cole.hasMoreElements())
        {
            String colLoc = (String) cole.nextElement();
            boolean isMarked = (selectedColumns.get(colLoc)!=null);
            if (showSel && !isMarked)
            {
                continue;
            }
            if (showUnsel && isMarked)
            {
                continue;
            }
            String prompt = "&lt;&lt;&lt;";
            if (isMarked)
            {
                prompt = "&gt;&gt;&gt;";
                out.write("<td bgcolor=\"yellow\" align=\"center\">");
            }
            else
            {
                out.write("<td align=\"center\">");
            }
            %>
            <a href="toggleColumn.jsp?r=<%=r%>&cval=<%=URLEncoder.encode(colLoc,"UTF8")%>"><%=prompt%></a></td><td></td><%
        }

        out.write("\n</tr>");
    }


    if (nextStart!=0)
    {
        %><tr><td colspan="7">That's all for this page. <a href="<%=queryOrder%>&min=<%=nextStart%>">
          Next page</a> starts at <%=nextStart%></td></tr><%
    }



%>
</table>
<table>
    <tr><td><a href="main.jsp"><img src="home.gif" border="0"></a></td>
        </tr>
</table>

<table>
<%
        cole = colVec.elements();
        int count = 0;
        while (cole.hasMoreElements())
        {
            String colLoc = (String) cole.nextElement();
            boolean isMarked = (selectedColumns.get(colLoc)!=null);
            if (showSel && !isMarked)
            {
                continue;
            }
            if (showUnsel && isMarked)
            {
                continue;
            }
%>
            <tr><td><%=++count%>: </td><td <% if (isMarked) {%>bgcolor="yellow"<%}%> ><%=colLoc%>
                ( <%=gData.numberInColumn(colLoc)%> )
            </td><form action="delDups.jsp">
                <input type="hidden" name="src" value="<%HTMLWriter.writeHtml(out,colLoc);%>">
                <td><input type="submit" name="action" value="Delete Dups">
                <input type="checkbox" name="doubleCheck" value="true"></td>
            </form>

            </tr>

            <%
            if (isMarked && showSel) {
                Enumeration othere = colVec.elements();
                while (othere.hasMoreElements())
                {
                    String otherLoc = (String) othere.nextElement();
                    boolean otherMarked = (selectedColumns.get(otherLoc)!=null);
                    if (!otherMarked)
                    {
                        continue;
                    }
                    if (colLoc.equals(otherLoc) && selectedColumns.size()>1)
                    {
                        continue;
                    }
                    int colonPos = otherLoc.lastIndexOf("/");
                    String dest = otherLoc.substring(0,colonPos+1);
                    String patt = otherLoc.substring(colonPos+1);

            %><tr><form action="delDups.jsp">
                  <input type="hidden" name="src" value="<%HTMLWriter.writeHtml(out,colLoc);%>">
                <td></td>
                <td>Move to: <input type="text" name="newLoc" value="<%HTMLWriter.writeHtml(out,dest);%>" size="50"><br/>
                    Rename to: <input type="text" name="newPatt" value="<%HTMLWriter.writeHtml(out,patt);%>">
                    <input type="submit" name="action" value="Consolidate">
                    <input type="checkbox" name="doubleCheck" value="true"><br/>
                    On Duplicate: <input type="radio" name="dupact" value="delNew" checked="checked"> delete file being moved
                                  <input type="radio" name="dupact" value="delOld"> copy over file</td>

            </form></tr><%
                }
            }
        }
%>
    </table>
<br/>
<hr/>
<br/>
<table width="600">
    <form method="GET" action="startGrid.jsp">
        <tr width="600"><td width="600">
            <input type="hidden" name="min" value="<%=r%>">
            <input type="hidden" name="o" value="num">
            <input type="submit" value="Change Query:">
            <input type="text" size="80" name="q" value="<%HTMLWriter.writeHtml(out,query);%>">
        </td></tr>
    </form>

<tr><td>
<form action="setPict.jsp" method="get">
  <input type="submit" value="Set">
  Thumbnail Size: <input type="text" name="thumbsize" size="5" value="<%=thumbsize%>">
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

    public static int getRowNumberForValueX(int photoValue, Vector v)
        throws Exception
    {
        int last = v.size();
        for (int i=0; i<last; i++)
        {
            Integer iVal = (Integer) v.elementAt(i);
            if (iVal.intValue() >= photoValue)
            {
                return i;
            }
        }
        return -1;
    }


%>