package bogus;

import java.io.Writer;
import java.util.List;
import java.util.Vector;

import com.purplehillsbooks.streams.CSVHelper;

/**
 * represents a failure to get a particular news article.
 */
public class NewsArticleError {
    public long articleNo;
    public long lastErrorTime = 0;
    int errorCount = 0;
    String errorReason;

    //ignore repeated failures within 5 minutes
    public static long timeout = 24L * 60 * 60 * 1000;

    public NewsArticleError(long artNo) {
        articleNo = artNo;
    }

    public void registerNewAttempt(String errorMsg) {
        long time = System.currentTimeMillis();
        long embargoStart = time - timeout;
        if (lastErrorTime > embargoStart) {
            //ignore another failure within 1 day of the last
            //should not be trying again for at least a couple days anyway,
            //but a bug might cause this.
            //Ignore in order to avoid a huge run up of failures
            //if something is stuck in a fast loop.
            return;
        }
        //ok, record this
        lastErrorTime = time;
        if (errorMsg!=null) {
            errorReason = errorMsg;
        }
        errorCount++;
    }

    public boolean okToTryAgainNow() {
        //timeout is 1 day
        //retry embargo is 1 hour, or 12 times that
        long retryEmbargoStart = System.currentTimeMillis() - ((errorCount)*timeout);
        return lastErrorTime < retryEmbargoStart;
    }

    public long mostRecentAttempt() {
        return lastErrorTime;
    }

    public void assertOK() throws Exception {
        long embargoStart = System.currentTimeMillis() - ((errorCount)*timeout);
        if (lastErrorTime > embargoStart) {
            throw new Exception("Article " + articleNo + " has failed "+errorCount+" times, try again in "+ ((lastErrorTime-embargoStart)/3600000) +" hours");
        }
    }

    public String status() {
        long embargoStart = System.currentTimeMillis() - ((errorCount)*timeout);
        if (lastErrorTime > embargoStart) {
            return "Article " + articleNo + " has failed "+errorCount+" times, try again in "+ ((lastErrorTime-embargoStart)/3600000) +" hours";
        }
        return "Article " + articleNo + " has failed "+errorCount+" times, OK to try again";
    }

    public void writeCacheLine(Writer w) throws Exception {
        Vector<String> values = new Vector<String>();
        values.add(Long.toString(articleNo));
        values.add(Integer.toString(errorCount));
        values.add(Long.toString(lastErrorTime));
        values.add(errorReason);
        CSVHelper.writeLine(w, values);
    }

    public static NewsArticleError createFromLine(NewsGroup theGroup, List<String> values)
            throws Exception {
        if (values.size() < 4) {
            // bogus line
            return null;
        }
        long articleNumber = Long.parseLong(values.get(0));
        NewsArticleError t = new NewsArticleError(articleNumber);
        t.errorCount = Integer.parseInt(values.get(1));
        t.lastErrorTime = Long.parseLong(values.get(2));
        t.errorReason = values.get(3);

        return t;
    }

    /**
     * For reading files that end with "errs" that was the old format.
     * which had article number and three dates.
     * Convert to the current object format.
     */
    public static NewsArticleError createFromOldLine(NewsGroup theGroup, List<String> values)
            throws Exception {
        if (values.size() < 4) {
            // bogus line
            return null;
        }
        long articleNumber = Long.parseLong(values.get(0));
        NewsArticleError t = new NewsArticleError(articleNumber);
        long date1x = Long.parseLong(values.get(1));
        long date2x = Long.parseLong(values.get(2));
        long date3x = Long.parseLong(values.get(3));

        //put the newest date into the lastErrorTime
        if (date3x > 0) {
            t.errorCount = 3;
            t.lastErrorTime = date3x;
        }
        else if (date2x > 0) {
            t.errorCount = 2;
            t.lastErrorTime = date2x;
        }
        else {
            t.errorCount = 1;
            t.lastErrorTime = date1x;
        }
        t.errorReason = "legacy error";
        return t;
    }

}
