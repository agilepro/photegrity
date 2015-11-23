<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DOMUtils"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Set"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Document"
%><%@page import="org.w3c.dom.Element"
%><%
    request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String pageName = "queryManip.jsp";

    if (session.getAttribute("userName") == null) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%
        return;
    }
    String query = UtilityMethods.reqParam(request, pageName, "q");
    String order = UtilityMethods.defParam(request, "o", "name");
    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    String listName = "";
    String newGroup = UtilityMethods.getSessionString(session, "newGroup", "");

    Vector groupImages = new Vector();
    groupImages.addAll(ImageInfo.imageQuery(query));

    String extras = "&o="+order+"&min="+dispMin;
    String thisURL = "queryManip.jsp?q="+URLEncoder.encode(query,"UTF8")+extras;

    String setHangOutURL = "setHangoutAction.jsp?go="+URLEncoder.encode(thisURL,"UTF8");


    //session defaults
    String moveDest = (String) session.getAttribute("moveDest");
    if (moveDest == null) {
        moveDest = "";
    }
    String np = (String) session.getAttribute("np");
    if (np == null) {
        np = "";
    }
    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec == null) {
        destVec = new Vector();
    }
    int destSize = destVec.size();
    String queryOrder = URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+dispMin;

    String lastPath = "";
    Hashtable groupMap = new Hashtable();
    Hashtable diskMap = new Hashtable();
    pathCount = new HashCounter();
    allPaths = new Hashtable<String,String>();
    ImageInfo.sortImages(groupImages, order);
    int recordCount = groupImages.size();
    Enumeration e2 = groupImages.elements();
    long totalSize = 0;
    int totalCount = 0;
    while (e2.hasMoreElements()) {
        ImageInfo ii = (ImageInfo)e2.nextElement();
        String location = ii.diskMgr.diskName+":"+ii.getRelativePath();
        allPaths.put(location, ii.getFullPath());
        pathCount.increment(location);
        totalSize += ii.fileSize;
        totalCount++;
    }

    Document e_html = DOMUtils.createDocument("html");
    Element  e_head = DOMUtils.createChildElement(e_html, e_html.getDocumentElement(), "head");
    Element  e_title = DOMUtils.createChildElement(e_html, e_head, "title", "M "+query);
    Element  e_body9 = DOMUtils.createChildElement(e_html, e_html.getDocumentElement(), "body");
    e_body9.setAttribute("BGCOLOR", "#FDF5E6");
    Element  e_table9 = DOMUtils.createChildElement(e_html, e_body9,   "table");
    e_table9.setAttribute("width", "800");
    Element  e_tr9    = DOMUtils.createChildElement(e_html, e_table9, "tr");
    Element  e_body   = DOMUtils.createChildElement(e_html, e_tr9,    "td");

    //Row 1
    Element e_tr1 = topLine(e_html, e_body, groupImages.size(), query, queryOrder, "queryManip");


    Element e_table1 = DOMUtils.createChildElement(e_html, e_body,   "hr");

    e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
    e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");
    Element e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    Element e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", "Main ");
    e_a.setAttribute("href", "main.jsp");
    long avgsize = 0;
    if (totalCount>0) {
        avgsize = totalSize/totalCount;
    }
    e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", " 1 ");
    e_a.setAttribute("href", "sel.jsp?set=1");
    e_a.setAttribute("target", "sel1");
    e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", " 2 ");
    e_a.setAttribute("href", "sel.jsp?set=2");
    e_a.setAttribute("target", "sel2");
    e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", " 3 ");
    e_a.setAttribute("href", "sel.jsp?set=3");
    e_a.setAttribute("target", "sel3");
    e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", " 4 ");
    e_a.setAttribute("href", "sel.jsp?set=4");
    e_a.setAttribute("target", "sel4");
    e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", " 5 ");
    e_a.setAttribute("href", "sel.jsp?set=5");
    e_a.setAttribute("target", "sel5");

    e_a = DOMUtils.createChildElement(e_html, e_td1, "i", Long.toString(totalCount));
    DOMUtils.addChildText(e_html, e_a, " files, avg ");
    Element sizeHolder = e_a;
    if (avgsize>200000) {
        sizeHolder = DOMUtils.createChildElement(e_html, sizeHolder, "b");
        sizeHolder = DOMUtils.createChildElement(e_html, sizeHolder, "font");
        sizeHolder.setAttribute("color", "red");
    }
    DOMUtils.addChildText(e_html, sizeHolder, Long.toString(avgsize));
    DOMUtils.addChildText(e_html, e_a, " bytes, ");
    DOMUtils.addChildText(e_html, e_a, Long.toString(totalSize));
    DOMUtils.addChildText(e_html, e_a, " bytes total");

    e_a   = DOMUtils.createChildElement(e_html, e_td1, "a", "Set Hang Out");
    e_a.setAttribute("href", setHangOutURL);




    e_a = DOMUtils.createChildElement(e_html, e_td1, "hr", "");



    e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");
    Element e_form    = DOMUtils.createChildElement(e_html, e_tr1, "form");
    e_td1 = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "move.jsp");
    e_form.setAttribute("name", "moveForm");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "submit", "op", "Move "+recordCount);
    DOMUtils.addChildText(e_html, e_td1, " to ");
    Element e_input = inputTag(e_html, e_td1, "text", "dest",   moveDest);
    e_input.setAttribute("size", "50");
    e_input = inputTag(e_html, e_td1, "checkbox", "news", "yes");
    e_input.setAttribute("checked", "checked");
    DOMUtils.addChildText(e_html, e_td1, " Move News ");

    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_td1   = DOMUtils.createChildElement(e_html, e_tr1,    "td");

    Set<String> keys = allPaths.keySet();
    if (keys.size()>0) {
        assignValue(e_html, e_td1, "moveForm.dest.value", keys.iterator().next());
    }
    for(int i=0; i<destSize; i++) {
        assignValue(e_html, e_td1, "moveForm.dest.value", destVec.elementAt(i));
    }


    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_form  = DOMUtils.createChildElement(e_html, e_tr1, "form");
    e_td1   = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "changeSelection.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "hidden", "dest",   thisURL);
    inputTag(e_html, e_td1, "submit", "op", "Change "+recordCount);
    DOMUtils.addChildText(e_html, e_td1, " pattern from ");
    inputTag(e_html, e_td1, "text", "p1",   "");
    DOMUtils.addChildText(e_html, e_td1, " to ");
    inputTag(e_html, e_td1, "text", "p2",   "");


    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_form  = DOMUtils.createChildElement(e_html, e_tr1, "form");
    e_td1   = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "renumberSelection.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "hidden", "dest",   thisURL);
    inputTag(e_html, e_td1, "submit", "op", "Renumber "+recordCount);
    DOMUtils.addChildText(e_html, e_td1, " new pattern ");
    inputTag(e_html, e_td1, "text", "np",   np);

    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_form  = DOMUtils.createChildElement(e_html, e_tr1, "form");
    e_td1   = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "insertGroupSelection.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "hidden", "dest",   thisURL);
    inputTag(e_html, e_td1, "submit", "op", "Insert Tag "+recordCount);
    DOMUtils.addChildText(e_html, e_td1, " == ");
    inputTag(e_html, e_td1, "text", "grp",   newGroup);


    String formerSearchSource = UtilityMethods.getSessionString(session, "formerSearchSource", "");
    String formerSearchTarget = UtilityMethods.getSessionString(session, "formerSearchTarget", "");

    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_form  = DOMUtils.createChildElement(e_html, e_tr1, "form");
    e_td1   = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "replName.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "hidden", "dest",   thisURL);
    inputTag(e_html, e_td1, "submit", "op", "Replace");
    inputTag(e_html, e_td1, "text", "s",   formerSearchSource);
    DOMUtils.addChildText(e_html, e_td1, " with ");
    inputTag(e_html, e_td1, "text", "t",   formerSearchTarget);
    inputTag(e_html, e_td1, "checkbox", "regex",   "yes");
    DOMUtils.addChildText(e_html, e_td1, " RegEx - ");
    inputTag(e_html, e_td1, "checkbox", "test",   "yes");
    DOMUtils.addChildText(e_html, e_td1, " Test Only");

    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    Element e_td2   = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    Element e_table2 = DOMUtils.createChildElement(e_html, e_td2,    "table");
    Element e_tr2   = DOMUtils.createChildElement(e_html, e_table2, "tr");

    e_form  = DOMUtils.createChildElement(e_html, e_tr2, "form");
    e_td1   = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "replName.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "hidden", "dest",   thisURL);
    inputTag(e_html, e_td1, "submit", "op", "Remove Hyphen Single Digit at End");
    inputTag(e_html, e_td1, "hidden", "s",   "-\\d.jpg");
    inputTag(e_html, e_td1, "hidden", "t",   ".jpg");
    inputTag(e_html, e_td1, "hidden", "regex",   "yes");
    inputTag(e_html, e_td1, "hidden", "test",   "no");

    e_form  = DOMUtils.createChildElement(e_html, e_tr2, "form");
    e_td1   = DOMUtils.createChildElement(e_html, e_form,    "td");
    e_form.setAttribute("action", "trimPattern.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_td1, "hidden", "q",   query);
    inputTag(e_html, e_td1, "hidden", "dest",   thisURL);
    inputTag(e_html, e_td1, "submit", "op", "Trim Patterns");
    inputTag(e_html, e_td1, "hidden", "test",   "no");


    e_tr1   = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_td1   = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_form  = DOMUtils.createChildElement(e_html, e_td1, "form");
    e_form.setAttribute("action", "saveSelection2.jsp");
    e_form.setAttribute("method", "get");
    e_form.setAttribute("target", "_blank");
    inputTag(e_html, e_form, "hidden", "q",   query);
    inputTag(e_html, e_form, "hidden", "dest",   thisURL);
    DOMUtils.addChildText(e_html, e_form, "File: ");
    inputTag(e_html, e_form, "text", "list",   listName);
    inputTag(e_html, e_form, "submit", "op", "Save");
    inputTag(e_html, e_form, "submit", "op", "Load");
    inputTag(e_html, e_form, "submit", "op", "Clear");

    e_table1 = DOMUtils.createChildElement(e_html, e_body,   "hr");


    e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
    e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");
    for (int i=1; i<=3; i++) {
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
        e_form    = DOMUtils.createChildElement(e_html, e_td1, "form");
        e_form.setAttribute("action", "selectQuery.jsp");
        e_form.setAttribute("method", "get");
        inputTag(e_html, e_form, "hidden", "o",   order);
        inputTag(e_html, e_form, "hidden", "q",   query);
        inputTag(e_html, e_form, "hidden", "set", Integer.toString(i));
        inputTag(e_html, e_form, "submit", "op", "Select "+i);
        inputTag(e_html, e_form, "hidden", "dest", thisURL);

        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
        e_form    = DOMUtils.createChildElement(e_html, e_td1, "form");
        e_form.setAttribute("action", "clearSelection.jsp");
        e_form.setAttribute("method", "get");
        inputTag(e_html, e_form, "hidden", "set", Integer.toString(i));
        inputTag(e_html, e_form, "submit", "op", "Clear "+i);
        inputTag(e_html, e_form, "hidden", "dest", thisURL);
    }

    e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
    Enumeration ep = HashCounter.sort(allPaths.keys());

    Hashtable alreadyDone = new Hashtable();
    while (ep.hasMoreElements()) {
        String loc = (String) ep.nextElement();
        loc = loc.substring(0, loc.length()-1 );
        String locp = (String) allPaths.get(loc);
        int start = 0;
        int lastStart=0;
        int lastPos=0;
        boolean atLeastOne = false;
        while (start<loc.length()) {
            int nextPos = loc.length();
            int tPos = loc.indexOf("/", start);
            if (tPos > -1 && tPos < nextPos) {
                nextPos = tPos;
            }
            tPos = loc.indexOf(":", start);
            if (tPos > -1 && tPos < nextPos) {
                nextPos = tPos;
            }
            tPos = loc.indexOf(".", start);
            if (tPos > -1 && tPos < nextPos) {
                nextPos = tPos;
            }
            lastStart = start;
            lastPos = nextPos;
            if (detail(e_html, e_table1, query, extras, loc, start, nextPos, alreadyDone, false)) {
                atLeastOne = true;
            }
            start = nextPos+1;
        }
        if (!atLeastOne) {
            detail(e_html, e_table1, query, extras, loc, lastStart, lastPos, alreadyDone, true);
        }

    }


    breakOutQuery(query, e_html, e_body, extras);
    DOMUtils.writeDom(e_html, out);
%>
<%!
    Hashtable<String,String> allPaths;
    HashCounter pathCount;

    public boolean detail(Document e_html, Element e_table1, String query, String extras,
                       String loc, int slashPos, int dotPos, Hashtable alreadyDone, boolean force)
        throws Exception
    {
        String firstSegment = loc.substring(0,slashPos);
        if (dotPos<slashPos) {
            dotPos = loc.length();
        }
        String midSegment   = loc.substring(slashPos, dotPos);
        if (alreadyDone.get(midSegment) != null && !force) {
            return false;
        }
        alreadyDone.put(midSegment, midSegment);
        if (alreadyDone.get(midSegment) == null) {
            throw new Exception("huh? midSegment="+midSegment);
        }
        String lastSegment  = null;
        if (dotPos<loc.length()) {
            lastSegment = loc.substring(dotPos);
        }
        Integer cnt = (Integer) pathCount.get(loc+"/");
        if (cnt==null) {
            //throw new Exception("for some reason the loc does not work: "+loc+", slashPos="+slashPos+", dotPOS="+dotPos);
            cnt = new Integer(-1);
        }
        Element e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");
        Element e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
        //e_td1.setAttribute("width", "300");
        e_td1.appendChild(e_html.createTextNode(firstSegment));
        Element e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a", midSegment);
        String queryExt = query + "g("+midSegment.toLowerCase()+")";
        e_a.setAttribute("href", "group.jsp?g="+URLEncoder.encode(midSegment.toLowerCase(), "UTF8"));
        if (lastSegment != null) {
            e_td1.appendChild(e_html.createTextNode(lastSegment));
        }
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td");
        e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a", "S");
        e_a.setAttribute("href", "show.jsp?q="+URLEncoder.encode(queryExt, "UTF8")+extras);
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td");
        e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a", "T");
        e_a.setAttribute("href", "xgroups.jsp?q="+URLEncoder.encode(queryExt, "UTF8")+extras);
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td");
        e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a", "P");
        e_a.setAttribute("href", "allPatts.jsp?q="+URLEncoder.encode(queryExt, "UTF8")+extras);
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td");
        e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a", "M");
        e_a.setAttribute("href", "queryManip.jsp?q="+URLEncoder.encode(queryExt, "UTF8")+extras);
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td");
        e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a", "X");
        e_a.setAttribute("href", "queryManip.jsp?q="+URLEncoder.encode(query + "d("+midSegment.toLowerCase()+")", "UTF8")+extras);
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td", ""+cnt.toString());
        e_td1.setAttribute("width", "50");
        String realPath = ""+allPaths.get(loc+"/");
        e_td1    = DOMUtils.createChildElement(e_html, e_tr1,  "td", realPath.replace('/', '\\'));
        e_td1.setAttribute("width", "300");
        return true;
    }

    public static void assignValue(Document e_html, Element e_td1, String address, String value)
    {
        Element button = DOMUtils.createChildElement(e_html, e_td1,  "input");
        button.setAttribute("value", value);
        button.setAttribute("type", "button");
        button.setAttribute("onClick", address + "='" + value + "'");

    }%>
<%@ include file="functions.jsp"%>
