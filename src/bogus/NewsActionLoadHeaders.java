package bogus;

import java.io.Writer;

import org.workcast.streams.HTMLWriter;

/**
 * represents a news group on a news server
 */

public class NewsActionLoadHeaders extends NewsAction {
    long start;
    int count;
    int stepSize;
    int curStep;   //the current iteration, 0 ... count

    public NewsActionLoadHeaders(long _start, int _count, int _step) throws Exception {
        start = _start;
        count = _count;
        stepSize = _step;
        curStep = 0;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        if (!NewsGroup.connect) {
            //no connection, so cancel, and leave right away
            return;
        }
        //no more than 5 seconds on this
        long timeOut = System.currentTimeMillis()+5000;
        out.write("\nDownloading Headers "+start+"--"+curStep+"/"+count);

        NewsGroup newsGroup = NewsGroup.getCurrentGroup();
        int errorCount = 0;
        while (curStep < count) {
            if (System.currentTimeMillis() > timeOut) {
                //jump out and come back later
                out.flush();
                addToEndOfMid();
                return;
            }
            long articleNo = start + (stepSize * curStep);
            curStep++;
            out.write("\n");
            out.write(Long.toString(articleNo));
            out.write(" - ");
            out.flush();
            NewsArticle na = null;
            boolean previous = newsGroup.hasArticle(articleNo);
            NewsArticleError nae = newsGroup.getError(articleNo);
            if (nae!=null && !nae.okToTryAgainNow()) {
                out.write(" ~~ previously errored, too soon to try again");
                continue;
            }
            try {
                na = newsGroup.getArticleOrNull(articleNo);
                errorCount = 0;
            }
            catch (Exception e) {
                out.write(UtilityMethods.getErrorString(e));
                // if we get an exception, skip this, but go on to next.
                if (errorCount++ > 50) {
                    throw new Exception("Unable to get articles, see most recent exception", e);
                }
            }
            if (na != null) {
                HTMLWriter.writeHtml(out, na.getHeaderSubject());
                if (previous) {
                    out.write(" ~~ previously loaded");
                    continue;
                }
            }
            else {
                out.write(" *not retrieved* ");
            }
        }
        out.flush();

        newsGroup.recalcStats();
        newsGroup.sortArticles();
    }

    public String getStatusView() throws Exception {
        return "Load Headers "+start+".."+count+" by "+stepSize+", @"+curStep;
    }

}
