<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="com.purplehillsbooks.photegrity.DOMUtils"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.PatternInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.photegrity.MongoDB"
%><%@page import="com.purplehillsbooks.json.JSONObject"
%><%@page import="com.purplehillsbooks.json.JSONArray"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.io.Writer"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Arrays"
%><%@page import="java.util.List"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Comparator"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Random"
%><%@page import="java.util.Vector"
%><%@page import="org.w3c.dom.Document"
%><%@page import="org.w3c.dom.Element"
%><%request.setCharacterEncoding("UTF-8");
    long starttime = System.currentTimeMillis();
    String pageName = "xgroups.jsp";

    //see if we are logged in.
    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    Vector<DiskMgr> sortedDisks = new Vector<DiskMgr>();
    for (DiskMgr dm : DiskMgr.getAllDiskMgr())
    {
        sortedDisks.add(dm);
    }


    // here is a case where tomcat has magically preserved our session
    // but of course not the internal object state, so we need to log
    // in in order to set things up correctly.
    if (!DiskMgr.isInitialized()) {
        %><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }


    int dispMin   = UtilityMethods.defParamInt(request, "min", 0);
    String query  = UtilityMethods.reqParam(request, "xgroups.jsp", "q");
    String order  = UtilityMethods.defParam(request, "o", "name");
    String encodedQuery = URLEncoder.encode(query,"UTF8");
    String thisBaseURL = "xgroups.jsp?q="+encodedQuery;
    String thisPageURL = thisBaseURL;

    String rd = UtilityMethods.defParam(request, "rd", "");
    DiskMgr requiredDisk = DiskMgr.getDiskMgrOrNull(rd);

    HashCounter groupCount = new HashCounter();
    HashCounter pattCount = new HashCounter();
    HashCounter symbolCount = new HashCounter();
    HashCounter sizeTotal = new HashCounter();

    MongoDB mongo = new MongoDB();
    mongo.queryStatistics(query, groupCount, pattCount, symbolCount, sizeTotal);
    mongo.close();

    List<String> sortedGroups = groupCount.sortedKeys();
    sortGroupsByCount(sortedGroups, groupCount);

    String[] colors = {"#FDF5E6", "#FEF9F5"};
    int row = 0;
    String queryOrderPart = URLEncoder.encode(query,"UTF8")+"&o="+order+"&min="+dispMin;


    Document e_html = DOMUtils.createDocument("html");
    Element  e_head = DOMUtils.createChildElement(e_html, e_html.getDocumentElement(), "head");
    Element  e_title = DOMUtils.createChildElement(e_html, e_head, "title", "All Tags "+query);

    Element  e_body9 = DOMUtils.createChildElement(e_html, e_html.getDocumentElement(), "body");
    e_body9.setAttribute("BGCOLOR", "#FDF5E6");
    Element  e_table9 = DOMUtils.createChildElement(e_html, e_body9,   "table");
    Element  e_tr9    = DOMUtils.createChildElement(e_html, e_table9, "tr");
    Element  e_body   = DOMUtils.createChildElement(e_html, e_tr9,    "td");

    //Row 1
    topLine(e_html, e_body, groupCount.size(), query, queryOrderPart, "xgroups");

    //Row 2
    Element  e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
    Element  e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");
    Element  e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    Element  e_a      = DOMUtils.createChildElement(e_html, e_td1,   "a",  "Main");
    e_a.setAttribute("href", "main.jsp");

    e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_a      = DOMUtils.createChildElement(e_html, e_td1,   "a",  "1");
    e_a.setAttribute("href", "xgroups.jsp?q=s(1)");

    e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_a      = DOMUtils.createChildElement(e_html, e_td1,   "a",  "2");
    e_a.setAttribute("href", "xgroups.jsp?q=s(2)");

    e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_a      = DOMUtils.createChildElement(e_html, e_td1,   "a",  "3");
    e_a.setAttribute("href", "xgroups.jsp?q=s(3)");

    e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_a      = DOMUtils.createChildElement(e_html, e_td1,   "a",  "Images");
    e_a.setAttribute("href", thisBaseURL+"&img=1");
    e_body.appendChild(e_html.createTextNode("\n"));


    Element e_img = DOMUtils.createChildElement(e_html, e_body,   "hr");

    // main table
    e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
    e_tr1 = DOMUtils.createChildElement(e_html, e_table1, "col");
    e_tr1.setAttribute("width", "100");
    e_tr1.setAttribute("align", "center");

    Random rand = new Random(System.currentTimeMillis());
    int imageLimit = 30;

    //title row
    e_tr1 = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
    for (DiskMgr dm  : sortedDisks) {

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");
        e_td1.appendChild(e_html.createTextNode(dm.diskName + " "));
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "req");
        e_a.setAttribute("href", "xgroups.jsp?q=" + queryOrderPart + "&rd="+dm.diskName);
        e_a.setAttribute("title", "Exclusive to "+dm.diskName);
    }

    for (String tagName : sortedGroups) {
        if (tagName.equals("extra")) continue;
        if (tagName.equals("y")) continue;
        if (requiredDisk!=null && requiredDisk.getTagCount(tagName)==0)
        {
            continue;
        }
        e_tr1 = DOMUtils.createChildElement(e_html, e_table1, "tr");
        e_tr1.setAttribute("valign", "top");
        e_tr1.setAttribute("bgcolor", colors[(row++)%2]);
        e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");

        String newQuery = query+"g("+tagName+")";
        String newQueryEncoded = URLEncoder.encode(newQuery,"UTF8");

        int num = groupCount.getCount(tagName);

        String fract = Integer.toString(num) + "/" + Integer.toString(999);
        e_td1.appendChild(e_html.createTextNode(fract));
        DOMUtils.createChildElement(e_html, e_td1,    "br");

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", tagName);
        e_a.setAttribute("href", "show.jsp?q="+newQueryEncoded);
        DOMUtils.createChildElement(e_html, e_td1,    "br");

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "S");
        e_a.setAttribute("href", "show.jsp?q="+newQueryEncoded);

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "A");
        e_a.setAttribute("href", "analyzeQuery.jsp?q="+newQueryEncoded);

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "T");
        e_a.setAttribute("href", "xgroups.jsp?q="+newQueryEncoded);

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "P");
        e_a.setAttribute("href", "allPatts.jsp?q="+newQueryEncoded);

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "M");
        e_a.setAttribute("href", "queryManip.jsp?q="+newQueryEncoded);

        e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
        e_a = DOMUtils.createChildElement(e_html, e_td1, "a", "Exclude");
        e_a.setAttribute("href", "xgroups.jsp?q="+URLEncoder.encode(query+"d("+tagName+")","UTF8"));

        for (DiskMgr dm : sortedDisks) {
            e_td1 = DOMUtils.createChildElement(e_html, e_tr1, "td");
            int count = dm.getTagCount(tagName);
            if (count > 0) {
                e_td1.appendChild(e_html.createTextNode(Integer.toString(count)));
            }
            else {
                e_td1.appendChild(e_html.createTextNode(" - "));
            }
        }
        out.flush();
    }

    e_img = DOMUtils.createChildElement(e_html, e_body,   "img");
    e_img.setAttribute("src", "bar.jpg");

    e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
    e_tr1 = DOMUtils.createChildElement(e_html, e_table1, "tr");
    e_td1 = DOMUtils.createChildElement(e_html, e_tr1,    "td");

    Element e_form = DOMUtils.createChildElement(e_html, e_td1,  "form");
    e_form.setAttribute("action", "xgroups.jsp");
    e_form.setAttribute("method", "get");

    Element e_input = DOMUtils.createChildElement(e_html, e_td1,  "input");
    e_input.setAttribute("type", "text");
    e_input.setAttribute("name", "q");
    e_input.setAttribute("value", query);

    e_input = DOMUtils.createChildElement(e_html, e_td1,  "input");
    e_input.setAttribute("type", "submit");
    e_input.setAttribute("value", "Tag");

    breakOutQuery(query, e_html, e_body, thisPageURL);

    DOMUtils.writeDom(e_html, out);%>

    <%@ include file="functions.jsp"%>

