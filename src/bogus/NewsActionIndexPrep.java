package bogus;

import java.io.Writer;

/**
 * schedules a file save at a time when the background tasks are doing nothing
 * else...
 */

public class NewsActionIndexPrep extends NewsAction {

	public NewsActionIndexPrep() throws Exception {
	}

	/**
	 * call this to perform the action
	 */
	public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        try {
            long startTime = System.currentTimeMillis();
            out.write("\nPreparing the index ... ");
            out.flush();
            NewsGroup.findBunchesWithPattern("xyzzy");
            long secs = (System.currentTimeMillis()-startTime)/1000;
            out.write("\n ... done preparing index in "+secs+" second");
            out.flush();
        }
        catch (Exception e) {
            throw new Exception ("failure while preparing the index", e);
        }
	}

    public String getStatusView() throws Exception {
        return "Preparing index";
    }

}
