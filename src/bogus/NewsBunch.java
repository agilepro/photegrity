package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.List;
import java.util.Vector;

import org.workcast.json.JSONArray;
import org.workcast.json.JSONObject;
import org.workcast.streams.CSVHelper;
import org.workcast.streams.HTMLWriter;

/**
 * represents all the articles with a single subject digest
 */

public class NewsBunch {
    public String digest;
    public String from;
    public String extraTags;
    public int pState = 0;
    public boolean plusOneNumber = false; // make file with number 1 larger than
                                          // article says
    public static final int STATE_INITIAL = 0;
    public static final int STATE_INTEREST = 1;
    public static final int STATE_SEEK = 2;
    public static final int STATE_SEEK_DONE = 3;
    public static final int STATE_DOWNLOAD = 4;
    public static final int STATE_DOWNLOAD_DONE = 5;
    public static final int STATE_COMPLETE = 6;
    public static final int STATE_HIDDEN = 7;
    public static final int STATE_ERROR = 8;
    public static final int STATE_GETABIT = 9;

    private NewsGroup newsGroup;
    private int specialTokenIndex = -2; // -2 means not determined yet
    private Vector<PosPat> sites = null;

    //This is a unique key JUST for this session!
    public long bunchKey;

    public int count = -1;   //don't know how many
    public long maxId = 0;
    public long minId = 0;
    public int denominator;
    public int numerator = -1;
    public boolean hasMulti = false;
    //private String fileTemplate = "";
    private FracturedFileName fracTemplate;
    
    private DiskMgr disk;
    private String pathInDisk;
    private String sender;

    public int fileTotal = 0;
    public int fileComplete = 0;
    public int fileDown = 0;

    // for tracking current actions for feedback in UI
    // these should NOT be persistent
    public boolean isSeeking;
    public boolean isDownloading;
    public boolean shrinkFiles = true;
    public boolean isYEnc = false;
    public long lastTouch = 0;
    public int seekExtent=15; //how far beyond the known edges should we look?
                              //used by NewsActionSeekBunch

    private String samplePattern = null;

    public Exception failureMessage;

    public static boolean groupIsFullyIndexed = false;

    public String getStateColor() {
        switch (pState) {
        case STATE_INITIAL:
            return "white";
        case STATE_INTEREST:
            return "yellow";
        case STATE_SEEK:
            return "green";
        case STATE_SEEK_DONE:
            return "lightgreen";
        case STATE_DOWNLOAD:
            return "dodgerblue";
        case STATE_DOWNLOAD_DONE:
            return "lightblue";
        case STATE_COMPLETE:
            return "grey";
        case STATE_HIDDEN:
            return "red";
        case STATE_ERROR:
            return "deeppink";
        case STATE_GETABIT:
            return "orange";
        }
        return "purple";
    }

    static long nextKeyValue = System.currentTimeMillis();

    public NewsBunch(NewsGroup ng, String _bunch, String _from) throws Exception {
    	bunchKey = nextKeyValue++;
        digest = _bunch;
        from = _from;
        newsGroup = ng;

        // now figure out if this pattern has provision for multipart files, and
        // identify which index it is.
        int multipos = digest.lastIndexOf("(\u25A3/\u25A3)");
        hasMulti = multipos >= 0;
        numerator = 0;
        if (hasMulti) {
            for (int i = 0; i < multipos; i++) {
                if (digest.charAt(i) == '\u25A3') {
                    numerator++;
                }
            }
            denominator = numerator + 1;
        }

        // initialize to *something*
        disk = ng.defaultDiskMgr;
        setRelativePath(makeReasonablePath(_bunch));

        //check to see if there is a YEnc indicator in the subject line
        isYEnc =  (_bunch.toLowerCase().indexOf("yenc")>0);
    }
    
    public static NewsBunch copyCreate(NewsBunch oldOne, String from) throws Exception  {
        String digest = oldOne.digest;
        NewsBunch nb = new NewsBunch(oldOne.newsGroup, digest, from);
        nb.extraTags = oldOne.extraTags;
        nb.pState = oldOne.pState;
        nb.pathInDisk = oldOne.pathInDisk;
        nb.fracTemplate = oldOne.fracTemplate;
        return nb;
    }


    private String makeReasonablePath(String _bunch) {
        boolean loop = true;
        String fakePath = cleanPunct(_bunch);
        while (loop) {
        	loop = false;
        	//get rid of jpg if it exists
        	fakePath = fakePath.replaceAll("jpg", "");
            //get rid of zip if it exists
            fakePath = fakePath.replaceAll("zip", "");
            //get rid of rar if it exists
            fakePath = fakePath.replaceAll("rar", "");
         	if (fakePath.length()>5) {
            	int dotPos = fakePath.lastIndexOf(".");
            	if (dotPos>fakePath.length()-4) {
            		//trim off small tiny zero, one or two letter entries between dots at the end
            		fakePath = fakePath.substring(0,dotPos);
    	        	loop = true;
            	}
        	}
       }
        if (fakePath.length()<10) {
            //add a completely arbitrary thing to make it more unique
            fakePath = fakePath + Long.toString( System.currentTimeMillis() );
        }
        if (!fakePath.endsWith("/")) {
            fakePath = fakePath + "/";
        }

        return fakePath;
    }
    public DiskMgr getDiskMgr() {
        return disk;
    }


    public void setRelativePath(String newLocalPath) {
        if (!newLocalPath.endsWith("/")) {
            throw new RuntimeException("local path MUST end with a slash, but this doesn't: ("+newLocalPath+")");
        }
        pathInDisk = newLocalPath;
    }

    public String getRelativePath() {
        return pathInDisk;
    }

    /**
     * For a specified pattern, this will get the PosPat
     * for it.  Not sure how useful this is.
     */
    public PosPat getPosPat(String pattern) throws Exception {
        if (disk==null) {
            return null;   //probably never possible
        }
        String localPath = this.getRelativePath();
        if (localPath==null || localPath.length()==0) {
            return null;
        }
        if (!localPath.endsWith("/")) {
            throw new RuntimeException("local path MUST end with a slash, but this doesn't: ("+localPath+")");
        }
        return PosPat.findOrCreate(disk, localPath, pattern);
    }

