package com.purplehillsbooks.photegrity;

import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.streams.CSVHelper;

/**
 * represents a failure to get a particular news article.
 */
public class NewsArticleError {
    public long articleNo;
    public long lastErrorTime = 0;
    int errorCount = 0;
    String errorReason;

    //ignore repeated failures within 1 hour
    public static long TIMEOUT_ONE_HOUR = 60 * 60 * 1000;

    public NewsArticleError(long artNo) {
        articleNo = artNo;
    }

    public void registerNewAttempt(String errorMsg) {
        long time = System.currentTimeMillis();
        long embargoStart = time - TIMEOUT_ONE_HOUR;
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
        //retry embargo is 1 hour
        long retryEmbargoStart = System.currentTimeMillis() - TIMEOUT_ONE_HOUR;
        return lastErrorTime < retryEmbargoStart;
    }

    public long mostRecentAttempt() {
        return lastErrorTime;
    }

    public void assertOK() throws Exception {
        long embargoStart = System.currentTimeMillis() - TIMEOUT_ONE_HOUR;
        if (lastErrorTime > embargoStart) {
            throw new JSONException("Article {0} has failed {1} times, try again in {2} minutes",
                    articleNo, errorCount, ((lastErrorTime-embargoStart)/60000));
        }
    }
    
    public void unerror() {
        lastErrorTime = System.currentTimeMillis() - TIMEOUT_ONE_HOUR - 1000;
    }

    public String status() {
        long embargoStart = System.currentTimeMillis() - TIMEOUT_ONE_HOUR;
        if (lastErrorTime > embargoStart) {
            return "Article " + articleNo + " has failed "+errorCount+" times, try again in "+ ((lastErrorTime-embargoStart)/60000) +" minutes";
        }
        return "Article " + articleNo + " has failed "+errorCount+" times, OK to try again";
    }

    public void writeCacheLine(Writer w) throws Exception {
        List<String> values = new ArrayList<String>();
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
