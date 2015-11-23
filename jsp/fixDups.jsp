<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.Exception2"
%><%@page import="bogus.HashCounter"
%><%@page import="bogus.PatternInfo"
%><%@page import="bogus.TagInfo"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileReader"
%><%@page import="java.io.LineNumberReader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.Vector"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "showDups.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }


    // **** query?
    //    g(xyz)  find all images with matching tags
    //    p(xyz)  find all images with matching pattern
    //    s(#)    get from storage area #
    String query = UtilityMethods.reqParam(request, pageName, "q");
    String requestURL = request.getQueryString();

    String widerQuery = null;
    int ppos = query.lastIndexOf('(');
    if (ppos>3) {
        widerQuery = query.substring(0,ppos-1);
    }


    String moveDest = UtilityMethods.getSessionString(session, "moveDest", "");

    // **** sort in a given order?
    String order = "num";
    String orderParam = "&o=name";

    // **** show pictures?
    // **** this page only shows grouped mode
    String pict = "group";

    String listName = UtilityMethods.getSessionString(session, "listName", "");
    String localPath = UtilityMethods.getSessionString(session, "localPath", "../pict/");
    int columns = UtilityMethods.getSessionInt(session, "columns", 3);
    int rows = UtilityMethods.getSessionInt(session, "rows", 4);
    int pageSize = UtilityMethods.getSessionInt(session, "listSize", 20);

    int rowMax = 6;

    String pictParam = "&pict=group";


    int dispMin = UtilityMethods.defParamInt(request, "min", 0);
    if (dispMin < 0) {
        dispMin = 0;
    }
    int dispMax = dispMin + pageSize;
    int prevPage = dispMin - pageSize;
    if (prevPage < 0) {
        prevPage = 0;
    }


    String queryNoOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8");
    String queryOrder = "show.jsp?q="+URLEncoder.encode(query,"UTF8")+"&o="+order+pictParam;
    String thisPage = queryOrder +"&min="+dispMin;
    String queryOrderNoMin = URLEncoder.encode(query,"UTF8")+"&o="+order;
    String queryOrderPart = queryOrderNoMin+"&min="+dispMin;

    String lastPath = "";
    Hashtable diskMap = new Hashtable();
    Vector<ImageInfo> initialImages = new Vector<ImageInfo>();
    initialImages.addAll(ImageInfo.imageQuery(query));
    ImageInfo.sortImages(initialImages, order);
    int recordCount = initialImages.size();

    Vector<ImageInfo> rowImages = new Vector<ImageInfo>();
    int lastRowVal = -99999;
    for (ImageInfo ii : initialImages) {
        if (ii.value != lastRowVal) {
            //need to process the collected row
            processRow(rowImages);
            rowImages = new Vector<ImageInfo>();
            lastRowVal = ii.value;
        }
        rowImages.add(ii);
    }
    processRow(rowImages);

    response.sendRedirect("show.jsp?q="+queryOrderNoMin);
%>

<%!

    public static String[] allDupIndicators = new String[] {"z", "y", "yz", "yy", "yzz", "yzy", "yyz","yyy", "yzzz", "yzzy"};

    public void processRow(Vector<ImageInfo> rowImages) throws Exception {
        boolean hasDup = false;
        for (ImageInfo ii : rowImages) {
            for (String tag : ii.getTagNames()) {
                for (String possibleMatch : allDupIndicators) {
                    if (possibleMatch.equals(tag)) {
                        hasDup = true;
                    }
                }
            }
        }
        if (!hasDup) {
            return;
        }

        ImageInfo bestImage = findImageByDupIndicator(rowImages, "");
        if (bestImage == null) {
            //there is no image without dups, must just remove from one
            //just pick any image
            bestImage = rowImages.firstElement();
            for (String possibleMatch : allDupIndicators) {
                if (imageHasTag(bestImage, possibleMatch)) {
                    removeTag(bestImage, possibleMatch);
                }
            }
        }
        for (ImageInfo ii : rowImages) {
            if (ii!=bestImage) {
                //throw new Exception("About to suppress '"+ii.fileName);
                ii.isTrashed = !ii.isTrashed;
                //ii.suppressImage();
            }
        }
    }

    public ImageInfo findImageByDupIndicator(Vector<ImageInfo> rowImages, String desired) throws Exception {
        if ("".equals(desired)) {
            for (ImageInfo ii : rowImages) {
                boolean hasDupIndicator = false;
                for (String poss : allDupIndicators) {
                    if (imageHasTag(ii, poss)) {
                        hasDupIndicator = true;
                    }
                }
                if (!hasDupIndicator) {
                    return ii;
                }
            }

        }
        else {
            for (ImageInfo ii : rowImages) {
                if (imageHasTag(ii, desired)) {
                    return ii;
                }
            }
        }
        return null; //rowImages.firstElement();
    }

    public boolean imageHasTag(ImageInfo ii, String searchTag) throws Exception {
        for (String tag : ii.getTagNames()) {
            if (searchTag.equals(tag)) {
                return true;
            }
        }
        return false;
    }

    public void removeTag(ImageInfo ii, String tag) throws Exception {
        String fn = ii.fileName;
        int pos = fn.indexOf("."+tag+".");
        if (pos<0) {
            throw new Exception("File "+fn+" does not have tag '"+tag+"'");
        }
        String newName = fn.substring(0,pos) + fn.substring(pos+tag.length()+1);
        //throw new Exception("About to rename '"+fn+"' to '"+newName+"'");
        ii.renameFile(newName);
    }
%>
