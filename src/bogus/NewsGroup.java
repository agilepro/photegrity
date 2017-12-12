package bogus;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Hashtable;
import java.util.List;
import java.util.Properties;
import java.util.Vector;

import org.apache.commons.net.nntp.NewsgroupInfo;
import com.purplehillsbooks.streams.CSVHelper;

/**
 * represents a news group on a news server this is a singleton class
 */

public class NewsGroup {
    public String groupName = "alt.binaries.pictures.erotica.latina";
    public DiskMgr defaultDiskMgr;
    public File containingFolder;

    public long firstArticle;
    public long lastArticle;
    public long articleCount;

    public long lowestFetched;
    public long highestFetched;

    public long displayWindow = 100000;
    public long lowestToDisplay = 0;
    
    public int phase = 0;
    public int step = 0;
    public int failCount = 0;

    private List<NewsArticle> articles;
    private Hashtable<Long, NewsArticle> index;
    private Hashtable<Long, NewsArticleError> errorIndex;
    public static NewsSession session;
    public static boolean connect = true;
    private static NewsGroup selectedGroup;
    private static Hashtable<String, NewsBunch> bunchIndex = new Hashtable<String, NewsBunch>();
    private static Hashtable<Long, NewsBunch> fastIndex = new Hashtable<Long, NewsBunch>();
    

    public boolean isReady = false;  //flag says whether the contents are OK

    /**
     * this is the starting point for most pages, the server has a selected
     * group loaded into memory. Changing groups is a bigger deal
     */
    public static NewsGroup getCurrentGroup() throws Exception {
        if (session == null) {
            session = NewsSession.getNewsSession();
        }
        if (selectedGroup == null) {
            selectedGroup = new NewsGroup();
        }
        return selectedGroup;
    }

