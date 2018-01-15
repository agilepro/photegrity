package bogus;

import java.io.Writer;
import java.util.HashSet;
import java.util.Iterator;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * An action that goes and tries to find all the messages of a
 * particular bunch.  Bunch may be spread out all over the place
 * Start with "clues" those are received articles of the pattern.
 * What we know is that articles of the same pattern usually arrive
 * together, so start from the known articles, and look at articles
 * next to them.
 *
 * When to stop?  When we search (seekExtent) articles ahead of behind all
 * known articles, and there are gaps of (seekExtent) articles ahead and
 * behind all known articles with no matching articles in the gap.
 * seekExtent is 15 by default, but depends upon the NewsGroup.
 *
 * Sometimes groups of articles on one pattern get divided by
 * articles with a different pattern.  We need to then do a search
 * "out" from every known article.
 *
 * We need to track all the spans of articles that have been searched.
 * This is the "already checked" list, and it consists of a collection
 * integer pairs with the top and bottom number checked.  Every time
 * we check an article, we either expand a checked range, or we create
 * a new range.  In some cases checking an article will merge two ranges.
 *
 * Then, we walk through the list of known articles, and check 15 ahead and
 * 15 behind every article -- of course being careful to avoid requesting
 * anything from the server more than once because this will cause a lot
 * of overlap checking.
 *
 * This is all done in "chunks" of work that take no longer than 10 seconds
 * at a time, yielding background processing time to other actions.
 */

public class NewsActionSeekBunch extends NewsAction {
    private NewsBunch seeker;
    private HashSet<Long> giveUpList = new HashSet<Long>();
    private HashSet<Long> checkList = null;
    private Iterator<Long> checkListIter;  //we don't iterate all at once
    private int iterPosition;

    private NewsGroup ng;

    public NewsActionSeekBunch(NewsBunch _seeker) throws Exception {
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
        NewsActionSeekBunch nasp = new NewsActionSeekBunch(_seeker);
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
        if (seeker.pState != NewsBunch.STATE_SEEK && seeker.pState != NewsBunch.STATE_DOWNLOAD) {
            // newsPattern is no longer wanting seeking
            out.write("\nNewsGroup Seeking Cancelled: ");
            HTMLWriter.writeHtml(out, seeker.tokenFill());
            out.write("<br/>");
            return;
        }

        //see if we need initializing
        if (checkList==null) {
            //scan all the articles, and see what we need.
            determineCheckList();

            //if we don't need anything, then we are done.
            if (checkList.size()==0) {
                seeker.isSeeking = false; // set this off
                if (seeker.pState == NewsBunch.STATE_SEEK) {
                    seeker.pState = NewsBunch.STATE_SEEK_DONE;
                }
                if (seeker.hasTemplate()) {
                    seeker.getFiles(); // resets the statistics
                }
                out.write("\nSeeking complete for "+seeker.tokenFill());
                return;
            }

            out.write("\nSeeking "+checkList.size()+" more for "+seeker.tokenFill());
        }

        out.write("\n------ seeking pass ------ "+iterPosition+"/"+checkList.size());
        boolean finished = doit(out);
        if (finished) {
            //force a recalc next run
            checkList = null;
        }

        //seeking takes priority over downloading
        addToEndOfMid();
    }

    private boolean doit(Writer out) throws Exception {
        long deadline = System.currentTimeMillis() + 10000; // ten seconds
        //we are going to iterate this list in many small segments limited by time.
        //so we can't use the normal approach without an iterator
        while (checkListIter.hasNext()) {
            Long l = checkListIter.next();
            iterPosition++;
            long seekPos = l.longValue();
            if (ng.avoidDownloadNow(seekPos)) {
                continue;
            }
            if (ng.hasArticle(seekPos)) {
                continue;
            }
            out.write("\nSeeking " + seekPos + " -- ");
            out.flush();
            try {
                NewsArticle art = ng.getArticleOrNull(seekPos);
                out.write(art.getHeaderSubject());
            }
            catch (Exception e) {
                out.write("fail: "+UtilityMethods.getErrorString(e));
                giveUpList.add(l);
                NewsArticleError nae = ng.getError(seekPos);
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
        checkList = new HashSet<Long>();
        int seekExtent = seeker.seekExtent;

        for (NewsArticle art : seeker.getArticles()) {
            long lastCheck = art.getNumber()+seekExtent;
            for (long testVal = art.getNumber()-seekExtent; testVal<lastCheck; testVal++) {
                Long l = new Long(testVal);
                //our local set is relatively small, so check that first
                //and there will be lots of overlapping sweeps
                if (checkList.contains(l)) {
                    //we already have this in the list
                    continue;
                }
                if (giveUpList.contains(l)) {
                    //we know already not to check this one
                    continue;
                }
                if (ng.avoidDownloadNow(testVal)) {
                    //since the giveUpList is smaller than the newsGroup
                    //it is worth remembering this in the giveUpList.
                    //faster checking on later passes
                    giveUpList.add(l);
                    continue;
                }
                if (ng.hasArticle(testVal)) {
                    //since the giveUpList is smaller than the newsGroup
                    //it is worth remembering this in the giveUpList.
                    //faster checking on later passes
                    giveUpList.add(l);
                    continue;
                }
                checkList.add(l);
            }

        }

        //we are going to iterate this list in many small segments limited by time.
        //so we can't use the normal approach without an iterator
        checkListIter = checkList.iterator();
        iterPosition = 1;
    }

    public String getStatusView() throws Exception {
        return "Seek bunch "+seeker.digest;
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        jo.put("verb", "Seek Bunch");
        jo.put("part", iterPosition);
        jo.put("total", checkList.size());
        jo.put("digest", seeker.digest);
        return jo;
    }

}
