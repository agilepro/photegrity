<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.GridData"
%><%@page import="com.purplehillsbooks.photegrity.TagInfo"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
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
    String unneededQuery = request.getParameter("q");
    if (unneededQuery!=null)
    {
        throw new Exception("got a query but we don't need one");
    }

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

    int rowMax = 6;

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
    String lastPath = "";
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8");
    String queryOrderPart = queryOrderNoMin+"&r="+r;
    int recordCount = rowMap.size();

    String thisPage = "showMap.jsp?r="+r;

///////////////////////////////////////

    int rowNum = -1;
    int colNum = 9999;
    int nextStart = 0;
    int lastSize = -1;


%>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Show <%= r %> / <%= recordCount %></TITLE></HEAD>
<body BGCOLOR="#FDF5FF">




</bod>
</html>