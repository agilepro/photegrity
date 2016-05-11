<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileInputStream"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.FileWriter"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.io.Writer"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Properties"
%><%@page import="java.util.Vector"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    ImageInfo.garbageCollect();

    DiskMgr.initPhotoServer(session.getServletContext());

    ImageInfo.garbageCollect();

%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Clear Cache</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Clear Cache</H1>
<ul>
<li>Cache has been cleared.
<%
    out.flush();
    String doRefreshAll = request.getParameter("refreshAll");
    if (doRefreshAll!=null) {
        Hashtable<String, DiskMgr> ht = DiskMgr.getDiskList();
        Vector<String> copyOfNames = new Vector<String>();
        for (String key : ht.keySet()) {
            copyOfNames.add(key);
            out.write("\n<li>preparing "+key);
        }
        for (String key : copyOfNames) {
            out.write("\n<li>clearing out "+key);
            out.flush();
            out.write("\n<ul>");
            DiskMgr mgr = DiskMgr.getDiskMgr(key);
            recursiveDelDirs(mgr.extraPath, out);
            mgr.loadDiskImages(out);
            out.write("\n</ul>");
            ImageInfo.garbageCollect();
        }
    }

%>

</ul>
<hr>
<a href="main.jsp"><img src="home.gif"></a>

<script language="javascript">
    //document.location = "main.jsp";
</script>

</BODY>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</HTML>

<%!

    public
    void
    recursiveDelDirs(String startDir, Writer out)
        throws Exception
    {
        try {
            File f1 = new File(startDir);
            if (!f1.exists()) {
                out.write("\n<li>Strangely, the file '");
                HTMLWriter.writeHtml(out, startDir);
                out.write("' does not exist.  This is an error.");
                return;
            }

            if (!f1.isDirectory()) {
                if (startDir.endsWith(".-.jpg")) {
                    //trashcan case, delete this file
                    out.write("\n<li>DELETED: ");
                    HTMLWriter.writeHtml(out, startDir);
                    out.flush();
                    f1.delete();
                    return;
                }
                if (startDir.endsWith(".jpg")) {
                    //file name OK so just return
                    return;
                }

                int lenMinus3 = startDir.length()-3;
                String lastThree = startDir.substring(lenMinus3);
                if (lastThree.equalsIgnoreCase("jpg")) {
                    File newName = new File(startDir.substring(0,lenMinus3)+"jpg");
                    out.write("\n<li>JPG extension lowered: ");
                    HTMLWriter.writeHtml(out, newName.toString());
                    out.flush();
                    f1.renameTo(newName);
                }
                return;
            }
            String[] flist = f1.list();
            if  (flist.length==0) {
                out.write("\n<li>");
                HTMLWriter.writeHtml(out, startDir);
                out.write(" is empty, so REMOVED!");
                out.flush();
                f1.delete();
            }
            else for (int i=0; i<flist.length; i++) {
                String thisName = startDir+"/"+flist[i];
                recursiveDelDirs(thisName, out);
            }
        }
        catch (Exception e) {
            throw new Exception2("Unable to scan directory ("+startDir+")",e);
        }
    }

    public
    void
    checkFileExtensions(String startDir, Writer out)
        throws Exception
    {
        try {
            File f1 = new File(startDir);
            if (!f1.exists()) {
                out.write("\n<li>Strangely, the file '");
                HTMLWriter.writeHtml(out, startDir);
                out.write("' does not exist.  This is an error.");
                return;
            }

            if (!f1.isDirectory()) {
                return;
            }
            String[] flist = f1.list();
            if  (flist.length==0) {
                out.write("\n<li>");
                HTMLWriter.writeHtml(out, startDir);
                out.write(" is empty, so REMOVED!");
                out.flush();
                f1.delete();
            }
            else for (int i=0; i<flist.length; i++) {
                String thisName = startDir+"/"+flist[i];
                recursiveDelDirs(thisName, out);
            }
        }
        catch (Exception e) {
            throw new Exception2("Unable to scan directory ("+startDir+")",e);
        }
    }


%>