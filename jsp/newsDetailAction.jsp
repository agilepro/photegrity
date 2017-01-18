<%@page errorPage="error.jsp"
%><%@page contentType="text/html;charset=UTF-8" pageEncoding="ISO-8859-1"
%><%@page import="bogus.DiskMgr"
%><%@page import="bogus.ImageInfo"
%><%@page import="bogus.LocalMapping"
%><%@page import="bogus.NewsAction"
%><%@page import="bogus.NewsActionDownloadAll"
%><%@page import="bogus.NewsActionDownloadFile"
%><%@page import="bogus.NewsActionDownloadPattern"
%><%@page import="bogus.NewsActionFixDisk"
%><%@page import="bogus.NewsActionSeekABit"
%><%@page import="bogus.NewsActionSeekBunch"
%><%@page import="bogus.NewsArticle"
%><%@page import="bogus.NewsBunch"
%><%@page import="bogus.NewsFile"
%><%@page import="bogus.NewsGroup"
%><%@page import="bogus.NewsSession"
%><%@page import="bogus.PosPat"
%><%@page import="bogus.UtilityMethods"
%><%@page import="java.io.File"
%><%@page import="java.io.FileOutputStream"
%><%@page import="java.io.InputStream"
%><%@page import="java.io.Reader"
%><%@page import="java.net.URLEncoder"
%><%@page import="java.util.Enumeration"
%><%@page import="java.util.Hashtable"
%><%@page import="java.util.List"
%><%@page import="java.util.Vector"
%><%@page import="org.apache.commons.net.nntp.ArticlePointer"
%><%@page import="org.apache.commons.net.nntp.NNTPClient"
%><%@page import="org.apache.commons.net.nntp.NewsgroupInfo"
%><%@page import="org.workcast.streams.HTMLWriter"
%><%request.setCharacterEncoding("UTF-8");
    response.setContentType("text/html;charset=UTF-8");
    long starttime = System.currentTimeMillis();

    String pageName = "nntp.jsp";

    if (session.getAttribute("userName") == null) {%><jsp:include page="PasswordPanel.jsp" flush="true"/><%return;
    }

    String dig       = UtilityMethods.reqParam(request, "News Detail Action", "dig");
    String cmd       = UtilityMethods.reqParam(request, "News Detail Action", "cmd");
    String go        = UtilityMethods.reqParam(request, "News Detail Action", "go");
    String prefFolder= UtilityMethods.defParam(request, "prefFolder", null);
    boolean delAll = (UtilityMethods.defParam(request, "delAll", null)!=null);
    String startPart = "search="+URLEncoder.encode(dig,"UTF-8");
    String newsPage  = UtilityMethods.defParam(request, "prefFolder", null);
    if (newsPage==null) {
        newsPage = "news.jsp?search="+URLEncoder.encode(dig,"UTF-8");
    }
    Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
    if (destVec==null) {
        destVec = new Vector<String>();
        session.setAttribute("destVec", destVec);
    }


    NewsGroup newsGroup = NewsGroup.getCurrentGroup();
    NewsBunch bunch = newsGroup.getBunch(dig.trim());
    String zingpat = (String) session.getAttribute("zingpat");
    if (zingpat==null) {
        zingpat="";
    }
    if (destVec.size()>0) {
        prefFolder = destVec.get(0);
    }
    boolean autoPath = (UtilityMethods.defParam(request, "autopath", null)!=null);


    if (bunch!=null)
    {

        if ("Delete All & Hide".equals(cmd)) {
            newsGroup.clearOutBunch(dig);
            response.sendRedirect(newsPage);
            return;
        }
        if ("Hide".equals(cmd)) {
            newsGroup.clearOutBunch(dig);
            if (delAll) {
                for (NewsFile nfc : bunch.getFiles()) {
                    nfc.deleteFile();
                }
            }
            response.sendRedirect(newsPage);
            return;
        }
        if ("Get A Bit".equals(cmd)) {
            setDefaults(bunch, request);
            NewsActionSeekABit nasp = new NewsActionSeekABit(bunch);
            nasp.addToFrontOfHigh();
            response.sendRedirect(newsPage);
            return;
        }
        if ("Mark Interested".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INTEREST;
            response.sendRedirect(newsPage);
            return;
        }
        if ("Cancel Interest".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INITIAL;
            response.sendRedirect(go);
            return;
        }
        if ("DoubleExtent".equals(cmd)) {
            bunch.seekExtent = bunch.seekExtent * 2;
            response.sendRedirect(go);
            return;
        }
        if ("Seek Bunch".equals(cmd)) {
            NewsActionSeekBunch nasp = new NewsActionSeekBunch(bunch);
            nasp.addToFrontOfHigh();
            response.sendRedirect(newsPage);
            return;
        }
        if ("Cancel Seek".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INTEREST;
            response.sendRedirect(go);
            return;
        }
        if ("Download All".equals(cmd)) {
            setDefaults(bunch, request);
            NewsActionSeekBunch nasp = new NewsActionSeekBunch(bunch);
            nasp.addToFrontOfHigh();
            NewsActionDownloadAll nada = new NewsActionDownloadAll(bunch);
            nada.addToFrontOfMid();
            response.sendRedirect(newsPage);
            return;
        }
        if ("Cancel Download".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_INTEREST;
            response.sendRedirect(go);
            return;
        }
        if ("Mark Complete".equals(cmd)) {
            bunch.pState = NewsBunch.STATE_COMPLETE;
            response.sendRedirect(newsPage);
            return;
        }
        if ("GetPatt".equals(cmd)) {

            List<NewsFile> fileList = bunch.getFiles();
            NewsFile nf = fileList.get(0);
            String pattern = ImageInfo.patternFromFileName(nf.getFileName());
            if (pattern.endsWith("!")) {
                pattern = pattern.substring(0,pattern.length()-1);
            }
            session.setAttribute("zingpat", pattern);
            //now flow through to the next option
            cmd="Get Folder";
        }
        if ("Get Folder".equals(cmd)) {
            String dest = bunch.getFolderLoc();
            int destSize = destVec.size();
            for (int i=0; i<destSize; i++) {
                if (dest.equalsIgnoreCase(destVec.get(i))) {
                    destVec.remove(i);
                    break;
                }
            }
            destVec.insertElementAt(dest, 0);
            response.sendRedirect(go);
            return;
        }
        if ("GetFile".equals(cmd)) {
            String fileName = UtilityMethods.reqParam(request, "", "fileName");
            NewsFile nf = bunch.getFileByName(fileName);
            NewsActionDownloadFile nadf = new NewsActionDownloadFile(nf, false);
            nadf.addToFrontOfHigh();
            response.sendRedirect(go);
            return;
        }
        if ("Create Folder".equals(cmd)) {
            bunch.changeFolder(UtilityMethods.reqParam(request, "News Detail Action", "folder"),true, out);
            File storeFile = bunch.getFolderPath();
            if (!storeFile.exists()) {
                storeFile.mkdirs();
            }
            response.sendRedirect(go);
            return;
        }
        if ("Don't Shrink".equals(cmd)) {
            bunch.shrinkFiles = false;
            response.sendRedirect(go);
            return;
        }
        if ("Do Shrink".equals(cmd)) {
            bunch.shrinkFiles = true;
            response.sendRedirect(go);
            return;
        }
        if ("YEnc".equals(cmd)) {
            bunch.isYEnc = !bunch.isYEnc;
            response.sendRedirect(go);
            return;
        }
        if ("Download All Patt".equals(cmd)) {
            String selPatt = UtilityMethods.reqParam(request, "News Detail Action", "selPatt");
            setDefaults(bunch, request);
            NewsActionSeekBunch nasp = new NewsActionSeekBunch(bunch);
            nasp.addToFrontOfHigh();
            NewsActionDownloadPattern nadp = new NewsActionDownloadPattern(bunch, selPatt);
            nadp.addToFrontOfMid();
            response.sendRedirect(newsPage);
            return;
        }
        if ("Download Available Patt".equals(cmd)) {
            String selPatt = UtilityMethods.reqParam(request, "News Detail Action", "selPatt");
            setDefaults(bunch, request);
            int startInt = UtilityMethods.defParamInt(request, "seekStart", 0);
            NewsActionDownloadPattern nadp = new NewsActionDownloadPattern(bunch, selPatt);
            nadp.addToFrontOfMid();
            response.sendRedirect(newsPage);
            return;
        }
        if ("Set Mapping".equals(cmd)) {
            String selPatt = UtilityMethods.reqParam(request, "News Detail Action", "selPatt");
            String mapPos  = UtilityMethods.reqParam(request, "News Detail Action", "mapPos");
            if (!mapPos.endsWith("/")) {
                mapPos = mapPos + "/";
            }
            String mapPatt = UtilityMethods.reqParam(request, "News Detail Action", "mapPatt");
            PosPat localTemp = bunch.getPosPat(selPatt);
            PosPat newPerm = PosPat.getPosPatFromSymbol(mapPos + mapPatt);
            LocalMapping map = LocalMapping.getMapping(localTemp);
            if (map==null) {
                map = LocalMapping.createMapping(localTemp, newPerm);
            }
            else {
                map.disableAndAbandon();
                map.dest = newPerm;
            }
            response.sendRedirect(go);
            return;
        }
        if ("Enable Mapping".equals(cmd)) {
            String selPatt = UtilityMethods.reqParam(request, "News Detail Action", "selPatt");
            PosPat localTemp = bunch.getPosPat(selPatt);
            LocalMapping map = LocalMapping.getMapping(localTemp);
            if (map!=null) {
                map.enableAndMoveFiles();
            }

            NewsActionFixDisk nafd = new NewsActionFixDisk(map.source.getDiskMgr(), map.source.getFolderPath());
            nafd.addToFrontOfHigh();
            nafd = new NewsActionFixDisk(map.dest.getDiskMgr(), map.dest.getFolderPath());
            nafd.addToFrontOfHigh();

            response.sendRedirect(go);
            return;
        }
        if ("Disable Mapping".equals(cmd)) {
            String selPatt = UtilityMethods.reqParam(request, "News Detail Action", "selPatt");
            PosPat localTemp = bunch.getPosPat(selPatt);
            LocalMapping map = LocalMapping.getMapping(localTemp);
            if (map!=null) {
                map.disableAndAbandon();
            }

            NewsActionFixDisk nafd = new NewsActionFixDisk(map.source.getDiskMgr(), map.source.getFolderPath());
            nafd.addToFrontOfHigh();
            nafd = new NewsActionFixDisk(map.dest.getDiskMgr(), map.dest.getFolderPath());
            nafd.addToFrontOfHigh();

            response.sendRedirect(go);
            return;
        }
        if ("Revert Files".equals(cmd)) {
            String selPatt = UtilityMethods.reqParam(request, "News Detail Action", "selPatt");
            PosPat localTemp = bunch.getPosPat(selPatt);
            LocalMapping map = LocalMapping.getMapping(localTemp);
            if (map!=null) {
                map.disableAndRetrieveFiles();
            }

            NewsActionFixDisk nafd = new NewsActionFixDisk(map.source.getDiskMgr(), map.source.getFolderPath());
            nafd.addToFrontOfHigh();
            nafd = new NewsActionFixDisk(map.dest.getDiskMgr(), map.dest.getFolderPath());
            nafd.addToFrontOfHigh();

            response.sendRedirect(go);
            return;
        }
    }%>