    /**
     * Get the digest in a form that has substitution tokens in it, like
     * xxx$1yyyy$2zzzz
     */
    public String tokenFill() {

        StringBuffer res = new StringBuffer();
        int count = 0;
        for (int i = 0; i < digest.length(); i++) {

            char ch = digest.charAt(i);

            if (ch == NewsArticle.special) {
                res.append("$");
                res.append(Integer.toString(count));
                count++;
            }
            else {
                res.append(ch);
            }

        }
        return res.toString();
    }

    public void addCount(long articleId) {
        count++;
        if (minId == 0 || articleId < minId) {
            minId = articleId;
        }
        if (maxId == 0 || articleId > maxId) {
            maxId = articleId;
        }
    }

    public void registerNewArticle() {
        sites = null;  //will force recalc because this new article might be a different pattern
    }


    public void changeState(int newState) throws Exception {
    	if (newState==pState) {
    		//nothing to do.
    		return;
    	}

    	if (newState==NewsBunch.STATE_GETABIT) {
    		NewsActionSeekABit nasp = new NewsActionSeekABit(this);
    		nasp.addToFrontOfHigh();
    	}
    	if (newState==NewsBunch.STATE_SEEK) {
    		NewsActionSeekBunch nasp = new NewsActionSeekBunch(this);
            nasp.addToFrontOfHigh();
        }
    	if (newState==NewsBunch.STATE_DOWNLOAD) {
    		NewsActionSeekBunch nasp = new NewsActionSeekBunch(this);
            nasp.addToFrontOfHigh();
            NewsActionDownloadAll nada = new NewsActionDownloadAll(this);
            nada.addToFrontOfMid();
        }

    	pState = newState;
    }


    public void writeCacheLine(Writer fw) throws Exception {
        Vector<String> values = new Vector<String>();
        values.add(digest);
        String store = disk.diskName + ":" + pathInDisk;
        values.add(store);
        if (fracTemplate == null) {
            fracTemplate = new FracturedFileName();
        }
        values.add(fracTemplate.getBasicName());
        if (pState == NewsBunch.STATE_HIDDEN) {
            values.add("hide");
        }
        else if (pState == NewsBunch.STATE_INITIAL) {
            values.add("show");
        }
        else if (pState == NewsBunch.STATE_COMPLETE) {
            values.add("complete");
        }
        else if (pState == NewsBunch.STATE_SEEK_DONE) {
            values.add("seekdone");
        }
        else if (pState == NewsBunch.STATE_DOWNLOAD_DONE) {
            values.add("downdone");
        }
        else if (pState == NewsBunch.STATE_GETABIT) {
            values.add("getabit");
        }
        else {
            // all the states that have been added and are not persistent turn
            // into interest
            values.add("interest");
        }
        values.add(Integer.toString(count));

        // add either 'plus' or 'zero' to indicate increment
        if (plusOneNumber) {
            values.add("plus");
        }
        else {
            values.add("zero");
        }
        values.add(Integer.toString(fileTotal));
        values.add(Integer.toString(fileComplete));
        values.add(Integer.toString(fileDown));
        values.add(Long.toString(lastTouch));
        values.add(from);
        CSVHelper.writeLine(fw, values);
    }

    public static void restoreData(NewsGroup ng) throws Exception {

        File destFile = new File(ng.containingFolder, ng.groupName + ".patt");
        FileInputStream fis = new FileInputStream(destFile);
        Reader fr = new InputStreamReader(fis, "UTF-8");

        List<String> values = CSVHelper.parseLine(fr);
        while (values != null) {
            NewsBunch.parseFromLine(ng, values);
            values = CSVHelper.parseLine(fr);
        }

        fr.close();
    }

    public static void parseFromLine(NewsGroup ng, List<String> values) throws Exception {

        String subjectLine = values.get(0);
        String fromLine = null;
        if (values.size() > 10) {
            fromLine = values.get(10);
        }

        // schema migration ... eliminate tails in certain cases
        subjectLine = removeOffEndIfPresent(subjectLine, "[\u25A3K]");
        subjectLine = removeOffEndIfPresent(subjectLine, "[1\u25A3K]");
        subjectLine = removeBytesOffEndIfPresent(subjectLine);

        NewsBunch newBunch = ng.getBunch(subjectLine, fromLine);

        String store = values.get(1);
        store = store.replace('\\', '/');

        //get rid of any dot before a slash
        while (store.indexOf("./")>=0) {
            store = store.replace("./", "/");
        }

        if (store.startsWith("m:/z/.y/")) {
            // this is legacy conversion code not needed after July 2013
            File storePath = new File(store);
            DiskMgr fDisk = DiskMgr.findDiskMgrFromPath(storePath);
            if (fDisk != null) {
                newBunch.disk = fDisk;
                newBunch.setRelativePath(fDisk.getOldRelativePathWithoutSlash(storePath));
            }
        }
        else {
            if (isPathReasonable(store)) {
                if (!store.endsWith("/")) {
                    store = store + "/";
                }
                //if the storage path is reasonable (diskmgr exists) then
                //set the path value without moving any file.
                newBunch.changeFolder(store, false);
            }
        }
        newBunch.fracTemplate = FracturedFileName.parseTemplate(values.get(2));
        String stateStr = values.get(3);
        if ("hide".equals(stateStr)) {
            newBunch.pState = NewsBunch.STATE_HIDDEN;
        }
        else if ("interest".equals(stateStr)) {
            newBunch.pState = NewsBunch.STATE_INTEREST;
        }
        else if ("seekdone".equals(stateStr)) {
            newBunch.pState = NewsBunch.STATE_SEEK_DONE;
        }
        else if ("downdone".equals(stateStr)) {
            newBunch.pState = NewsBunch.STATE_DOWNLOAD_DONE;
        }
        else if ("complete".equals(stateStr)) {
            newBunch.pState = NewsBunch.STATE_COMPLETE;
        }
        else if ("getabit".equals(stateStr)) {
            newBunch.pState = NewsBunch.STATE_GETABIT;
        }
        if (values.size() > 4 && newBunch.count == -1) {
            newBunch.count = UtilityMethods.safeConvertInt(values.get(4));
        }

        if (values.size() > 5) {
            // sixth column is either 'zero' or 'plus'
            newBunch.plusOneNumber = "plus".equals(values.get(5));
        }
        if (values.size() > 8) {
            //added these to the file format at the same time, so get all or none
            newBunch.fileTotal = UtilityMethods.safeConvertInt(values.get(6));
            newBunch.fileComplete = UtilityMethods.safeConvertInt(values.get(7));
            newBunch.fileDown = UtilityMethods.safeConvertInt(values.get(8));
        }
        if (values.size() > 9) {
            newBunch.lastTouch = UtilityMethods.safeConvertLong(values.get(9));
        }
        if (values.size() > 10) {
            newBunch.from = values.get(10);
        }

    }

