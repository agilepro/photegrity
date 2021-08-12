<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.GridData"
%><%@page import="com.purplehillsbooks.photegrity.TagInfo"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.NewsBunch"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="java.io.Writer"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String pageName = "delDups.jsp";

    GridData gData = (GridData) session.getAttribute("gData");
    if (gData==null)
    {
        gData = new GridData();
        session.setAttribute("gData", gData);
    }
    Hashtable selectedColumns = gData.getSelectedColumns();


    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String q = request.getParameter("q");
    if (q!=null)
    {
        throw new Exception("should not have a query parameter");
    }

    String check = UtilityMethods.defParam(request, "doubleCheck", null);
    boolean doit = check!=null;
    String action = UtilityMethods.reqParam(request, pageName, "action");
    boolean delDup = action.equals("Delete Dups");
    boolean consolidate = action.equals("Consolidate");

    String sourceCol = UtilityMethods.reqParam(request, pageName, "src");
    int colonPos = sourceCol.lastIndexOf(":");
    if (colonPos<0) {
        throw new Exception("the source column does not have a colon in it");
    }
    String sourceLoc = sourceCol.substring(0,colonPos);
    String sourcePatt = sourceCol.substring(colonPos+1);

    Vector grid = gData.getEntireGrid();
    Enumeration e = grid.elements();

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Delete from Grid</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=6>
<H1>Delete from Grid</H1>
</tr>
<tr><td colspan=6>
</tr>
<tr><td colspan=7><img src="bar.jpg"></td></tr>
<tr><td>Query</td><td><%HTMLWriter.writeHtml(out,gData.query);%></td></tr>
<tr><td>Source Col</td><td><%HTMLWriter.writeHtml(out,sourceCol);%></td></tr>
</table>
<hr><ul>
<%

    int lastNum = -999999;
    if (delDup)
    {
        while (e.hasMoreElements())
        {
            Vector row = (Vector) e.nextElement();
            ImageInfo ii = (ImageInfo)row.firstElement();
            int value = ii.value;
            if (value<gData.rangeTop)
            {
                continue;
            }
            if (value>gData.rangeBottom)
            {
                continue;
            }
            eliminateLocation(out, value, row, sourceCol, doit, selectedColumns);
        }
    }
    else if (consolidate) {
        String newLoc = UtilityMethods.reqParam(request, pageName, "newLoc");
        if(!newLoc.endsWith("/")) {
            throw new Exception ("the new location should end with slash: "+newLoc);
        }
        String newPatt = UtilityMethods.reqParam(request, pageName, "newPatt");
        String dupact = UtilityMethods.reqParam(request, pageName, "dupact");
        boolean delNew = "delNew".equals(dupact);
            out.write("<li>LOOPING "+sourceCol+" -> "+newLoc+newPatt);
            out.write("</li>");
        while (e.hasMoreElements()) {
            Vector row = (Vector) e.nextElement();
            ImageInfo ii = (ImageInfo)row.firstElement();
            int value = ii.value;
            if (value<gData.rangeTop) {
                continue;
            }
            if (value>gData.rangeBottom) {
                continue;
            }
            consolidateLocation(out, value, row, sourceCol, doit, selectedColumns, newLoc, newPatt, delNew);
        }
        if (doit) {
            NewsBunch.trackMovedFiles(sourceLoc, sourcePatt, newLoc, newPatt);
            out.write("<li>Tracked the moved files in News</li>");
        }
    }

    gData.reindex();