<html>
  <head>
    <meta charset="UTF-8">
  </head> 
<body>
<h3>Updating ... <% HTMLWriter.writeHtml(out, dig); %></h3>
<%
    int count = 0;
    int startPos = 0;
    int posp = dig.indexOf("?", startPos);
    while (posp>0) {
        ++count;
        startPos = posp + 1;
        posp = dig.indexOf("?", startPos);
    }
%>
<p>Found <%=count%> occurrences of question mark</p>
<p>Uncheck this box: <input type="checkbox" name="autoReturn" checked="checked">
   to disable the auto return after processing.</p>
<hr/>
<ul>

<%
    out.flush();
    if (bunch==null) {
        out.write("<li>No bunch available to operation on</li>");
    }
    else if ("Set Without Files".equals(cmd) || "Set And Move Files".equals(cmd)) {
        String dest = UtilityMethods.reqParam(request, "News Detail Action", "folder");
        System.out.println("OK=== Got request for "+cmd);
        if (!dest.endsWith("/")) {
            dest = dest + "/";
        }
        if (dest.endsWith("./")) {
            dest = dest.substring(0,dest.length()-2)+"/";
        }
        System.out.println("OK=== dest is "+dest);
        int colonpos = dest.indexOf(':');
        if (colonpos <= 0) {
            throw new Exception("Parameter 'dest' must have a disk name, colon, and path on that disk, instead received '"+dest+"'.");
        }
        String disk2 = dest.substring(0, colonpos);
        System.out.println("OK=== disk2 is "+disk2);
        String destPath = dest.substring(colonpos+1);
        System.out.println("OK=== destPath is "+destPath);
        DiskMgr dm2 = DiskMgr.getDiskMgr(disk2);
        boolean createIt = ("yes".equals(UtilityMethods.defParam(request, "createIt", "no")));
        boolean copyFiles = ("Set And Move Files".equals(cmd));
        boolean plusOne = UtilityMethods.defParam(request, "plusOne", null)!=null;
        String newTemplate =  UtilityMethods.defParam(request, "template", "");
        System.out.println("OK=== newTemplate is "+newTemplate);
        if (createIt) {
            out.write("\n<li>creating folder"+destPath+"</li>");
            File ref = dm2.getFilePath(destPath);
            if (!ref.exists()) {
                ref.mkdirs();
            }
        }
        out.write("\n<li>changing the bunch location"+dest+"</li>");
        out.flush();
        bunch.changeLocAndTemplate(dest, newTemplate, copyFiles, out, plusOne);

        rememberDestination(session, dest);
    }
    else if ("Set Tags".equals(cmd)) {
        String extraTags = UtilityMethods.reqParam(request, "News Detail Action", "extraTags");
        bunch.extraTags = extraTags;
    }
    else if ("Set Template".equals(cmd)) {
        boolean plusOne = UtilityMethods.defParam(request, "plusOne", null)!=null;
        bunch.changeTemplateInt(UtilityMethods.defParam(request, "template", ""), true, out, plusOne);
    }
    else if ("Cover".equals(cmd)) {

        bunch.changeTemplate(zingpat+"000.cover.jpg", true);
        if (prefFolder!=null && autoPath) {
            bunch.changeFolder(prefFolder, true, out);
        }
    }
    else if ("Flogo".equals(cmd)) {

        bunch.changeTemplate(zingpat+"000.flogo.jpg", true);
        if (prefFolder!=null && autoPath) {
            bunch.changeFolder(prefFolder, true, out);
        }
    }
    else if ("Sample".equals(cmd)) {

        bunch.changeTemplate(zingpat+"000.sample.jpg", true);
        if (prefFolder!=null && autoPath) {
            bunch.changeFolder(prefFolder, true, out);
        }
    }
    else if ("SetPattern".equals(cmd)) {

        String oldTemp = bunch.getTemplate();
        String oldTempLC = oldTemp.toLowerCase();
        int pos = oldTempLC.indexOf(".jpg");
        if (pos<0) {
            throw new Exception("can't find a .jpg suffix on the current template");
        }
        int dollar = oldTempLC.lastIndexOf("$");
        if (pos<0) {
            throw new Exception("can't find a dollarsign on the current template");
        }
        if (pos < dollar) {
            throw new Exception("dont understand how the .jpg can be BEFORE the last dollar sign");
        }

        bunch.changeTemplate(zingpat+oldTemp.substring(dollar), true);
        if (prefFolder!=null && autoPath) {
            bunch.changeFolder(prefFolder, true, out);
        }
    }
    else if ("SetIndex".equals(cmd)) {

        String oldTemp = bunch.getTemplate();
        String oldTempLC = oldTemp.toLowerCase();
        int pos = oldTempLC.indexOf(".jpg");
        if (pos<0) {
            throw new Exception("can't find a .jpg suffix on the current template");
        }
        int dollar = oldTempLC.lastIndexOf("$");
        if (pos<0) {
            throw new Exception("can't find a dollarsign on the current template");
        }
        if (pos < dollar) {
            throw new Exception("dont understand how the .jpg can be BEFORE the last dollar sign");
        }

        bunch.changeTemplate(zingpat+"!"+oldTemp.substring(dollar), true);
        System.out.println("starting change folder: "+System.currentTimeMillis());
        if (prefFolder!=null && autoPath) {
            bunch.changeFolder(prefFolder, true, out);
        }
        System.out.println("finished change folder: "+System.currentTimeMillis());
    }
    else if ("SetOneIndex".equals(cmd)) {

        String oldTemp = bunch.getTemplate();
        String oldTempLC = oldTemp.toLowerCase();
        int pos = oldTempLC.indexOf(".jpg");
        if (pos<0) {
            throw new Exception("can't find a .jpg suffix on the current template");
        }

        bunch.changeTemplate(zingpat+"!01.jpg", true);
        if (prefFolder!=null && autoPath) {
            bunch.changeFolder(prefFolder, true, out);
        }
    }
    else {
        out.write("Don't understand command '"+cmd+"'");
    }