    public static String removeOffEndIfPresent(String buf, String token) {
        if (buf.endsWith(token)) {
            int pos = buf.length() - token.length();
            while (buf.charAt(pos - 1) == ' ') {
                pos--;
            }
            return buf.substring(0, pos);
        }
        return buf;
    }

    public static String removeBytesOffEndIfPresent(String buf) {
        if (buf.endsWith("bytes") || buf.endsWith("Bytes")) {
            int len = buf.length() - 6;
            while (buf.charAt(len) == ' ') {
                len--;
            }
            while (buf.charAt(len) == '\u25A3') {
                len--;
            }
            while (buf.charAt(len) >= '0' && buf.charAt(len) <= '9') {
                len--;
            }
            while (buf.charAt(len) == ' ') {
                len--;
            }
            return buf.substring(0, len + 1);
        }
        return buf;
    }

    private static String cleanPunct(String inStr) {
        StringBuffer outStr = new StringBuffer();

        boolean needDot = false;
        for (int i = 0; i < inStr.length(); i++) {
            char ch = inStr.charAt(i);
            if ((ch >= 'a' && ch <= 'z') || (ch >= 'A' && ch <= 'Z') || (ch >= '0' && ch <= '1')
                    || ch == '_') {
                outStr.append(ch);
                needDot = true;
            }
            else if (ch == ' ') {

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

    public List<NewsArticle> getArticles() throws Exception {
        List<NewsArticle> res = newsGroup.getArticlesDigest(digest, from);
        return res;
    }

    public NewsArticle getSampleArticle() throws Exception {
        List<NewsArticle> res = newsGroup.getArticlesDigest(digest, from);
        if (res.size()>0) {
            return res.get(0);
        }
        System.out.println("Found bunch with NO sample article: "+digest);
        return null;
    }

    public static void sortByPattern(List<NewsBunch> listToSort) throws Exception {
        Collections.sort(listToSort, new byPattComp());
    }

    /**
     * sorts by digest
     */
    static class byPattComp implements Comparator<NewsBunch> {
        public byPattComp() {
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            NewsBunch na1 = o1;
            NewsBunch na2 = o2;
            int val = na1.digest.compareTo(na2.digest);
            return val;
        }
    }

    public static void sortByArticleId(List<NewsBunch> listToSort) throws Exception {
        Collections.sort(listToSort, new byIDComp());
    }

    /**
     * sorts by digest
     */
    static class byIDComp implements Comparator<NewsBunch> {
        public byIDComp() {
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            NewsBunch na1 = o1;
            NewsBunch na2 = o2;
            if (na2.minId > na1.minId) {
                return 1;
            }
            if (na2.minId < na1.minId) {
                return -1;
            }
            return 0;
        }
    }

    public static void sortByCount(List<NewsBunch> listToSort) throws Exception {
        Collections.sort(listToSort, new byCountComp());
    }

    /**
     * sorts by pattern
     */
    static class byCountComp implements Comparator<NewsBunch> {
        public byCountComp() {
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            NewsBunch na1 = o1;
            NewsBunch na2 = o2;
            if (na2.count > na1.count) {
                return 1;
            }
            if (na2.count < na1.count) {
                return -1;
            }
            return 0;
        }
    }

    public static void sortByLocalFile(List<NewsBunch> listToSort, DiskMgr d) throws Exception {
        Collections.sort(listToSort, new byLocalFileComp(d));
    }

    /**
     * sorts by local file count
     */
    static class byLocalFileComp implements Comparator<NewsBunch> {
        DiskMgr disk;

        public byLocalFileComp(DiskMgr d) {
            disk = d;
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            NewsBunch na1 = o1;
            NewsBunch na2 = o2;
            boolean isLocal1 = na1.hasFolder() && na1.disk.equals(disk);
            boolean isLocal2 = na2.hasFolder() && na2.disk.equals(disk);
            //if different, then one is local and one not.  That decides it
            if (isLocal1 && !isLocal2) {
                return -1;
            }
            if (!isLocal1 && isLocal2) {
                return 1;
            }
            //if the same, return based on the count
            if (na2.count > na1.count) {
                return 1;
            }
            if (na2.count < na1.count) {
                return -1;
            }
            return 0;
        }
    }

    public static void sortByTemplate(List<NewsBunch> listToSort) throws Exception {
        Collections.sort(listToSort, new byTemplateComp());
    }

    /**
     * sorts by file name (template)
     */
    static class byTemplateComp implements Comparator<NewsBunch> {
        public byTemplateComp() {
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            String template1 = o1.getTemplate();
            String template2 = o2.getTemplate();
            return template1.compareTo(template2);
        }
    }

    public static void sortByLastTouch(List<NewsBunch> listToSort) throws Exception {
        Collections.sort(listToSort, new byLastTouchComp());
    }

    /**
     * sorts inverse direction by touch timestamp, most recent (largest) first
     * normal: (first<second = -1) (first==second = 0) (first>second = 1)
     * inverse: (first<second = 1) (first==second = 0) (first>second = -1)
     */
    static class byLastTouchComp implements Comparator<NewsBunch> {
        public byLastTouchComp() {
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            if (o1.lastTouch < o2.lastTouch) {
                return 1;
            }
            if (o1.lastTouch > o2.lastTouch) {
                return -1;
            }
            return 0;
        }
    }

    public static void sortByPath(List<NewsBunch> listToSort) throws Exception {
        Collections.sort(listToSort, new byPathComp());
    }

    /**
     * sorts alphabetically by full path and template normal: (first<second =
     * -1) (first==second = 0) (first>second = 1) inverse: (first<second = 1)
     * (first==second = 0) (first>second = -1)
     */
    static class byPathComp implements Comparator<NewsBunch> {
        public byPathComp() {
        }

        public int compare(NewsBunch o1, NewsBunch o2) {
            String path1 = o1.getFolderLoc();
            String path2 = o2.getFolderLoc();
            return path1.compareTo(path2);
        }
    }

    /**
     * A heuristic attempt to determine if there seem to be missing articles
     */
    public boolean appearsToNeedSeek(NewsGroup ng) throws Exception {

        // first, find the minimum and maxumum articles
        long min = 999999999999L;
        long max = 0;
        for (NewsArticle art : getArticles()) {
            long artNo = art.articleNo;
            if (artNo < min) {
                min = artNo;
            }
            if (artNo > max) {
                max = artNo;
            }
        }

        min -= 10;
        max += 10;
        long count = 0;
        // starting before the min and ending after max, check to
        // see if all the article hearders are present in buffer
        for (long i = min; i < max; i++) {
            if (ng.hasArticle(i)) {
                count++;
            }
        }

        long ninetyFivePercent = (max - min) * 95 / 100; // 95%
        return (count < ninetyFivePercent);
    }

    public List<NewsFile> getFiles() throws Exception {
        if (fracTemplate == null || fracTemplate.isEmpty()) {
            throw new Exception("sorry, can't collect files until the file template is set for the bunch "+digest);
        }
        int countTotal = 0;
        int countComplete = 0;
        int countDown = 0;
        Hashtable<String, NewsFile> files = new Hashtable<String, NewsFile>();
        for (NewsArticle art : getArticles()) {
            String fileName = art.getFileName();
            if (fileName.length() == 0) {
                throw new Exception("Article " + art.articleNo
                        + " has a null filename, but there is a fileTemplate on the pattern for "+digest);
            }
            FracturedFileName ffn = FracturedFileName.parseFile(fileName);
            
            NewsFile file = files.get(fileName);
            if (file == null) {
                file = new NewsFile(fileName, this);
                files.put(fileName, file);
            }
            file.addArticle(art);
        }
        Vector<NewsFile> results = new Vector<NewsFile>();
        for (NewsFile nf : files.values()) {
            results.add(nf);
            countTotal++;
            if (nf.isComplete()) {
                countComplete++;
            }
            if (nf.isDownloaded()) {
                countDown++;
            }
        }
        fileTotal = countTotal;
        fileComplete = countComplete;
        fileDown = countDown;
        NewsFile.sortByFileName(results);
        return results;
    }

    /**
     * Given an article, this gets the NewsFile object, which contains
     * all the other articles.
     */
    public NewsFile getFileForArticle(NewsArticle artIn) throws Exception {
        String fileName = artIn.getFileName();
        NewsFile file = new NewsFile(fileName, this);
        for (NewsArticle art : getArticles()) {
            if (fileName.equals(art.getFileName())) {
                file.addArticle(art);
            }
        }
        return file;
    }

    /**
     * Get a single NewsFile object by filename Note: might be empty if no file
     * actually matches the name
     */
    public NewsFile getFileByName(String fileName) throws Exception {
        NewsFile file = new NewsFile(fileName, this);
        for (NewsArticle art : getArticles()) {
            if (fileName.equals(art.getFileName())) {
                file.addArticle(art);
            }
        }
        return file;
    }

    public NewsFile getFileByNumber(String pattern, int fileNumber) throws Exception {
        for (NewsFile nf : getFiles()) {
            if (fileNumber == nf.getSequenceNumber() && pattern.equals(nf.getPattern())) {
                return nf;
            }
        }
        return null;
    }

    public boolean hasTemplate() {
        return (fracTemplate != null && !fracTemplate.isEmpty());
    }

    public String getTemplate() {
        if (fracTemplate == null || fracTemplate.isEmpty()) {
            return guessFileTemplate();
        }
        return fracTemplate.getBasicName();
    }
    public FracturedFileName getFracTemplate() {
        return fracTemplate;
    }

    public String getSampleFileName() throws Exception {
        String temp = fracTemplate.getBasicName();
        if (temp == null || temp.length() == 0) {
            temp = guessFileTemplate();
        }
        // this is a "random" article, not necessarily the first, or typical
        NewsArticle art = getSampleArticle();
        if (art != null) {
            return art.fillTemplate(temp);
        }
        return null;
    }

    public void changeTemplate(String newTemplate, boolean renameFiles) throws Exception {
        changeTemplate(newTemplate, renameFiles, new org.workcast.streams.NullWriter());
    }

    public void changeTemplate(String newTemplate, boolean renameFiles, Writer out)
            throws Exception {
        changeTemplateInt(newTemplate, renameFiles, out, plusOneNumber);
    }

    public void changeTemplateInt(String newTemplate, boolean renameFiles, Writer out,
            boolean newPlusOne) throws Exception {
        changeLocAndTemplate(getFolderLoc(), newTemplate, renameFiles, out,newPlusOne);
    }

    public void changeLocAndTemplate(String newFolder, String newTemplate, boolean renameFiles,
            Writer out, boolean newPlusOne) throws Exception {

        DiskMgr oldDM         = disk;
        File    oldFolderPath = getFolderPath();

        sites = null;  //in case anything changed, will force recalc
        int colonPos = newFolder.indexOf(":");
        if (colonPos <= 0) {
            throw new Exception("changeLocAndTemplate requires a location with disk manager name followed by colon");
        }

        String disk2 = newFolder.substring(0, colonPos);
        String destPath = newFolder.substring(colonPos + 1);
        DiskMgr dm2 = DiskMgr.getDiskMgr(disk2); // throws exception if not found
        File newFolderPath = dm2.getFilePath(destPath);

        // lets clean up the template a bit....
        // remove spaces just in case some got on there
        newTemplate = cleanUpTemplate(newTemplate);
        FracturedFileName newFracTemplate = FracturedFileName.parseTemplate(newTemplate);

        if (dm2 == disk && destPath.equals(pathInDisk) &&
                newFracTemplate.equals(fracTemplate) && newPlusOne == plusOneNumber) {
            // skip this trouble if setting to the same disk/path/name/plus it already at.
            return;
        }
        out.write("\n<li>Digest is ");
        HTMLWriter.writeHtml(out, digest);
        out.write("</li>");
        out.write("\n<li>hasFolder() is "+hasFolder()+"</li>");
        out.write("\n<li>renameFiles is "+renameFiles+"</li>");
        out.write("\n<li>hasTemplate() is "+hasTemplate()+"</li>");

        if (hasFolder() && renameFiles && hasTemplate()) {

            FracturedFileName oldTemplate = fracTemplate;
            if (newFracTemplate.equals(fracTemplate) && newPlusOne != plusOneNumber) {
                // if we are not changing the template at the same time, we need
                // to
                // first move the files to a dummy name, so that number change
                // problems do
                // not clash
                FracturedFileName nonClashTemplate = fracTemplate.copy();
                nonClashTemplate.prePart = "~tmp~" + nonClashTemplate.prePart;
                for (NewsFile nf : getFiles()) {
                    if (nf.isDownloaded()) {
                        out.write("\n<li>renaming file ");
                        HTMLWriter.writeHtml(out, nf.getFileName());
                        out.write("</li>");
                        out.flush();
                    }
                    nf.renameFracDeluxe(oldFolderPath, oldTemplate, plusOneNumber, oldFolderPath,
                            nonClashTemplate, plusOneNumber);
                }
                fracTemplate = nonClashTemplate;
                oldTemplate = nonClashTemplate;
            }

            // clear out the cached pattern record
            samplePattern = null;
            for (NewsFile nf : getFiles()) {
                if (nf.isDownloaded()) {
                    out.write("\n<li>moving file ");
                    HTMLWriter.writeHtml(out, nf.getFileName());
                    out.write("</li>");
                    out.flush();
                }
                nf.renameFracDeluxe(oldFolderPath, oldTemplate, plusOneNumber, newFolderPath,
                        newFracTemplate, newPlusOne);
            }
            samplePattern = null;
        }
        disk = dm2;
        setRelativePath(destPath);
        out.write("\n<li>relative path now set to "+destPath+"</li>");
        fracTemplate = newFracTemplate;
        plusOneNumber = newPlusOne;
        // forces it to recalculate if needed
        specialTokenIndex = -2;

        out.write("\n<li>refreshing disk to memory "+oldFolderPath+"</li>");
        //update the disk representation in memory
        oldDM.refreshDiskFolder(oldFolderPath);
        out.write("\n<li>refreshing disk to memory "+newFolderPath+"</li>");
        dm2.refreshDiskFolder(newFolderPath);
        out.write("\n<li>DONE refreshing disk folder</li>");

    }



    private String cleanUpTemplate(String origTemplate) {
        String newTemplate = origTemplate.trim();

        // lowercase the file extension if necessary
        int pos = newTemplate.indexOf(".JPG");
        if (pos == newTemplate.length() - 4) {
            newTemplate = newTemplate.substring(0, pos) + ".jpg";
        }

        pos = newTemplate.indexOf(".jpg");
        if (pos == newTemplate.length() - 4) {
            // if this is a JPG template, find the last dollar sign
            int lastNumPos = newTemplate.lastIndexOf("$", pos);
            if (lastNumPos > 0) {
                String patternPart = newTemplate.substring(0, lastNumPos);

                // remove any space that might exist between pattern and number
                newTemplate = patternPart.trim() + newTemplate.substring(lastNumPos);
            }

        }

        //eliminate parens
        StringBuffer sb = new StringBuffer();
        for (int i=0; i<newTemplate.length(); i++) {
            char ch = newTemplate.charAt(i);
            if (ch<' ') {
                //ignore it
            }
            else if (ch>='a' && ch<='z') {
                sb.append(ch);
            }
            else if (ch>='A' && ch<='Z') {
                sb.append(ch);
            }
            else if (ch>='0' && ch<='9') {
                sb.append(ch);
            }
            else if (ch=='_' || ch=='-' || ch=='!' || ch=='$' || ch=='.') {
                sb.append(ch);
            }
            else {
                //ignore all other characters
            }
        }

        return sb.toString();
    }

    public String getSampleFilePattern() throws Exception {
        if (samplePattern == null) {
            String sampleFileName = getSampleFileName();
            if (sampleFileName != null) {
                samplePattern = getFilePattern(sampleFileName);
            }
            else {
                System.out.println("Found bunch with NO sample file name: "+digest);
                //need to set this to avoid reattempting many times to generate
                samplePattern = "unknown";
            }
        }
        return samplePattern;
    }

    public boolean hasFolder() {
        File proposed = getFolderPath();
        return (proposed.exists());
    }
    
    public void createFolderIfReasonable() {
        if (pathInDisk==null) {
            pathInDisk = Long.toString( System.currentTimeMillis() ).substring(4);
        }
        if (pathInDisk.length()<4) {
            //add an arbitrary thing to make this more unique if the path is short or not there
            pathInDisk = pathInDisk + Long.toString( System.currentTimeMillis() ).substring(7);
        }
        File proposed = getFolderPath();
        proposed.mkdirs();
    }

    public File getFolderPath() {
        if (!pathInDisk.endsWith("/")) {
            throw new RuntimeException("getFolderPath somehow got a path without a slash on end: ("+pathInDisk+")");
        }
        return disk.getFilePath(pathInDisk);
    }

    public String getFolderLoc() {
        if (!pathInDisk.endsWith("/")) {
            throw new RuntimeException("getFolderLoc somehow got a path without a slash on end: ("+pathInDisk+")");
        }
        return disk.diskName + ":" + pathInDisk;
    }

    public void changeFolder(String newFolder, boolean moveFiles) throws Exception {
        while (newFolder.endsWith(".")) {
            newFolder = newFolder.substring(0,newFolder.length()-1);
        }
        changeFolder(newFolder, moveFiles, new org.workcast.streams.NullWriter());
    }

    public static boolean isPathReasonable(String newFolder) throws Exception {
        int colonPos = newFolder.indexOf(":");
        if (colonPos <= 0) {
            return false;
        }
        String disk2 = newFolder.substring(0, colonPos);
        DiskMgr dm2 = DiskMgr.getDiskMgrOrNull(disk2);
        return (dm2!=null);
    }

    public void changeFolder(String newFolder, boolean moveFiles, Writer out) throws Exception {
        try {
            out.write("\n<li>Change folder, and movefiles="+moveFiles+"</li>");
            out.write("\n<li>old folder: "+pathInDisk+"</li>");
            out.write("\n<li>new folder: "+newFolder+"</li>");

            sites = null;  //will force recalc
            if (!newFolder.endsWith("/")) {
                newFolder = newFolder + "/";
            }
            int colonPos = newFolder.indexOf(":");
            if (colonPos <= 0) {
                throw new Exception("changeFolder requires a disk manager name followed by colon");
            }
            String disk2 = newFolder.substring(0, colonPos);
            String destPath = newFolder.substring(colonPos + 1);
            DiskMgr dm2 = DiskMgr.getDiskMgr(disk2); // throws exception if not found

            if (dm2 == disk && destPath.equals(pathInDisk)) {
                // skip this trouble if setting to the same folder it already is at.
                out.write("\n<li>Skipping the move because it appears to already be there.</li>");
                return;
            }

            if (moveFiles && hasTemplate()) {
                List<NewsFile> fileList = getFiles();
                out.write("\n<li>Found "+fileList.size()+" files to move.</li>");
                for (NewsFile nf : fileList) {
                    if (nf.isDownloaded()) {
                        out.write("<li>moving file ");
                        HTMLWriter.writeHtml(out, nf.getFileName());
                        out.write("</li>");
                        out.flush();
                        System.out.println("before move file: "+destPath+" - "+System.currentTimeMillis());
                        nf.moveFile(dm2, destPath, true);
                        System.out.println("after move file: "+destPath+" - "+System.currentTimeMillis());
                    }
                }
            }
            DiskMgr dm1 = disk;
            String sourcePath = pathInDisk;
            disk = dm2;
            setRelativePath(destPath);

            dm1.refreshDiskFolder(dm1.getFilePath(sourcePath));
            dm2.refreshDiskFolder(dm2.getFilePath(destPath));
            out.write("\n<li>final folder: "+pathInDisk+"</li>");
        }
        catch (Exception e) {
            out.write("Exception encountered - "+e.toString());
            throw e;
        }
    }

    // This is where we keep all the ideas about how to automatically guess the
    // file name. yEnc is standardized, so we can use that.
    private String guessFileTemplate() {
        String tokPattern = tokenFill();
        String lcPattern = tokPattern.toLowerCase();

        if (fracTemplate != null && !fracTemplate.isEmpty()) {
            // don't do anything if there is already a file temaplate
            return fracTemplate.getBasicName();
        }
        String quotedSpan = getLastQuotedSpan(tokPattern);
        if (quotedSpan!=null && quotedSpan.length()>4) {
            String lastFour = quotedSpan.substring(quotedSpan.length()-4);
            //All yenc cases should be handled by this since yenc requires a quoted span.
            if (lastFour.equalsIgnoreCase(".jpg") || lastFour.equalsIgnoreCase(".zip")  || lastFour.equalsIgnoreCase(".jpeg")) {
                return quotedSpan;
            }
        }

        //handle the case where the tokPattern is nothing but the name, or end with name
        if (lcPattern.endsWith("jpg")) {
            int spacePos = tokPattern.lastIndexOf(" ");
            if (spacePos >= 0) {
                return tokPattern.substring(spacePos + 1);
            }
        }
        int jpgPos = lcPattern.indexOf(".jpg");
        if (jpgPos > 0) {

            //there is a particular case where it specifically mentions the File number
            int specialStart = tokPattern.indexOf("File $0 of $1");
            if (specialStart > 0 && specialStart + 16 < jpgPos + 4) {
                return tokPattern.substring(specialStart + 16, jpgPos + 4);
            }

            //search for the beginning of the file name.
            int spacePos = tokPattern.lastIndexOf(" ", jpgPos);
            if (spacePos >= 0 && spacePos < jpgPos - 3) {
                return tokPattern.substring(spacePos + 1, jpgPos + 4);
            }
        }
        return tokPattern;
    }

    /**
    * Searches for a pair of quotes, starting with the last quote
    * and the second to last quote in the line.  If found
    * returns the span of characters between them
    */
    private String getLastQuotedSpan(String line) {
        int endPos = line.lastIndexOf("\"");
        if (endPos < 0) {
            return null;
        }
        int startPos = line.lastIndexOf("\"", endPos - 1);
        if (startPos < 0) {
            return null;
        }
        return line.substring(startPos + 1, endPos);
    }

    public void deleteAllFiles() throws Exception {
        for (NewsFile nf : getFiles()) {
            nf.deleteFile();
        }
    }

    public void clearArticles() throws Exception {
        for (NewsArticle art : getArticles()) {
            art.clearMsgBody();
        }
    }

    public static void trackMovedFiles(String oldPath, String oldPattern, String newPath,
            String newPattern) throws Exception {
        NewsActionTrack nat = new NewsActionTrack(oldPath, oldPattern, newPath, newPattern);
        nat.addToFrontOfHigh();
    }

    /**
     * The challenge is to figure out how to point a bunch at a new location.
     * The file template might expand into multiple file patterns.
     * We have at hand only a single file pattern, if you just set the template
     * to the pattern, you run the risk that you distoirt the template, so that it
     * fails to handle multiple file patterns, and causing files to write over each
     * other.
     */

    public static void trackMovedFilesInternal(Writer out, String oldPath, String oldPattern,
            String newPath, String newPattern) throws Exception {
        int count = 0;
        oldPattern = oldPattern.trim();
        out.write("\nTrackPattern: " + oldPath + oldPattern + " --> " + newPath + newPattern);
        String oldSymbol = oldPath + oldPattern;
        for (NewsBunch aBunch : NewsGroup.getAllBunches()) {
            PosPat foundpp = null;
            for (PosPat pp : aBunch.getPosPatList()) {
                if (oldSymbol.equalsIgnoreCase(pp.getSymbol())) {
                    foundpp =  pp;
                }
            }
            if (foundpp!=null) {
                NewsFile aFile = aBunch.getFiles().get(0);
                String fileName = aFile.getFileName();
                String filePatt = getFilePattern(fileName).trim();
                if (oldPattern.equalsIgnoreCase(filePatt)) {
                    // todo: figure out how to handle when patterns are
                    // different
                    if (!oldPattern.equalsIgnoreCase(newPattern)) {
                        String rest = aBunch.getTemplate().substring(filePatt.length());
                        aBunch.changeTemplate(newPattern + rest, false);
                    }
                    aBunch.changeFolder(newPath, false);
                    out.write("\n    " + aBunch.getTemplate() + " == " + aBunch.tokenFill());
                    count++;
                }
            }
        }
        out.write("\n    " + count + " patterns found total.\n");
    }


    /**
     * The news header is parsed of all numbers, and tokens replace those.
     * Within the bunch, tokens can have different numbers for different files.
     * There is a special token, and that is the one that distinguishes files in
     * a set. Is it the first token ($0) or a later token (such as $5). This is
     * important for the 'plusOneNumber' feature which adds one to the value
     * that numbers the files within a set (usually only for index files).
     *
     * @return the token index that must be treated specially. Returns 0 for the
     *         first token, 1 for the second, and so on. Returns -1 if there is
     *         no token at all.
     */
    public int getSpecialTokenIndex() {
        if (specialTokenIndex < -1) {
            specialTokenIndex = fracTemplate.prePart.length();
        }
        return specialTokenIndex;
    }

    public static int findSpecialTokenIndex(String template) {
        int pos = template.indexOf(".jpg");
        if (pos < 0) {
            return -1;
        }

        int lastNumPos = template.lastIndexOf("$", pos);
        if (lastNumPos < 0) {
            return -1;
        }

        char ch = template.charAt(lastNumPos + 1);
        if (ch >= '0' && ch <= '9') {
            return ch - '0';
        }
        throw new RuntimeException(
                "Malformed template has a dollarsign but does not have a digit after it: "
                        + template);
    }
    
    private static String nullString = "";
    
    public static String[] getTemplateParts(String template) {
        String[] ret  = new String[3];
        int lastDollarPos = template.lastIndexOf("$");
        if (lastDollarPos>=0) {
            ret[0] = template.substring(0,lastDollarPos);
            ret[1] = template.substring(lastDollarPos,lastDollarPos+2);
            ret[2] = template.substring(lastDollarPos+2);
        }
        else {
            ret[0] = template;
            ret[1] = nullString;
            ret[2] = nullString;
        }
        return ret;
    }

    public static String getFilePattern(String fileName) {
        FracturedFileName ffn = FracturedFileName.parseFile(fileName);
        return ffn.prePart;
    }

    public static String[] getFileNameParts(String fileName) {

        String[] parts = new String[3];

        //if a null string was passed in, remain well behaved
        if (fileName==null || fileName.length()==0) {
            parts[0] = "";
            parts[1] = "";
            parts[2] = "";
            return parts;
        }
        // Now get the pattern from the file name
        // find the last numeral
        int pos = fileName.length() - 1;
        char ch = fileName.charAt(pos);
        while (pos > 0 && (ch < '0' || ch > '9')) {
            pos--;
            ch = fileName.charAt(pos);
        }

        //handle the case where no numeral was found at all, we just
        //split the file extension as the tail, and everything else pattern
        if (pos==0) {
            parts[1] = "";
            pos = fileName.lastIndexOf(".");
            if (pos>=0) {
                parts[0] = fileName.substring(0,pos);
                parts[2] = fileName.substring(pos);
                return parts;
            }

            //handle case where there is no period at all
            parts[0] = fileName;
            parts[2] = "";
            return parts;
        }

        // now, attempt to recognize and ignore file names with a hyphen-numeral
        // at the end. For example, best6789.jpg equals best6789-1.jpg
        if (pos > 3) {
            char tch = fileName.charAt(pos - 2);
            if (fileName.charAt(pos - 1) == '-' && (tch >= '0' && tch <= '9')) {
                pos = pos - 2;
                ch = tch;
            }
        }

        int tailBegin = pos + 1;

        int digitLimit = 2; // produces three digits max
        while (digitLimit > 0 && pos > 0 && ch >= '0' && ch <= '9') {
            pos--;
            digitLimit--;
            ch = fileName.charAt(pos);
        }

        // special case
        if (ch < '0' || ch > '9') {
            pos++;
        }

        // trim the exclamation mark if this is a negative, note that this
        // works only if the exclamation is just before the number.
        // Exclamation in other positions will lead to a separate, unique pattern
        if (pos > 0) {
            ch = fileName.charAt(pos - 1);
            if ('!' == ch) {
                pos--;
            }
        }

        parts[0] = fileName.substring(0, pos);
        parts[1] = fileName.substring(pos, tailBegin);
        parts[2] = fileName.substring(tailBegin);
        return parts;
    }

    public void touch() {
        lastTouch = System.currentTimeMillis();
    }

    public Vector<PosPat> getPosPatList() throws Exception {
        Vector<PosPat> tsites = sites;
        if (tsites!=null) {
            return tsites;
        }
        tsites = new Vector<PosPat>();
        if (fracTemplate == null || fracTemplate.isEmpty()
                || pathInDisk == null || pathInDisk.length()==0 ) {
            //without a template or path we can not find any of them, return empty
            sites = tsites;
            return tsites;
        }
        String path = disk + ":" + pathInDisk;
        Hashtable<String, PosPat> pathSet = new Hashtable<String, PosPat>();
        for (NewsFile nf : getFiles()) {
            String pattern = nf.getPattern();
            String loc = path + pattern;
            if (!pathSet.containsKey(loc)) {
                pathSet.put(loc, new PosPat(disk, pathInDisk, pattern));
            }
        }
        for (PosPat aLoc : pathSet.values()) {
            tsites.add(aLoc);
        }
        sites = tsites;
        return tsites;
    }

    /**
     * Given a filter string, returns the subset of the passed in bunches
     * which has an element that contains that filter value in either
     * the digest, the location, or the extra tags.
     */
    static public List<NewsBunch> filterThese(List<NewsBunch> src, String filter) {
        List<NewsBunch> filteredPatterns = new Vector<NewsBunch>();
        if (filter!=null && filter.length()>0) {
            for (NewsBunch tpatt : src) {
                if (tpatt.digest.indexOf(filter)>=0) {
                    filteredPatterns.add(tpatt);
                }
                else if (tpatt.getFolderLoc().indexOf(filter)>=0) {
                    filteredPatterns.add(tpatt);
                }
                else if (tpatt.extraTags!=null && tpatt.extraTags.indexOf(filter)>=0) {
                    filteredPatterns.add(tpatt);
                }
            }
        }
        return filteredPatterns;
    }

    static public List<NewsBunch> filterSort(List<NewsBunch> src,
            String filter,String sort, NewsGroup newsGroup) throws Exception {

        List<NewsBunch> filteredPatterns = filterThese(src,filter);
        if ("id".equals(sort)) {
            NewsBunch.sortByArticleId(filteredPatterns);
        } else if ("count".equals(sort)) {
            NewsBunch.sortByLocalFile(filteredPatterns, newsGroup.defaultDiskMgr);
        } else if ("recent".equals(sort)) {
            NewsBunch.sortByLastTouch(filteredPatterns);
        } else if ("file".equals(sort)) {
            NewsBunch.sortByTemplate(filteredPatterns);
        } else if ("path".equals(sort)) {
            NewsBunch.sortByPath(filteredPatterns);
        } else {
            NewsBunch.sortByPattern(filteredPatterns);
        }
        return filteredPatterns;
    }


    public String getSender() throws Exception {
        if (sender==null) {
            List<NewsArticle> arts = getArticles();
            if (arts.size()>0) {
                NewsArticle art = arts.get(0);
                sender = art.optionValue[1];
            }
        }
        return sender;
    }

    public JSONObject getJSON() throws Exception {
        JSONObject rec = new JSONObject();
        rec.put("key", bunchKey);
        rec.put("digest", digest);
        rec.put("digestB", tokenFill());
        rec.put("count", count);
        rec.put("cTotal", fileTotal);
        rec.put("cComplete", fileComplete);
        rec.put("cDown", fileDown);
        rec.put("folderLoc", getFolderLoc());
        rec.put("hasTemplate", hasTemplate());
        rec.put("stateColor", getStateColor());
        rec.put("minId", minId);
        rec.put("maxId", maxId);
        rec.put("lastTouch", lastTouch);
        rec.put("template", getTemplate());
        rec.put("state", pState);
        rec.put("color", getStateColor());
        rec.put("lastTouch", lastTouch);
        rec.put("sender", getSender());


        JSONArray pplist = new JSONArray();
        JSONArray patList = new JSONArray();
        if (hasTemplate()) {
            Vector<PosPat> vpp = getPosPatList();
            for (PosPat ppinst : vpp) {
                patList.put(ppinst.getPattern());
                pplist.put(ppinst.getSymbol());
            }
        }
        rec.put("patts", patList);
        rec.put("posPats", pplist);

        if (failureMessage!=null) {
            rec.put("failure", failureMessage.toString());
        }
        rec.put("template", getTemplate());
        rec.put("plusOne", plusOneNumber);
        rec.put("isYEnc", isYEnc);
        rec.put("shrinkFiles", shrinkFiles);
        rec.put("seekExtent", seekExtent);
        return rec;
    }

    public void updateFromJSON(JSONObject objIn) throws Exception {
    	if (objIn.has("folderLoc") || objIn.has("template")) {
    		boolean changed = false;
    		String folderLoc = getFolderLoc();
    		if (objIn.has("folderLoc")) {
    			String newFolderLoc = objIn.getString("folderLoc");
    			if (!newFolderLoc.equals(folderLoc)) {
    				changed = true;
    				folderLoc = newFolderLoc;
    			}
    		}
    		String template = getTemplate();
    		if (template==null)  {
    			template = "";
    		}
    		if (objIn.has("template")) {
    			String newTemplate = objIn.getString("template");
    			if (!newTemplate.equals(folderLoc)) {
    				changed = true;
    				template = newTemplate;
    			}
    		}
    		if (changed) {
    			PrintWriter pw = new PrintWriter(System.out);
    			changeLocAndTemplate(folderLoc, template, true, pw, false);
    			pw.flush();
    		}
    	}
    	if (objIn.has("state")) {
	    	changeState(objIn.getInt("state"));
    	}
    }
}