%>
<li><b>Finished</b>
</ul><hr>
<a href="main.jsp"><img src="home.gif"></a>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>
<%!

        public void consolidateLocation(Writer out, int lastNum, Vector row,
            String sourceCol, boolean doit, Hashtable selectedColumns,
            String newLoc, String newPatt, boolean delNew)
            throws Exception
        {
            String destCol = newLoc + newPatt;

            if (selectedColumns.get(sourceCol)==null)
            {
                throw new Exception("Source column ("+sourceCol+") is not selected, should be one of ("+selectedColumns.toString()+") ... is there a whitespace char at end?");
            }

            ImageInfo iiSrc = null;
            ImageInfo iiDest = null;

            Enumeration q = row.elements();
            int delGuard = row.size();
            while (q.hasMoreElements())
            {
                ImageInfo i3 = (ImageInfo)q.nextElement();
                String iLoc = i3.getPatternSymbol();
                //out.write("\n<li>looking for "+iLoc+" at "+destCol+"</li>");
                boolean isMarked = (selectedColumns.get(iLoc)!=null);
                if (!isMarked)
                {
                    continue;
                }

                if (iLoc.equals(sourceCol))
                {
                    iiSrc = i3;
                }
                if (iLoc.equals(destCol))
                {
                    iiDest = i3;
                }
            }


            if (iiSrc==null)
            {
                //no source images in this row, no problem, ignore this row
                return;
            }

            String msg = "*??????*";
            out.write("\n<li> ");
            out.write(Integer.toString(lastNum));
            out.write(" (");
            out.write(Integer.toString(row.size()));
            out.write("): ");
            if (iiDest!=null)
            {
                if (delNew)
                {
                    if (doit)
                    {
                        msg = "*DELETED SOURCE* ";
                        iiSrc.suppressImage();
                        row.remove(iiSrc);
                    }
                    else
                    {
                        msg = "*AVOIDED DELETE* ";
                    }
                    HTMLWriter.writeHtml(out, msg);
                    HTMLWriter.writeHtml(out, sourceCol);
                    out.write("</li>");
                    out.flush();
                    return;
                }

                if (doit)
                {
                    msg = "*OVERWRITE* ";
                    iiDest.suppressImage();
                    row.remove(iiDest);
                    iiSrc.moveImageToLoc(newLoc);
                    iiSrc.changePattern(newPatt);
                }
                else
                {
                    msg = "*AVOIDED OVERWRITE* ";
                }
            }

            else
            {
                if (doit)
                {
                    msg = "*MOVED* ";
                    iiSrc.moveImageToLoc(newLoc);
                    iiSrc.changePattern(newPatt);
                }
                else
                {
                    msg = "*AVOIDED MOVE* ";
                }
            }

            HTMLWriter.writeHtml(out, msg);
            HTMLWriter.writeHtml(out, sourceCol);
            out.write("</li>");
            out.flush();
        }



        public void eliminateLocation(Writer out, int lastNum, Vector row,
            String sourceCol, boolean doit, Hashtable selectedColumns)
            throws Exception
        {
            if (row.size()==0)
            {
                //silent in cases where there are no rows
                return;
            }
            out.write("\n<li> ");
            out.write(Integer.toString(lastNum));
            out.write(" (");
            out.write(Integer.toString(row.size()));
            out.write("): ");
            if (row.size()==1)
            {
                out.write("ONLY-ONE");
            }
            else
            {
                Enumeration q = row.elements();
                boolean found = false;
                int delGuard = row.size();
                while (q.hasMoreElements())
                {
                    ImageInfo i3 = (ImageInfo)q.nextElement();
                    String iLoc = i3.getPatternSymbol();

                    boolean isMarked = (selectedColumns.get(iLoc)!=null);
                    if (!isMarked)
                    {
                        continue;
                    }

                    out.write(" ("+iLoc+")  ");
                    if (iLoc.equals(sourceCol))
                    {
                        delGuard--;
                        if (delGuard<=0)
                        {
                            out.write("PRESERVED");
                        }
                        else if (doit)
                        {
                            out.write("DELETED");
                            i3.suppressImage();
                            row.remove(i3);
                        }
                        else
                        {
                            out.write("AVOIDED");
                        }
                        found = true;
                    }
                }
                if (!found)
                {
                    out.write("*NONE FOUND* "+sourceCol);
                }
            }
            out.write("</li>");
            out.flush();
        }



%>
