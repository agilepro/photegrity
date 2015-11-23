<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.Thumb" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector"
%><%@page import="org.workcast.streams.HTMLWriter"
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

    String check = request.getParameter("doubleCheck");
    if (check == null) {
        throw new Exception("Back up to the previous page, and check the checkbox if you really want to shrink this set of images.");
    }


%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Shrink <%HTMLWriter.writeHtml(out,query);%></TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<%

    boolean workToDo = true;
    int lastNum = 0;
    long totalBefore = 0;
    long totalAfter = 0;

    synchronized (toDoList) {
        if (toDoList.size()>0) {
            workToDo = false;
        }
        toDoList.add(query);
    }

    try {
        while (workToDo)
        {
            Vector groupImages = new Vector();
            groupImages.addAll(ImageInfo.imageQuery(query));
            Enumeration e = groupImages.elements();
            int recordCount = groupImages.size();

            %>
            <H1>Shrink <%=recordCount%></H1>
            <table>
            <tr><td><%HTMLWriter.writeHtml(out,query);%></td></tr>
            </table>
            <hr><ol>
            <%



            while (e.hasMoreElements()) {
                ImageInfo ii = (ImageInfo)e.nextElement();
                if (ii == null) {
                    throw new Exception ("null image file where lastnum="+lastNum);
                }
                out.write("\n<li> ");
                HTMLWriter.writeHtml(out, ii.getFullPath());
                HTMLWriter.writeHtml(out, ii.fileName);
                out.write("   ");

                //skip the file if it is small enough (190K)
                if (ii.fileSize<190000) {
                    out.write( "skipped</li>" );
                    continue;
                }

                out.write(Integer.toString(ii.fileSize));
                int sizeBefore = ii.fileSize;
                totalBefore += sizeBefore;
                out.flush();
                Thumb.shrinkFile(ii);
                long percentShrink = (((long)ii.fileSize)*100)/sizeBefore;
                out.write(" -- ");
                out.write(Long.toString(percentShrink));
                out.write("% --> ");
                out.write(Integer.toString(ii.fileSize));
                totalAfter += ii.fileSize;
                out.write( "</li>" );
            }
            synchronized (toDoList) {
                toDoList.remove(0);
                if (toDoList.size()>0) {
                    query = (String) toDoList.get(0);
                }
                else {
                    workToDo = false;
                }
            }
            %>
            </ol><hr>
            <%
        }
    }
    catch (Exception e) {
        //something has to clean this out on failure
        toDoList = new Vector();
        throw e;
    }
    catch (java.lang.OutOfMemoryError e2) {
        //something has to clean this out on failure
        toDoList = new Vector();
        throw e2;
    }

    if (totalBefore>0) {
        long duration = System.currentTimeMillis() - starttime;
        long diffamt = totalBefore-totalAfter;
        %>
        <b>All Shrunk</b><%=totalBefore/1000%>K -- <%=(int)((totalAfter*100)/totalBefore)%> --> <%=totalAfter/1000%>K
            Saved <%=diffamt/1000%>Kbytes.<br>

            <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
        <%
    }
    else {
        %>
        <b>None Shrunk</b>  look for other page has <%=toDoList.size()%> more to complete<br>

        <%
            for (int j=0; j<toDoList.size(); j++) {
                %>Query: <%=toDoList.get(j)%><br><%
            }
    }
%>
</BODY>
</HTML>
<%!

    static Vector toDoList = new Vector();

%>
