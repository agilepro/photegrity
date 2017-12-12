<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileWriter" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="java.util.regex.Pattern" %>
<%@page import="java.util.regex.Matcher" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.UtilityMethods"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }

    String query = UtilityMethods.reqParam(request, "replName.jsp", "q");
    if (query == null) {
        query="s(1)";
    }

    String source = UtilityMethods.reqParam(request, "replName.jsp", "s");
    if (source.length() == 0) {
        throw new Exception("page requires a 's' parameter with a non-null value");
    }
    String target = UtilityMethods.defParam(request, "t", "");
    session.setAttribute("formerSearchSource", source);
    session.setAttribute("formerSearchTarget", target);

    String dest = UtilityMethods.reqParam(request, "replName.jsp", "dest");

    boolean isRegEx = UtilityMethods.defParam(request, "regex", "no").equals("yes");
    boolean isTest  = UtilityMethods.defParam(request, "test",  "no").equals("yes");

    Vector copyImages = new Vector();
    copyImages.addAll(ImageInfo.imageQuery(query));
    Enumeration e2 = copyImages.elements();
    int count = 0;
    int num = 1;
%>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Repl Name</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=6>
<H1>Repl Name</H1>
Replace <%HTMLWriter.writeHtml(out, source);%>
with <%HTMLWriter.writeHtml(out, target);%> -
Regex:<%if (isRegEx) {out.write("yes");} else {out.write("no");}%> -
Testing:<%if (isTest) {out.write("yes");} else {out.write("no");}%>
<ul>


<%
    if (source.equals("?"))
    {
        while (e2.hasMoreElements()) {
            ImageInfo ii = (ImageInfo)e2.nextElement();
            if (ii == null) {
                throw new Exception ("null image file in selection");
            }
            String oldname = ii.fileName;
            //looking for XXXXXXXXXXXX-1.jpg
            int namelen = oldname.length();
            if (namelen<8)
            {
                continue;
            }
            char isDash = oldname.charAt(namelen-6);
            char isNum = oldname.charAt(namelen-5);
            if (isDash=='-' && isNum>='0' && isNum<='9')
            {
                String newName = oldname.substring(0,namelen-6) + ".jpg";
                File newFile = new File(ii.getFullPath(),newName);
                out.write("\n<li>");
                HTMLWriter.writeHtml(out, oldname);
                out.write(" --- ");
                HTMLWriter.writeHtml(out, newName);
                if (newFile.exists())
                {
                    out.write(" - ABORT, already exists");
                }
                else
                {
                    count++;
                    if (!isTest)
                    {
                        ii.renameFile(newName);
                    }
                }
            }

        }
    }
    else
    {
        while (e2.hasMoreElements()) {
            ImageInfo ii = (ImageInfo)e2.nextElement();
            if (ii == null) {
                throw new Exception ("null image file in selection");
            }
            String oldname = ii.fileName;
            if (isRegEx)
            {
                Pattern p = Pattern.compile(source);
                Matcher m = p.matcher(oldname);
                String newName = m.replaceAll(target);
                if (!newName.equals(oldname))
                {
                    out.write("\n<li>");
                    HTMLWriter.writeHtml(out, oldname);
                    out.write(" --- ");
                    HTMLWriter.writeHtml(out, newName);
                    if (!isTest)
                    {
                        ii.renameFile(newName);
                    }
                }
            }
            else
            {
                int pos = oldname.indexOf(source);
                if (pos >= 0)
                {
                    String newName = oldname.substring(0,pos) + target
                           + oldname.substring(pos+source.length());
                    count++;
                    out.write("\n<li>");
                    HTMLWriter.writeHtml(out, oldname);
                    out.write(" --- ");
                    HTMLWriter.writeHtml(out, newName);
                    if (!isTest)
                    {
                        ii.renameFile(newName);
                    }
                }
            }

        }
    }

    if (dest == null)
    {
        dest = "selection.jsp?msg=Modified%20"+count+"%20Filenames";
    }
%>
</ul>
</body>
</html>