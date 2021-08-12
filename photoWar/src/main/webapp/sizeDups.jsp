<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Vector" %>
<%@page import="com.purplehillsbooks.photegrity.DiskMgr" %>
<%@page import="com.purplehillsbooks.photegrity.ImageInfo" %>
<%@page import="com.purplehillsbooks.photegrity.PatternInfo" %>
<%@page import="com.purplehillsbooks.photegrity.TagInfo" %>
<%@page import="com.purplehillsbooks.photegrity.UtilityMethods" %>

<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    int thumbsize = UtilityMethods.getSessionInt(session, "thumbsize", 100);

    int startSize = UtilityMethods.defParamInt(request, "p", -1);
    boolean allNumbers = (request.getParameter("all") != null);
    String allParam = "";
    if (allNumbers) {
        allParam = "&all=yes";
    }
    boolean showPict = (request.getParameter("pict")!=null);
    String pictParam = "";
    if (showPict) {
        pictParam = "&pict=yes";
    }

    Vector images = ImageInfo.getImagesBySize();
    Enumeration e = images.elements();

%>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD><TITLE>Size Duplicates</TITLE></HEAD>
<BODY BGCOLOR="#FDF5E6">
<table>
<tr><td colspan=6>
<H1>Size Duplicates</H1>
</tr>
<tr><td colspan=6>
<table><tr><td>

<%  if (showPict) { %>
    <a href="sizeDups.jsp?p=<%=startSize%><%=allParam%>">Without-Images</a>,
<%  } else { %>
    <a href="sizeDups.jsp?p=<%=startSize%><%=allParam%>&pict=yes">With-Images</a>,
<%  }  %>

<%  if (allNumbers) { %>
    <a href="sizeDups.jsp?p=<%=startSize%><%=pictParam%>">Match-Numbers</a>,
<%  } else { %>
    <a href="sizeDups.jsp?p=<%=startSize%><%=pictParam%>&all=all">All-Numbers</a>,
<%  }  %>
    <a href="main.jsp"><img src="home.gif"></a>
</td></tr></table>
</tr>
<%
    boolean newGroup = true;
    int lastSize = -1;
    int lastNum = 0;
    int count = 0;
    Vector bunch = new Vector();
    ImageInfo lastImage = null;
    %><%
    while (e.hasMoreElements()) {

        ImageInfo ii = (ImageInfo) e.nextElement();
        // skip everything up to the estimated startSize.
        if (ii.fileSize > startSize) {
            continue;
        }

        // first image can not be checked yet.
        if (lastImage == null) {
            lastImage = ii;
            continue;
        }


    %><%
        if (lastSize == ii.fileSize) {
            if (lastImage.value == ii.value || allNumbers) {
                if (newGroup) {
                    bunch.addElement(lastImage);
                    newGroup = false;
                }
                bunch.addElement(ii);
            }
        }
    %><%
        else {
            if (!newGroup) {
                Enumeration buncher = bunch.elements();
%>
        <tr bgcolor="#FFFFFF"><td colspan=4><%= lastSize %></td></tr>
<%
                while (buncher.hasMoreElements()) {
                    ImageInfo jj = (ImageInfo) buncher.nextElement();
                    String viewPath = "photo/"+jj.getRelPath();
                    if (showPict) {
%>      <tr>
        <td width="100">
            <a href="photo/<%=jj.getRelPath()%>" target="photo" borderwidth="0">
            <img src="thumb/<%=thumbsize%>/<%=jj.getRelPath()%>" width="<%=thumbsize%>"></a></td>
        <td width="800">
            <a href="pattern.jsp?g=<%= URLEncoder.encode(jj.getPattern(),"UTF8") %>"><%= jj.getPattern() %></a>
            <%= jj.value %>
            <a href="<%=viewPath%>" target="photo">
                <%= jj.tail %></a><br>
            <%= jj.pp.diskMgr.diskName %><br>
            <a href="selectImage.jsp?d=<%= jj.pp.diskMgr.diskName %>&f=<%= URLEncoder.encode(jj.fileName,"UTF8") %>&p=<%= URLEncoder.encode(jj.getRelPath()) %>&a=supp" target="suppwindow">
                <img border="0" src="addicon.gif"></a><%= jj.getRelPath() %>
            </td></tr>
<%                  }
                    else {
%>
        <tr>
        <td><a href="pattern.jsp?g=<%= URLEncoder.encode(jj.getPattern(),"UTF8") %>"><%= jj.getPattern() %></a>
            <%= jj.value %>
            <a href="<%=viewPath%>" target="photo">
                <%= jj.tail %></a></td>
            <td bgcolor="#CCCCFF"><%= jj.pp.diskMgr.diskName %></td>
            <td><a href="selectImage.jsp?d=<%= jj.pp.diskMgr.diskName %>&f=<%= URLEncoder.encode(jj.fileName,"UTF8") %>&p=<%= URLEncoder.encode(jj.getRelPath(),"UTF8") %>&a=supp" target="suppwindow">
                <img border=0 src="addicon.gif"></a></td>
            <td><%= jj.getRelPath() %></td>
            </tr>
<%
                    }
                }
                if (++count > 30) {
                    break;
                }
            }
            newGroup = true;
            bunch.clear();
        }

        lastSize = ii.fileSize;
        lastImage = ii;
    }
%>
</table>
<br>
<a href="sizeDups.jsp?p=<%=lastSize%>&all=all<%=allParam%><%=pictParam%>">Next-Page</a>
<a href="main.jsp"><img src="home.gif"></a>
<%
    long duration = System.currentTimeMillis() - starttime;
%>
    <font color="#BBBBBB">page generated in <%=duration%>ms.</font>
</BODY>
</HTML>