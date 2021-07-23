package com.purplehillsbooks.photegrity;

import java.io.Writer;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * An action that finds the range of articles on the ends of 
 * the range, and makes sure that the 100 articles around the ends
 * are filled in.
 * 
 * That is, say a bunch has 12 articles from 30100 to 31500, the highest
 * number is 31500 while the lowest number is 30100.  What this will do, is start
 * searching from the highest for higher articles and reaching 50 fifty articles 
 * higher.  When 50 articles higher are filled in, it search down to cover 50 articles
 * lower than the highest.   then it does the opposite on the low end: searching lower
 * until there are 50 articles filled in lower than the lowest, and then it searches
 * up 50 from the lowest.
 * 
 * The thing to keep in mind is that as it searches higher, it might find a higher article
 * that belongs to the group.  That should reset things to start all over with the approach.
 * So ... we remember nothing but the failures.  Each time we start by finding the highest
 * and seeing if there are 100 articles filled in around that.   If so, look at the lowest, 
 * and fill 100 in around that.
 * 
 * Eventually the bunch will become stable, with a solid range of 100 on each end of the 
 * range filled in.   This is to find related articles that usually come before or after 
 * the main group, like a single JPG at the end of a MP4 file.
 */

public class NewsActionProbeEnds extends NewsAction {
    private NewsBunch seeker;
    private HashSet<Long> giveUpList = new HashSet<Long>();

    private NewsGroup ng;
    long highArt = -1;
    long lowArt = -1;
    long halfSpanSize = 50;
    int percentComplete = 0;
    private List<Long> checkList = null;

    public NewsActionProbeEnds(NewsBunch _seeker) throws Exception {
        seeker = _seeker;
        seeker.isSeeking = true;
        seeker.pState = NewsBunch.STATE_SEEK;
        ng = NewsGroup.getCurrentGroup();
        seeker.touch();
    }

    /**
     * Convenient static method creates and queues an instance
     */
    public static void start(NewsBunch _seeker) throws Exception {
        NewsActionProbeEnds nasp = new NewsActionProbeEnds(_seeker);
        nasp.addToFrontOfHigh();
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        if (!NewsGroup.connect) {
            //no connection, so cancel, and leave right away
            seeker.pState = NewsBunch.STATE_INTEREST;
            seeker.isSeeking = false;
            return;
        }

        seeker.touch();
        //first make sure we have not been turned off
        //can be seeking OR downloading, starting to download
        //should not terminate the seeking.
        if (seeker.pState != NewsBunch.STATE_SEEK) {
            // newsPattern is no longer wanting seeking
            out.write("\nNewsGroup Seeking Cancelled: ");
            HTMLWriter.writeHtml(out, seeker.tokenFill());
            out.write("<br/>");
            return;
        }

        determineCheckList();

        //if we don't need anything, then we are done.
        if (checkList.size()==0) {
            seeker.isSeeking = false; // set this off
            if (seeker.pState == NewsBunch.STATE_SEEK) {
                seeker.pState = NewsBunch.STATE_INTEREST;
            }
            if (seeker.hasTemplate()) {
                seeker.getFiles(); // resets the statistics
            }
            out.write("\nSeeking complete for "+seeker.tokenFill());
            return;
        }

        out.write("\nProbing "+checkList.size()+" more for "+seeker.tokenFill());
        doit(out);

        //seeking takes priority over downloading
        addToEndOfMid();
    }

    private boolean doit(Writer out) throws Exception {
        long deadline = System.currentTimeMillis() + 10000; // ten seconds
        //we are going to iterate this list in many small segments limited by time.
        //so we can't use the normal approach without an iterator
        while (checkList.size()>0) {
            long artNum = checkList.remove(0);
            if (ng.avoidDownloadNow(artNum)) {
                continue;
            }
            if (ng.hasArticle(artNum)) {
                //something else may have gotten it in the mean time
                //but ... not possible on this thread and we just 
                //created the list.  Probably not possible.
                continue;
            }
            out.write("\nProbing " + artNum + " -- ");
            out.flush();
            try {
                NewsArticle art = ng.getArticleOrNull(artNum);
                out.write(art.getHeaderSubject());
            }
            catch (Exception e) {
                out.write("fail: "+UtilityMethods.getErrorString(e));
                giveUpList.add(artNum);
                NewsArticleError nae = ng.getError(artNum);
                if (nae == null) {
                    out.write("\nSTRANGE ... got a failure but the news group did not record it!<br/>");
                }
                else {
                    out.write("\n    >" + nae.status());
                }
            }
            out.flush();
            if (System.currentTimeMillis() > deadline) {
                return false;
            }
        }
        return true;

    }


    private void determineCheckList() throws Exception {
        highArt = 0;
        lowArt = 999999999;
        
        for (NewsArticle art : seeker.getArticles()) {
            
            if (art.articleNo>highArt) {
                highArt = art.articleNo;
            }
            if (art.articleNo<lowArt) {
                lowArt = art.articleNo;
            }
        }
        
        checkList = new ArrayList<Long> ();
            
        for (long testVal = highArt+this.halfSpanSize; testVal>highArt; testVal--) {
            conditionallyAdd(testVal);
        }
        for (long testVal = lowArt-this.halfSpanSize; testVal<lowArt; testVal++) {
            conditionallyAdd(testVal);
        }
        for (long testVal = highArt; testVal>highArt-this.halfSpanSize; testVal--) {
            conditionallyAdd(testVal);
        }
        for (long testVal = lowArt; testVal<lowArt+this.halfSpanSize; testVal++) {
            conditionallyAdd(testVal);
        }
        percentComplete = (200-checkList.size())/2;
    }
    
    private void conditionallyAdd(long artNum) {
        //our local set is relatively small, so check that first
        //and there will be lots of overlapping sweeps
        if (checkList.contains(artNum)) {
            //we already have this in the list (in case overlapping ends)
            return;
        }
        if (giveUpList.contains(artNum)) {
            //we know already not to check this one
            return;
        }
        if (ng.avoidDownloadNow(artNum)) {
            //since the giveUpList is smaller than the newsGroup
            //it is worth remembering this in the giveUpList.
            //faster checking on later passes
            giveUpList.add(artNum);
            return;
        }
        if (ng.hasArticle(artNum)) {
            //since the giveUpList is smaller than the newsGroup
            //it is worth remembering this in the giveUpList.
            //faster checking on later passes
            giveUpList.add(artNum);
            return;
        }
        checkList.add(artNum);
    }

    public String getStatusView() throws Exception {
        return "Probe ends "+percentComplete+"%  "+seeker.digest;
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        jo.put("verb", "Probe Ends");
        if (checkList!=null) {
            jo.put("total", checkList.size());
        }
        jo.put("digest", seeker.digest);
        return jo;
    }

}
