<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.Writer" %>
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
    String diskName = request.getParameter("n");
    if (diskName == null) {
        throw new Exception("page required a parameter 'n' with the name of the disk to clean");
    }
    diskName = diskName.toLowerCase();
    String dest = request.getParameter("dest");
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Cleaning '<%= diskName %>'</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<H1>Cleaning '<%= diskName %>' Empty Directories & JPG extensions</H1>
<ul>
<%
    out.flush();
    Vector v = new Vector();

    DiskMgr mgr = DiskMgr.getDiskMgr(diskName);
    recursiveDelDirs(mgr.extraPath, out);
%>
</ul>
<hr>
<a href="main.jsp"><img src="home.gif"></a> &nbsp;
<a href="diskinfo.jsp?n=<%=diskName%>">Info</a> &nbsp;
<%
if (dest != null) {
%>
<script language="javascript">
    document.location = "<%=dest%>";
</script>
<%
}
%>
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
                if (startDir.endsWith(".jpeg") || startDir.endsWith(".JPEG")) {
                    File newName = new File(startDir.substring(0,startDir.length()-4)+"jpg");
                    out.write("\n<li>JPEG extension converted: ");
                    HTMLWriter.writeHtml(out, newName.toString());
                    out.flush();
                    f1.renameTo(newName);
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
            for (int i=0; i<flist.length; i++) {
                String thisName = startDir+"/"+flist[i];
                if ("sm1200".equalsIgnoreCase(flist[i])) {
                    out.write("\n<li>");
                    HTMLWriter.writeHtml(out, startDir);
                    out.write(" has a sm1200 directory!");
                    out.flush();
                    promoteSmallFiles(f1, out);
                }
                recursiveDelDirs(thisName, out);
            }

            flist = f1.list();
            if  (flist.length==0) {
                out.write("\n<li>");
                HTMLWriter.writeHtml(out, startDir);
                out.write(" is empty, so REMOVED!");
                out.flush();
                f1.delete();
            }
        }
        catch (Exception e) {
            throw new Exception("Unable to scan directory ("+startDir+")",e);
        }
    }


    public void promoteSmallFiles(File f1, Writer out) throws Exception {

        File sm1200 = new File(f1, "sm1200");
        if (!sm1200.exists()) {
            throw new Exception("promoteSmallFiles got passed a folder that does not have a sm1200 folder in it!");
        }

        String[] flist = sm1200.list();
        for (String childName : flist) {

            File childFile = new File (sm1200, childName);
            if (childFile.isDirectory()) {
                continue;
            }
            if (childFile.length()>200000) {
                //large files in the sub directory should be left alone
                out.write("\n<li>");
                HTMLWriter.writeHtml(out, childFile.toString());
                out.write(" is ");
                out.write( Integer.toString(((int)childFile.length()/1000)));
                out.write("K so not moved!");
                out.flush();
                continue;
            }
            File parentFile = new File (f1, childName);
            if (parentFile.exists()) {
                if (parentFile.length()<200000) {

                    //delete the child if parent is < 200K (unnecessary shrink)

                    childFile.delete();
                    out.write("\n<li>");
                    HTMLWriter.writeHtml(out, childFile.toString());
                    out.write(" parent is small enough, no need to shrink, child deleted!");
                    out.flush();
                    continue;
                }
                if (childFile.length() >= parentFile.length()) {

                    //or child is bigger than parent (accidental expansion)

                    childFile.delete();
                    out.write("\n<li>");
                    HTMLWriter.writeHtml(out, childFile.toString());
                    out.write(" is bigger than parent, so child deleted!");
                    out.flush();
                    continue;
                }
                parentFile.delete();
            }
            copyFile(childFile, parentFile);
            childFile.delete();
            out.write("\n<li>");
            HTMLWriter.writeHtml(out, childFile.toString());
            out.write(" promoted over the original!");
            out.flush();
        }
    }


    public static void copyFile(File source, File dest) throws Exception
    {
        DiskMgr.copyFile(source, dest);
    }


%>
