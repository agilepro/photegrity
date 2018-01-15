package bogus;

import java.io.Writer;
import java.util.List;
import java.util.Random;
import java.util.Vector;

import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;

/**
 * represents an overloadable action this one bring in three sample files to get
 * a feeling for the set.
 */

public class NewsActionSeekABit extends NewsAction {
    NewsBunch seeker;
    long startInt;
    Vector<Long> giveUpList = new Vector<Long>();
    int seekInc = -1;
    NewsGroup ng;

    public NewsActionSeekABit(NewsBunch _seeker) throws Exception {
        seeker = _seeker;
        /*
        if (!seeker.hasTemplate()) {
            String temp = seeker.getTemplate();
            if (!temp.endsWith(".jpg")) {
                throw new Exception("file template must end with .jpg: got ("+temp+")");
            }
            seeker.changeTemplate(temp, false);
        }
        if (!seeker.hasFolder()) {
            seeker.changeFolder(seeker.getFolderLoc(), false);
            File storeFile = seeker.getFolderPath();
            if (!storeFile.exists()) {
                storeFile.mkdirs();
            }
        }
        */
        String template = seeker.getTemplate();
        if (!template.endsWith(".jpg")) {
            throw new Exception("template needs to end with jpg");
        }
        seeker.isSeeking = true;
        seeker.pState = NewsBunch.STATE_GETABIT;
        ng = NewsGroup.getCurrentGroup();
        seeker.touch();
    }

    /**
     * Convenient static method creates and queues an instance
     */
    public static void start(NewsBunch _seeker) throws Exception {
        NewsActionSeekABit nada = new NewsActionSeekABit(_seeker);
        nada.addToFrontOfHigh();
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
        if (seeker.pState != NewsBunch.STATE_GETABIT) {
            // newsPattern is no longer wanting seeking
            out.write("\nNewsGroup Seeking Cancelled: ");
            HTMLWriter.writeHtml(out, seeker.tokenFill());
            out.write("<br/>");
            return;
        }
        if (giveUpList.size()>9) {
            out.write("\nNewsGroup Giving up too many errors: ");
            HTMLWriter.writeHtml(out, seeker.tokenFill());
            out.write("<br/>");
            return;
        }

        out.write("\n-----------------");
        boolean finished = doit(out);
        if (finished) {
            seeker.isSeeking = false; // set this off
            if (seeker.pState == NewsBunch.STATE_GETABIT) {
                seeker.pState = NewsBunch.STATE_INTEREST;
            }
            seeker.getFiles(); // resets the statistics
        }
        else {
            // schedule the next step
            addToEndOfMid();
        }

    }

    private boolean doit(Writer out) throws Exception {
        long deadline = System.currentTimeMillis() + 10000; // ten seconds
        int completedCount = 0;
        int downloadCount = 0;
        Vector<NewsFile> completedFiles = new Vector<NewsFile>();
        for (NewsFile nf : seeker.getFiles()) {
            if (nf.isComplete() && nf.getFailMsg() == null) {
                completedCount++;
                completedFiles.add(nf);
            }
            if ((nf.isMarkedDownloading() || nf.isDownloaded()) && nf.getFailMsg() == null) {
                downloadCount++;
            }
        }

        // if there are 3 or more downloaded files, then done
        if (downloadCount > 2) {
            return true;
        }

        // if 6 or completed, but not downloading, then mark for downloading
        if (completedCount > 5) {
            startFileDownload(completedFiles.get(0));
            startFileDownload(completedFiles.get(completedFiles.size() - 1));
            startFileDownload(completedFiles.get(completedFiles.size() / 2));
            return false;
        }

        // if there are 3 or more downloaded files, then done
        if (downloadCount < 1 && completedCount >= 1) {
            //get one started immediately if there is one to get, but fall
            //through into getting more headers
            startFileDownload(completedFiles.get(completedFiles.size() / 2));
        }



        List<NewsArticle> artlist = seeker.getArticles();
        if (startInt == 0) {
            if (artlist.size() == 0) {
                throw new Exception(
                        "See Group only works when there is at least one article with that digest ("
                                + seeker.tokenFill() + ").");
            }
            Random rand = new Random();
            int randomArticlePosition = rand.nextInt(artlist.size());
            NewsArticle art = artlist.get(randomArticlePosition); // random
                                                                    // point to
                                                                    // work from
            startInt = art.articleNo;
        }
        HTMLWriter.writeHtml(out, seeker.tokenFill());

        seekInc = -1;
        if (!doOneWay(out, artlist, deadline)) {
            return false;
        }

        seekInc = 1;
        if (!doOneWay(out, artlist, deadline)) {
            return false;
        }
        ng.sortArticles();
        return true;
    }

    private void startFileDownload(NewsFile nf) throws Exception {
        if (!nf.isMarkedDownloading() && !nf.isDownloaded()) {
            NewsActionDownloadFile nadf = new NewsActionDownloadFile(nf, false);
            nadf.addToFrontOfHigh();  //high priority to get these quicker than other scans
        }
    }

    private boolean doOneWay(Writer out, List<NewsArticle> artlist, long deadline) throws Exception {
        String dig = seeker.digest;
        int missCount = 0;
        int errorCount = 0;
        long seekPos = startInt;
        if (seekPos < ng.firstArticle || seekPos > ng.lastArticle) {
            // should only happen if news group is corrupt
            throw new Exception("Strange situation the starting point (" + seekPos
                    + ") is not between start (" + ng.firstArticle + ") and end (" + ng.lastArticle
                    + ") of newsgroup.");
        }
        out.flush();
        while (missCount < 16 && seekPos > ng.firstArticle && seekPos < ng.lastArticle) {
            out.flush();
            seekPos += seekInc;
            if (giveUpList.contains(new Long(seekPos))) {
                // if this seek has failed before, don't try again
                out.write("\nSkipping " + seekPos);
                continue;
            }
            try {
                if (ng.avoidDownloadNow(seekPos)) {
                    // this does not add to the failure count, or anything
                    out.write("\nAvoiding recently errored article " + seekPos);
                    continue;
                }
                boolean needDownload = !ng.hasArticle(seekPos);
                NewsArticle art = ng.getArticleOrNull(seekPos);
                if (needDownload) {
                    out.write("\nSeeking " + seekPos + " -- " + art.getHeaderSubject());
                    out.flush();
                }
                if (dig.equals(art.getDigest())) {
                    missCount = 0;
                    errorCount = 0;
                }
                else {
                    missCount++;
                }
            }
            catch (Exception e) {
                giveUpList.add(new Long(seekPos));
                String msg = UtilityMethods.getErrorString(e);
                out.write("\nError " + seekPos + ": " + msg + "<br/>");
                NewsArticleError nae = ng.getError(seekPos);
                if (nae == null) {
                    out.write("\nSTRANGE ... got a failure but the news group did not record it!<br/>");
                }
                else {
                    out.write("\n    >" + nae.status());
                }

                out.flush();
                if (msg.contains("SocketException")) {
                    //this will reset the socket in the main thread loop
                    throw e;
                }
                if (errorCount++ > 5) {
                    seeker.pState = NewsBunch.STATE_ERROR;
                    seeker.failureMessage = e;
                    throw new Exception("Too many errors", e);
                }
            }
            if (System.currentTimeMillis() > deadline) {
                return false;
            }
        }
        return true;
    }

    public String getStatusView() throws Exception {
        return "Seek a bit from "+seeker.getTemplate()+" [tried "+giveUpList.size()+"]";
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }

}