%>
</ul>
<br/>
<a href="news.jsp">News</a>
<hr/>
<p>Now .... waiting 3 seconds before return (or click <a href="<%=go%>">here</a>)</p>
<script>
    setTimeout(goFarFarAway, 0010);

    function goFarFarAway() {
        window.location.assign("<%=go%>");
    }
</script>
</body></html>


<%!public String cleanPunct(String inStr) {
    StringBuffer outStr = new StringBuffer();

    boolean needDot = false;
    for (int i = 0; i<inStr.length(); i++) {
        char ch = inStr.charAt(i);
        if ( (ch>='a'&&ch<='z') || (ch>='A'&&ch<='Z') || (ch>='0'&&ch<='1') || ch=='_' ) {
            outStr.append(ch);
            needDot = true;
        }
        else if (ch==' ') {

        }
        else {
            if (needDot) {
                outStr.append('.');
                needDot = false;
            }
        }
    }
    return outStr.toString();
}

    public void rememberDestination(HttpSession session, String dest) {
        Vector<String> destVec = (Vector<String>) session.getAttribute("destVec");
        if (destVec == null) {
            destVec = new Vector<String>();
            session.setAttribute("destVec", destVec);
        }
        int destSize = destVec.size();
        for (int i=0; i<destSize; i++) {
            if (dest.equalsIgnoreCase(destVec.get(i))) {
                destVec.remove(i);
                break;
            }
        }
        destVec.insertElementAt(dest, 0);
    }

    public void setDefaults(NewsBunch bunch, HttpServletRequest request) throws Exception {
        if (!bunch.hasTemplate()) {
            String temp = UtilityMethods.defParam(request, "template", null);
            if (temp==null) {
                temp = bunch.getTemplate();
            }
            String templc = temp.toLowerCase();
            if (!templc.endsWith(".jpg")) {
                throw new Exception("file template must end with .jpg: got ("+temp+")");
            }
            bunch.changeTemplate(temp, false);
        }
        if (!bunch.hasFolder()) {
            bunch.createFolderIfReasonable();
        }
    }%>