    /*
     * A file called "news.properties" will occur in some disk mgr folders It
     * contains the properties for connecting to a news group
     */
    public synchronized void openNewsGroupFile(File propertyFile) throws Exception {
        try {
            openNewsGroupFile(propertyFile, true);
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }


    public synchronized void openNewsGroupFile(File propertyFile, boolean doConnect) throws Exception {

        if (!propertyFile.exists()) {
            throw new Exception(
                    "openNewsGroupFile requires a properties file:  this one does not exist: "
                            + propertyFile);
        }

        connect = doConnect;

        // first, clear everything out and GC as necessary
        System.out.println("openNewsGroupFile: clearArticles");

        clearArticles();
        System.out.println("openNewsGroupFile: reset");
        reset();
        System.out.println("openNewsGroupFile: System.gc");
        System.gc();

        containingFolder = propertyFile.getParentFile();
        Properties newProps = new Properties();
        System.out.println("openNewsGroupFile: newProps.load");
        newProps.load(new FileInputStream(propertyFile));

        groupName = newProps.getProperty("groupName");
        System.out.println("openNewsGroupFile: getGroupInfoFromServer");
        getGroupInfoFromServer();
        System.out.println("openNewsGroupFile: loadCache");
        loadCache();
        System.out.println("openNewsGroupFile: recalcStats");
        recalcStats();
        System.out.println("openNewsGroupFile: NewsBackground.startNewsThread");
        NewsBackground.startNewsThread(containingFolder);
        System.out.println("openNewsGroupFile: Stats.initializeStats");
        Stats.initializeStats(containingFolder);

        //initialize the background preparation
        System.out.println("openNewsGroupFile: naip.addToQueueHigh");
        NewsActionIndexPrep naip = new NewsActionIndexPrep();
        naip.addToFrontOfHigh();
        System.out.println("openNewsGroupFile: all done");
    }

    /**
     * Closes the file, and clean up all the memory
     */
    public void closeNewsGroupFile() throws Exception {
	    clearArticles();
	    defaultDiskMgr = null;
	    selectedGroup = null;
	    session = null;
	    System.gc();
	    getCurrentGroup();
    }

    public synchronized void clearArticles() throws Exception {
        isReady = false;

        //first make sure no processing is going on in background
        //and wait for current process to complete (12 seconds).
        NewsAction.shutDownProcessing();
        int count=100;
        while (count-- > 0 &&  NewsAction.active) {
            Thread.sleep(120);
        }
        articles.clear();
        index.clear();
        bunchIndex.clear();
        fastIndex.clear();
        NewsBunch.groupIsFullyIndexed = false;
    }

    public static List<NewsBunch> getUnhiddenBunches() {
        Vector<NewsBunch> ret = new Vector<NewsBunch>();
        for (NewsBunch nbunch : bunchIndex.values()) {
            if (nbunch.pState != NewsBunch.STATE_HIDDEN && nbunch.count > 0) {
                ret.add(nbunch);
            }
        }
        // need to sort them here
        return ret;
    }
    public static List<NewsBunch> getAllBunches() {
        Vector<NewsBunch> ret = new Vector<NewsBunch>();
        for (NewsBunch npatt : bunchIndex.values()) {
            ret.add(npatt);
        }
        // need to sort them here
        return ret;
    }
    public static synchronized List<NewsBunch> findBunchesWithPattern(String oldPattern) throws Exception {
        oldPattern = oldPattern.trim();
        Vector<NewsBunch> retVal = new Vector<NewsBunch>();
        for (NewsBunch aBunch : NewsGroup.getAllBunches()) {
            //skip all the hidden ones
            if (aBunch.pState==NewsBunch.STATE_HIDDEN) {
                continue;
            }
            // note: a bunch may have more than one pattern ... this finds only
            // one
            for (PosPat pp : aBunch.getPosPatList()) {
                if (oldPattern.equalsIgnoreCase(pp.getPattern())) {
                    retVal.add(aBunch);
                }
            }
        }
        NewsBunch.groupIsFullyIndexed = true;
        return retVal;
    }

    
    
    public NewsGroup() throws Exception {
        reset();
    }

    public void reset() {
        firstArticle = 0;
        lastArticle = 0;
        articleCount = 0;
        articles = new Vector<NewsArticle>();
        index = new Hashtable<Long, NewsArticle>();
    }

    
    private void getGroupInfoFromServer() throws Exception {
        firstArticle = 0;
        lastArticle = 0;
        articleCount = 0;
        if (!connect) {
            return;
        }
        session.connect();
        NewsgroupInfo[] ngiList = session.client.listNewsgroups(groupName);
        if (ngiList.length == 0) {
            throw new Exception("Can't find a news group with the name (" + groupName
                    + ") on that server!");
        }
        if (ngiList.length > 1) {
            throw new Exception("Found more than one news group with the name (" + groupName
                    + ") on that server!  Are there wild cards in the name given?");
        }

        NewsgroupInfo ngi = ngiList[0];

        groupName = ngi.getNewsgroup();
        firstArticle = ngi.getFirstArticleLong();
        lastArticle = ngi.getLastArticleLong();
        articleCount = ngi.getArticleCountLong();
        session.disconnect();
    }

    public boolean hasArticle(long articleNo) {
        return (index.containsKey(new Long(articleNo)));
    }

    public boolean avoidDownloadNow(long articleNo) {
        NewsArticleError nae = getError(articleNo);
        if (nae == null) {
            return false;
        }
        return !nae.okToTryAgainNow();
    }

    public NewsArticle getArticleOrNull(long articleNo) throws Exception {
        Long lval = new Long(articleNo);
        NewsArticle art = index.get(lval);

        if (art != null) {
            return art;
        }

        NewsArticleError nae = getError(articleNo);
        if (nae != null) {
            if (!nae.okToTryAgainNow()) {
                // don't try again for an hour after an error
                throw new Exception("Article "+articleNo+" recently errored (1 hour), too soon to try again");
            }
        }

        setGroupOnSession();
        try {
            String[] optionValues = NewsArticle.parseHeader(articleNo);
            art = new NewsArticle(this, articleNo, optionValues);
        }
        catch (Exception e) {
            registerError(articleNo, e);
            throw new Exception("Unable to get article '" + articleNo + "'", e);
        }
        if (nae != null) {
            // if previously had an error, then clear that out since we have the
            // article now
            errorIndex.remove(articleNo);
        }
        registerArticle(lval, art);
        String patt = art.getDigest();
        if (patt != null) {
            NewsBunch npatt = getBunch(art.getDigest(), art.getFrom());
            npatt.addCount(articleNo);
            npatt.registerNewArticle();
        }
        if (articleNo<lowestFetched) {
            lowestFetched = articleNo;
        }
        if (articleNo>highestFetched) {
            highestFetched = articleNo;
        }
        return art;
    }

    public NewsArticleError getError(long artNo) {
        NewsArticleError val = errorIndex.get(artNo);
        return val;
    }

    public void clearError(long artNo) {
        errorIndex.remove(artNo);
    }

    public void registerError(long artNo, Exception e) {
        NewsArticleError val = errorIndex.get(artNo);
        if (val == null) {
            val = new NewsArticleError(artNo);
            errorIndex.put(artNo, val);
        }
        val.registerNewAttempt(UtilityMethods.getErrorString(e));
    }

    /**
    * register article must be synchronized to avoid causing concurrency issues
    */
    public synchronized void registerArticle(Long lval, NewsArticle art) {
        articles.add(art);
        index.put(lval, art);
    }

    public synchronized List<NewsArticle> getArticles() {
        Vector<NewsArticle> ret = new Vector<NewsArticle>();
        for (NewsArticle art : articles) {
            ret.add(art);
        }
        // Collections.sort(ret, new authSubComp());
        return ret;
    }

    public synchronized List<NewsArticle> getArticlesDigest(String dig, String from) {
        Vector<NewsArticle> ret = new Vector<NewsArticle>();
        for (NewsArticle art : articles) {
            if (dig.equals(art.getDigest()) && art.getFrom().equals(from)) {
                ret.add(art);
            }
        }
        Collections.sort(ret, new authSubComp());
        return ret;
    }

    public int getIndexSize() {
        return index.size();
    }

    public void setGroupOnSession() throws Exception {
        session.internalSetGroup(groupName);
    }

    public String getName() {
        return groupName;
    }

    public static void zeroCounts() {
        for (NewsBunch patt : bunchIndex.values()) {
            patt.count = 0;
        }
    }
    public void recalcStats() throws Exception {
        zeroCounts();
        highestFetched = 0;
        lowestFetched = 999999999999L;
        for (NewsArticle art : getArticles()) {
            long artNo = art.articleNo;
            if (artNo > highestFetched) {
                highestFetched = artNo;
            }
            if (artNo < lowestFetched) {
                lowestFetched = artNo;
            }
            NewsBunch npatt = getBunch(art.getDigest(), art.getFrom());
            npatt.addCount(artNo);
        }
    }

    public void clearOutBunch(String bunch, String from) throws Exception {
        NewsBunch npatt = getBunch(bunch, from);
        npatt.pState = NewsBunch.STATE_HIDDEN;
        for (NewsArticle art : getArticlesDigest(bunch, from)) {
            art.clearMsgBody();
        }
    }

    public void saveCacheCSV() throws Exception {
        File destFile = new File(containingFolder, groupName + ".news");
        File tempFile = new File(containingFolder, groupName + ".news.temp");
        if (tempFile.exists()) {
            tempFile.delete();
        }
        FileOutputStream fos = new FileOutputStream(tempFile);
        Writer fw = new OutputStreamWriter(fos, "UTF-8");

        for (NewsArticle art : getArticles()) {
            art.writeCacheLine(fw);
        }

        fw.flush();
        fw.close();

        if (destFile.exists()) {
            destFile.delete();
        }
        tempFile.renameTo(destFile);
    }

    public void saveErrorsCSV() throws Exception {
        File oldDestFile = new File(containingFolder, groupName + ".errs");
        File destFile = new File(containingFolder, groupName + ".err2");
        File tempFile = new File(containingFolder, groupName + ".err2.temp");
        if (tempFile.exists()) {
            tempFile.delete();
        }
        FileOutputStream fos = new FileOutputStream(tempFile);
        Writer fw = new OutputStreamWriter(fos, "UTF-8");

        for (NewsArticleError nae : errorIndex.values()) {
            nae.writeCacheLine(fw);
        }

        fw.flush();
        fw.close();

        if (destFile.exists()) {
            destFile.delete();
        }
        tempFile.renameTo(destFile);
        if (oldDestFile.exists()) {
            oldDestFile.delete();
        }
    }

    public void saveCache() throws Exception {
        LocalMapping.storeData(containingFolder);
        saveCacheCSV();
        saveErrorsCSV();
        saveBunchData();
        Stats.saveStats();
        recalcStats();
    }

    public void saveBunchData() throws Exception {
        File fileTemplate = new File(containingFolder, groupName + ".patt");
        File tempFile = new File(containingFolder, groupName + ".patt.temp");
        if (tempFile.exists()) {
            tempFile.delete();
        }
        FileOutputStream fos = new FileOutputStream(tempFile);
        Writer fw = new OutputStreamWriter(fos, "UTF-8");

        for (NewsBunch patt : bunchIndex.values()) {
            if (patt.count>0) {
                patt.writeCacheLine(fw);
            }
        }

        fw.flush();
        fw.close();

        if (fileTemplate.exists()) {
            fileTemplate.delete();
        }
        tempFile.renameTo(fileTemplate);
    }
    
    private synchronized void loadCache() throws Exception {
        LocalMapping.readData(containingFolder);
        articles = new Vector<NewsArticle>();
        index = new Hashtable<Long, NewsArticle>();
        errorIndex = new Hashtable<Long, NewsArticleError>();
        defaultDiskMgr = DiskMgr.getDiskMgr(containingFolder.getName());
        loadArticles();
        loadErrors();
        isReady = true;
    }

    private synchronized void loadArticles() throws Exception {

        File destFile = new File(containingFolder, groupName + ".news");
        if (!destFile.exists()) {
            // silently ignore this because it will create on save
            return;
        }
        FileInputStream fis = new FileInputStream(destFile);
        Reader fr = new InputStreamReader(fis, "UTF-8");

        System.out.println("starting loading news article");
        int count=0;
        List<String> values = CSVHelper.parseLine(fr);
        while (values != null) {
            long mem = Runtime.getRuntime().freeMemory();
            if (mem<20000000) {
                throw new Exception("Not enough memory to read this news file at line "+count+" ("+mem+")");
            }
            NewsArticle art = NewsArticle.createFromLine(this, values);
            if (art != null) {
                long artno = art.getNumber();
                articles.add(art);
                index.put(new Long(artno), art);
            }
            values = CSVHelper.parseLine(fr);
        }

        fr.close();
        sortArticles();
        NewsBunch.restoreData(this);
        recalcStats();
    }

    private void loadErrors() throws Exception {

        File destFile = new File(containingFolder, groupName + ".err2");
        if (!destFile.exists()) {
            // no new file exists, but check for an old format one and read that
            loadOldErrors();
            return;
        }
        FileInputStream fis = new FileInputStream(destFile);
        Reader fr = new InputStreamReader(fis, "UTF-8");

        List<String> values = CSVHelper.parseLine(fr);
        System.out.println("loading errors");
        while (values != null) {
            NewsArticleError nae = NewsArticleError.createFromLine(this, values);
            if (nae != null) {
                errorIndex.put(new Long(nae.articleNo), nae);
            }
            values = CSVHelper.parseLine(fr);
        }

        fr.close();
    }

    private void loadOldErrors() throws Exception {

        File destFile = new File(containingFolder, groupName + ".errs");
        if (!destFile.exists()) {
            // silently ignore this because it will create on save
            return;
        }
        FileInputStream fis = new FileInputStream(destFile);
        Reader fr = new InputStreamReader(fis, "UTF-8");

        List<String> values = CSVHelper.parseLine(fr);
        System.out.println("loading errors");
        while (values != null) {
            NewsArticleError nae = NewsArticleError.createFromOldLine(this, values);
            if (nae != null) {
                errorIndex.put(new Long(nae.articleNo), nae);
            }
            values = CSVHelper.parseLine(fr);
        }

        fr.close();
    }

    public synchronized void sortArticles() throws Exception {
        Collections.sort(articles, new authSubComp());
    }

    
    /**
     * Find a NewsBunch with a specific pattern
     * @param digest
     * @return
     * @throws Exception
     */
    public NewsBunch getBunch(String digest, String from) throws Exception {
        if (digest == null) {
            throw new Exception("null value passed for patter in getPattern");
        }
        String seed = digest;
        if (from!=null) {
            seed = digest + "|" + from;
        }
        NewsBunch foundBunch = bunchIndex.get(seed);
        if (foundBunch != null) {
            return foundBunch;
        }
        foundBunch = bunchIndex.get(digest);
        
        NewsBunch newBunch; 
        if (foundBunch==null) {
            //copy everything from the found one
            newBunch = new NewsBunch(this, digest, from);
        }
        else {
            newBunch = NewsBunch.copyCreate(foundBunch, from);
        }
        bunchIndex.put(seed, newBunch);
        fastIndex.put(new Long(newBunch.bunchKey), newBunch);
        return newBunch;
    }
    
    public NewsBunch findBunchByKey(long key) throws Exception {
        NewsBunch foundBunch = fastIndex.get(key);
        if (foundBunch != null) {
            return foundBunch;
        }
        throw new Exception("There is no bunch with the key "+key);
    }
    
    /**
     * Find all known bunches in a particular range
     * @return
     */
    public List<NewsBunch> getBunchesInRange() {
    	//fixing this up here, in case it was left at zero or something else wrong
    	if (lowestToDisplay<lowestFetched) {
    		lowestToDisplay = lowestFetched;
    	}
        List<NewsBunch> filteredBunches = new Vector<NewsBunch>();
        for (NewsBunch tBunch : getAllBunches()) {
            if (tBunch.minId>lowestToDisplay+displayWindow) {
                continue;
            }
            if (tBunch.maxId<lowestToDisplay) {
                continue;
            }
            filteredBunches.add(tBunch);
        }
        return filteredBunches;
    }

    /**
     * Find all the bunches in a range that match a pattern
     * @param filter
     * @return
     */
    public List<NewsBunch> getFilteredBunches(String filter) throws Exception {
        List<NewsBunch> filteredBunches = new Vector<NewsBunch>();
        for (NewsBunch tBunch : getBunchesInRange()) {
            if (tBunch.digest.indexOf(filter)>=0) {
            	filteredBunches.add(tBunch);
            }
            else if (tBunch.getSender().indexOf(filter)>=0) {
            	filteredBunches.add(tBunch);
            }
            else if (tBunch.extraTags!=null && tBunch.extraTags.indexOf(filter)>=0) {
            	filteredBunches.add(tBunch);
            }
        }
        return filteredBunches;
    }
    
    

    
    /**
     * sorts by subject (digest) then subject, then from
     */
    class authSubComp implements Comparator<NewsArticle> {
        public authSubComp() {

        }

        public int compare(NewsArticle o1, NewsArticle o2) {
            NewsArticle na1 = o1;
            NewsArticle na2 = o2;
            int val = na1.getDigest().compareTo(na2.getDigest());
            if (val != 0) {
                return val;
            }
            val = na1.getHeaderSubject().compareTo(na2.getHeaderSubject());
            if (val != 0) {
                return val;
            }
            val = na1.getHeaderFrom().compareTo(na2.getHeaderFrom());
            return val;
        }
    }

    public long takePhaseStep() throws Exception {

        step++;
        if (phase < 0) {
            phase = 1;
        }
        int factor = 1;
        for (int k = 1; k < phase; k++) {
            factor = factor * 2;
        }

        if (step >= factor) {
            phase++;
            factor = factor * 2;
            step = 0;
        }

        long span = lastArticle - firstArticle;
        long stepSize = span / factor;
        long half = stepSize / 2;

        long newPos = stepSize * step + half + firstArticle;

        if (newPos > lastArticle) {
            throw new Exception("Calculation is incorrect ... position is " + newPos
                    + " but last article is " + lastArticle + ".");
        }

        // failcount is incremented here, which is preserved if there is an
        // exception, zeroed if not
        // causes the routine to fetch the next article everytime a fetch fails,
        // better than retrying
        // the same thing over and over.
        failCount++;
        getArticleOrNull(newPos);
        failCount = 0;
        return newPos;
    }

    /**
     * Use this to eliminate articles earlier than the specified number
     * from the internal collection of articles.  Presumably, you have already
     * scanned them by this time, and this will free up memory and file space.
     */
    public void discardOldArticles(long earlyLimit) {
        Vector<NewsArticle> earlyOnes = new Vector<NewsArticle>();
        for (NewsArticle art : articles) {
            if (art.articleNo < earlyLimit) {
                earlyOnes.add(art);
            }
        }

        //now delete them
        for (NewsArticle art : earlyOnes) {
            if (art.articleNo < earlyLimit) {
                index.remove(art.articleNo);
                articles.remove(art);
            }
        }

        //now clean out the error entries
        Vector<Long> errorsToForget = new Vector<Long>();
        for (Long aNum : errorIndex.keySet()) {
            if (aNum < earlyLimit) {
                errorsToForget.add(aNum);
            }
        }
        for (Long gonner : errorsToForget) {
            errorIndex.remove(gonner);
        }
    }
    
    public List<GapRecord> getGaps(long start, long end) {
        boolean inGap = false;
        long lastGapStart = start;
        List<GapRecord> gapList = new ArrayList<GapRecord>();
        for (long i=start; i<end; i++) {
            boolean avail = this.hasArticle(i);
            if (avail) {
                if (inGap) {
                    inGap = false;
                    int gapSize = (int)(i - lastGapStart);
                    GapRecord.recordGap(gapList, gapSize, lastGapStart);
                }
            }
            else {
                if (!inGap) {
                    inGap = true;
                    lastGapStart = i;
                }
            }
        }
        if (inGap) {
            int gapSize = (int)(end - lastGapStart);
            GapRecord.recordGap(gapList, gapSize, lastGapStart);
        }
        return gapList;
    }
}
