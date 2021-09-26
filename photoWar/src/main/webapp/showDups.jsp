<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.TagInfo"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "showDups.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }


    // **** query?
    //    g(xyz)  find all images with matching tags
    //    p(xyz)  find all images with matching pattern
    //    s(#)    get from storage area #
    String query = UtilityMethods.reqParam(request, pageName, "q");
    String requestURL = request.getQueryString();

    String widerQuery = null;
    int ppos = query.lastIndexOf('(');
    if (ppos>3) {
        widerQuery = query.substring(0,ppos-1);
    }


    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");

    // **** sort in a given order?
    String order = "num";
    String orderParam = "&o=name";

    // **** show pictures?
    // **** this page only shows grouped mode
    String pict = "group";

    String listName = UtilityMethods.getSessionString(session, "listName", "");
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);
    int pageSize = UtilityMethods.getSessionInt(session, "listSize", 20);

    int rowMax = 6;

    String pictParam = "&pict=group";


    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }


    String queryNoOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+pictParam;
    String thisPage = queryOrder +"&min="+dispMin;
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8")+"&o="+order;
    String queryOrderPart = queryOrderNoMin+"&min="+dispMin;

    String lastPath = "";
    Hashtable diskMap = new Hashtable();
    Vector<ImageInfo> initialImages = new Vector<ImageInfo>();
    initialImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(initialImages, order);
    int recordCount = initialImages.size();

    Vector<String> foundDupIndicators = new Vector<String>();
    foundDupIndicators.add("");

    Vector<ImageInfo> rowImages = new Vector<ImageInfo>();
    Vector<Vector<ImageInfo>> groupedImages = new Vector<Vector<ImageInfo>>();
    int lastRowVal = -99999;
    for (ImageInfo ii : initialImages) {
        if (ii.value != lastRowVal) {
            //need to process the collected row
            addIfDupTags(groupedImages, rowImages, foundDupIndicators);
            rowImages = new Vector<ImageInfo>();
            lastRowVal = ii.value;
        }
        rowImages.add(ii);
    }
    addIfDupTags(groupedImages, rowImages, foundDupIndicators);



///////////////////////////////////////

    int rowNum = -1;
    int colNum = 9999;
    int nextStart = 0;
    int lastSize = -1;
    int totalCount = -1;


%><!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
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
        </td><td>
        <a href="fixDups.jsp?q=<%=queryOrderPart%>">FIX DUPS</a>
        </td></tr></table>
    </td></tr>
</table>
<table>
<%
    //set totalcount back to value of first row
    totalCount = dispMin-1;

    out.write("\n<tr><td></td>");
    for (String columnHead : foundDupIndicators) {
        out.write("\n<th>"+ columnHead + "</th><th></th>");

    }
    out.write("</tr>");

    for (Vector<ImageInfo> row : groupedImages) {
        out.write("\n<tr>");

        boolean firstInRow = true;
        for (String column : foundDupIndicators) {
            totalCount++;
            ImageInfo ii = findImageByDupIndicator(row, column);
            String location = "";
            String encodedPath = "";
            String encodedDisk = "";
            String newQ = query;
            String diskName = "";
            String relPath = "null";
            String encodedName = "";
            if (ii==null) {
                ii = ImageInfo.getNullImage();
            }
            else if (!ii.isNullImage())
            {
                encodedName = URLEncoder.encode(ii.fileName,"UTF8");
                diskName = ii.pp.getDiskMgr().diskName;
                relPath = diskName+"/"+ii.getRelativePath()+ii.fileName;
                location = diskName+":"+ii.getRelativePath();
                encodedPath = URLEncoder.encode(ii.getFilePath().getAbsolutePath(),"UTF8");
                encodedDisk = URLEncoder.encode(diskName,"UTF8");
                newQ = query+"e("+ii.getPattern()+")";
            }

            String stdParams = "d="+encodedDisk+"&fn="+encodedName+"&p="+encodedPath;
            String stdAndGo = stdParams+"&go="+encodedPath;
            String trashIcon = "trash.gif";
            if (ii.isTrashed()) {
                trashIcon = "delicon.gif";
            }


            String truncName = ii.fileName;
            if (truncName.length()>30)
            {
                truncName = truncName.substring(0,28)+"...";
            }

            if (firstInRow)
            {
                out.write("<td>");
                out.write(Integer.toString(ii.value));
                out.write("</td>");
            }
            out.write("\n<td>");
            out.write("\n<!-- Filename: "+ii.fileName+" -->");
%>
            <a href="photo/<%=relPath%>" target="photo">
            <img src="thumb/100/<%=relPath%>" width="100" border="0"></a>
            </td><td><a href="show.jsp?q=<%=URLEncoder.encode(newQ,"UTF8")%>&o=<%=order%>">S</a><br/>
            <a href="selectImage.jsp?<%=stdParams%>&a=supp" target="suppwindow">
                <img border=0 src="addicon.gif" border="0"></a><br/>
            <a href="manage.jsp?q=<%=queryOrderNoMin%>&min=<%=totalCount%>">
                <img border=0 src="searchicon.gif" border="0"></a><br/>
            <font size="-4" color="#99CC99"><%=ii.value%></font><br/>
            <a href="deleteOne.jsp?<%=stdParams%>&go=<%=URLEncoder.encode(thisPage,"UTF-8")%>">
            <img border=0 src="<%=trashIcon%>" border="0"></a>
            </td><%

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

<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.  </font>
</BODY>
</HTML>
<%!

    public static String[] allDupIndicators = new String[] {"z", "y", "yz", "yy", "yzz", "yzy", "yyz","yyy", "yzzz", "yzzy"};

    public void addIfDupTags(Vector<Vector<ImageInfo>> groupedImages, Vector<ImageInfo> rowImages,
            Vector<String> foundDupIndicators) throws Exception {
        boolean hasDup = false;
        for (ImageInfo ii : rowImages) {
            for (String tag : ii.getTagNames()) {
                for (String possibleMatch : allDupIndicators) {
                    if (possibleMatch.equals(tag)) {
                        hasDup = true;
                        if (!foundDupIndicators.contains(tag)) {
                            foundDupIndicators.add(tag);
                        }
                    }
                }
            }
        }
        if (hasDup) {
            groupedImages.add(rowImages);
        }
    }

    public ImageInfo findImageByDupIndicator(Vector<ImageInfo> rowImages, String desired) throws Exception {
        if ("".equals(desired)) {
            for (ImageInfo ii : rowImages) {
                boolean hasDupIndicator = false;
                for (String tag  : ii.getTagNames()) {
                    for (String poss : allDupIndicators) {
                        if (poss.equals(tag)) {
                            hasDupIndicator = true;
                        }
                    }
                }
                if (!hasDupIndicator) {
                    return ii;
                }
            }

        }
        else {
            for (ImageInfo ii : rowImages) {
                for (String tag: ii.getTagNames()) {
                    if (desired.equals(tag)) {
                        return ii;
                    }
                }
            }
        }
        return null; //rowImages.firstElement();
    }


%>
