<%@page import="java.io.Writer"
%><%@page import="com.purplehillsbooks.photegrity.DOMUtils"
%><%@page import="com.purplehillsbooks.photegrity.DiskMgr"
%><%@page import="com.purplehillsbooks.photegrity.ImageInfo"
%><%@page import="com.purplehillsbooks.photegrity.UtilityMethods"
%><%@page import="com.purplehillsbooks.photegrity.HashCounter"
%><%@page import="com.purplehillsbooks.streams.HTMLWriter"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Collections"
%><%@page import="java.util.Comparator"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="javax.servlet.http.HttpServletRequest"
%><%@page import="org.w3c.dom.Document"
%><%@page import="org.w3c.dom.Element"
%><%!public static ImageInfo dummy = null;

    public void
    breakOutQuery(String query, Document e_html, Element e_body, String extras)
        throws Exception
    {
        //second line
        Element e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
        Vector v = new Vector();
        String thisPageURL = "queryManip.jsp?q="+URLEncoder.encode(query,"UTF8")+extras;

        int startPos = 0;
        int pos = query.indexOf(")");
        while (pos >= startPos) {
            String pieceq = query.substring(startPos, pos+1);
            v.add(pieceq);
            startPos = pos+1;
            pos = query.indexOf(")", startPos);
        }

        int last = v.size();
        for (int i=0; i<last; i++) {
            String pieceq = (String) v.elementAt(i);
            String piece = pieceq.substring(2, pieceq.length()-1);

            StringBuffer newQuery = new StringBuffer();
            for (int j=0; j<last; j++) {
                if (j != i) {
                    newQuery.append((String) v.elementAt(j));
                }
            }


            Element e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");
            Element e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");
            Element e_a = DOMUtils.createChildElement(e_html, e_td1, "a");
            e_a.setAttribute("href", "queryManip.jsp?q="+URLEncoder.encode(newQuery.toString(),"UTF8"));
            Element e_img = DOMUtils.createChildElement(e_html, e_a, "img");
            e_img.setAttribute("src", "delicon.gif");
            e_img.setAttribute("border", "0");

            e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td");

            e_a = DOMUtils.createChildElement(e_html, e_td1, "a",  pieceq);
            e_a.setAttribute("href", "xgroups.jsp?q="+URLEncoder.encode(pieceq,"UTF8"));

            e_td1.appendChild(e_html.createTextNode(" patterns:"));
            e_a = DOMUtils.createChildElement(e_html, e_td1, "a",  piece);
            e_a.setAttribute("href", "masterPatts.jsp?s="+URLEncoder.encode(piece,"UTF8"));

            e_td1.appendChild(e_html.createTextNode(" tags:"));
            e_a = DOMUtils.createChildElement(e_html, e_td1, "a",  piece);
            e_a.setAttribute("href", "masterGroups.jsp?s="+URLEncoder.encode(piece,"UTF8"));

            for (DiskMgr dm : DiskMgr.getAllDiskMgr()) {
                int count2 = (Integer) dm.getTagCount(piece);
                if (count2 > 0) {
                    e_td1.appendChild(e_html.createTextNode("  |  "+dm.diskName+":"+count2+" "));
                    e_a = DOMUtils.createChildElement(e_html, e_td1,   "a",  "load");
                    e_a.setAttribute("href", "loaddisk.jsp?n="+dm.diskName+"&dest="+URLEncoder.encode(thisPageURL,"UTF8"));
                    e_a.setAttribute("title", "Load into memory disk named "+dm.diskName);
                }
            }
        }
    }


    public
    void
    why /*do I need this?*/ (Writer out, String val)
        throws Exception
    {
        String foo = URLEncoder.encode(val,"UTF8");
        int start = 0;
        int pos = foo.indexOf('?');
        while (pos >= start) {
            out.write( foo.substring(start, pos) );
            out.write( "%FF" );
            start = pos + 1;
            pos = foo.indexOf('?', start);
        }
        out.write( foo.substring(start) );
    }

    public static void sortGroupsByCount(List<String> patterns, 
               HashCounter counter) throws Exception {
        GroupsByCountComparator sc = new GroupsByCountComparator(counter);
        Collections.sort(patterns, sc);
    }


    static class GroupsByCountComparator implements Comparator<String>
    {
        HashCounter counter;

        public GroupsByCountComparator(HashCounter _counter) {
            counter = _counter;
        }

        public int compare(String name1, String name2)
        {
            if (!(name1 instanceof String)) {
                return -1;
            }
            if (!(name2 instanceof String)) {
                return 1;
            }
            int o1size = counter.getCount((String)name1);
            int o2size = counter.getCount((String)name2);

            if (o1size > o2size) {
                return -1;
            }
            else if (o1size == o2size) {
                return 0;
            }
            else {
                return 1;
            }
        }
    }

    public Element
    inputTag(Document e_html, Element e_form, String type, String name, String value)
    {
        Element e_input    = DOMUtils.createChildElement(e_html, e_form, "input");
        e_input.setAttribute("type", type);
        e_input.setAttribute("name", name);
        e_input.setAttribute("value", value);
        return e_input;
    }



    public Element
    topLine(Document e_html, Element e_body, int setSize, String query, String queryOrderPart, String thisPage)
    {
        //Row 1 Menu
        Element  e_table1 = DOMUtils.createChildElement(e_html, e_body,   "table");
        Element  e_tr1    = DOMUtils.createChildElement(e_html, e_table1, "tr");

        pageLink(e_html, e_tr1, "show",         thisPage, "S", queryOrderPart);
        pageLink(e_html, e_tr1, "analyzeQuery", thisPage, "A", queryOrderPart);
        pageLink(e_html, e_tr1, "xgroups",      thisPage, "T", queryOrderPart);
        pageLink(e_html, e_tr1, "allPatts",     thisPage, "P", queryOrderPart);
        pageLink(e_html, e_tr1, "queryManip",   thisPage, "M", queryOrderPart);
        pageLink(e_html, e_tr1, "manage",       thisPage, "I", queryOrderPart);

        Element  e_td1    = DOMUtils.createChildElement(e_html, e_tr1,    "td",
                "{"+Integer.toString(setSize)+"}  "+query);
        return e_tr1;
    }


    public void
    pageLink(Document e_html, Element e_tr1, String pageType, String thisPage,
            String txt, String queryOrderPart)
    {
        Element  e_td1    = DOMUtils.createChildElement(e_html, e_tr1, "td");
        if (thisPage.equals(pageType)) {
            e_td1.setAttribute("bgcolor", "#FF0000");
        }
        Element  e_a      = DOMUtils.createChildElement(e_html, e_td1,    "a",  txt);
        e_a.setAttribute("href", pageType+".jsp?q="+queryOrderPart);
    }


    public Vector
    findMemoryBank(HttpServletRequest request)
        throws Exception
    {
        int set = UtilityMethods.defParamInt(request, "set", 1);
        if (set<1) {
            throw new Exception("memory banks are numbered 1 thru 6, and '"+set+"' is too small.");
        }
        if (set>6) {
            throw new Exception("memory banks are numbered 1 thru 6, and '"+set+"' is too large.");
        }
        return ImageInfo.memory[set-1];
    }

    public void displayThumbnail(Writer out, ImageInfo ii, int thumbsize)
        throws Exception
    {
        if (ii==null) {
            return;
        }
        if (ii.isNullImage()) {
            return;
        }
        out.write("<a href=\"photo/");
        HTMLWriter.writeHtml(out, ii.getRelPath());
        out.write("\" target=\"photo\"><img src=\"thumb/100/");
        HTMLWriter.writeHtml(out, ii.getRelPath());
        out.write("\" width=\""+thumbsize+"\" border=\"0\"></a>\n");
    }

    public int safeConvertInt(String str)
    {
        int ret = 0;
        for (int i=0; i<str.length(); i++)
        {
            char c = str.charAt(i);
            if (c>='0' && c<='9')
            {
                ret = (ret*10) + c - '0';
            }
        }
        return ret;
    }%>