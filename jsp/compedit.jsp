<%@page errorPage="error.jsp" %>
<%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1" %>
<%@page import="bogus.DiskMgr" %>
<%@page import="bogus.TagInfo" %>
<%@page import="bogus.ImageInfo" %>
<%@page import="bogus.MarkedVector" %>
<%@page import="bogus.PatternInfo" %>
<%@page import="bogus.UtilityMethods" %>
<%@page import="java.io.File" %>
<%@page import="java.io.FileReader" %>
<%@page import="java.io.LineNumberReader" %>
<%@page import="java.net.URLEncoder" %>
<%@page import="java.util.Enumeration" %>
<%@page import="java.util.Hashtable" %>
<%@page import="java.util.Vector" %>
<%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }



    int set = UtilityMethods.defParamInt(request, "set", 1);
    int pos = UtilityMethods.defParamInt(request, "pos", -1);
    if (pos==-1) {
        throw new Exception("error, you must have a specific position in the selection to edit ...");
    }

    int mina = UtilityMethods.defParamInt(request, "mina", 0);
    int minb = UtilityMethods.defParamInt(request, "minb", 0);
    String op = UtilityMethods.defParam(request, "op", "down");

    String go = UtilityMethods.defParam(request, "go", "compare.jsp?mina="+mina+"&minb="+minb);


    String lastPath = "";
    Hashtable groupMap = new Hashtable();
    MarkedVector group = ImageInfo.memory[set-1];
    if (pos < 0) {
        throw new Exception("Position in selection set is negative");
    }
    if (pos > group.size()) {
        throw new Exception("Position in selection set is too large: "+pos+" out of "+group.size());
    }


    ImageInfo dummy = ImageInfo.getNullImage();

    boolean found = true;

    if (op.equals("insert")) {
        group.insertElementAt(dummy, pos);
    }
    else if (op.equals("remove")) {
        group.removeElementAt(pos);
    }
    else if (op.equals("down")) {
        if (pos+1 >= group.size()) {
            throw new Exception("Can't move down past the end of the list od "+pos);
        }
        ImageInfo temp = (ImageInfo) group.elementAt(pos);
        group.removeElementAt(pos);
        group.insertElementAt( temp, pos+1 );
    }
    else if (op.equals("up")) {
        if (pos < 1) {
            throw new Exception("Can't move up past the beginning of the list");
        }
        ImageInfo temp = (ImageInfo) group.elementAt(pos);
        int dest = group.getMarkPosition();
        if (dest>=pos || dest<0) {
            dest = pos-1;
        }
        group.removeElementAt(pos);
        group.insertElementAt( temp, dest );
    }
    else if (op.equals("setMark")) {
        int newMark = UtilityMethods.defParamInt(request, "mark", -1);
        group.setMarkPosition(newMark);
    }
    else if (op.equals("chooseA")) {
        session.setAttribute("columnA", new Integer(set));
    }
    else if (op.equals("chooseB")) {
        session.setAttribute("columnB", new Integer(set));
    }
    else
    {
        found = false;
    }

    int setNo = 0;
    while (!found && setNo<ImageInfo.MEMORY_SIZE)
    {
        setNo++;
        if (op.equals(Integer.toString(setNo)))
        {
            found=true;
            doMove(pos, setNo-1, group);
        }
    }
    if (!found)
    {
        throw new Exception("unrecognized operation op="+op);
    }

    response.sendRedirect(go);
%>
<%!public void doMove(int pos, int dest, MarkedVector group)
    throws Exception
{
    ImageInfo temp = (ImageInfo) group.elementAt(pos);
    group.removeElementAt(pos);
    ImageInfo.memory[dest].insertAtMark(temp);
}%>
<%@ include file="functions.jsp"%>
