package bogus;

import java.io.Writer;
import java.util.List;
import java.util.Stack;
import java.util.Vector;

import com.purplehillsbooks.streams.NullWriter;

/**
 * represents a base class for News Actions which can be run in the background
 * There are three queue levels:
 *
 * High: generally for things that the user does directly and expects to see
 * quickly, such as downloading a specific file.
 *
 * Mid: for seeking which the user often waits for to decide whether to
 * to download the bunch or not.  Seeking takes priority over downloading
 * a bunch, but lower priority than download a single file.
 *
 * Low: for downloading of entire bunches which can go on in the background
 * for a long time.
 *
 *
 */

public abstract class NewsAction {
    private static Stack<NewsAction> jobQueueHigh = new Stack<NewsAction>();
    private static Stack<NewsAction> jobQueueMid = new Stack<NewsAction>();
    private static Stack<NewsAction> jobQueueLow = new Stack<NewsAction>();
    private static Stack<NewsAction> failedList = new Stack<NewsAction>();
    protected static long serviceId = 0;

    // tells whether the thread is actively processing a command or not
    public static boolean active = false;
    
    //Another thread can call abort() which sets this flag, and causes the
    //action to be removed from the queue on the next touch
    public boolean requestedAbort = false;
    
    //Each action is responsible to set this to true when it determines that 
    //it is finished.
    public boolean success = false;

    //each action adds up the time it has spent operating so far
    public long accumulatedTime = 0;
    public long thisStartTime = 0;

    public String serviceLevelName = "Unknown";
    
    public Exception failure;

    public NewsAction() throws Exception {
    }

    public void abort() {
    	requestedAbort = true;
    }
    
    /**
     * Each action should implement its own cleanUp.
     * 
     * This is called by the background thread whenever this action has been
     * terminated normally or abortively.  This allows the action to clean up
     * the settings it might have made on other object.  Use the success variable 
     * to tell when this is a cleanup after success, or an abort.
     * 
     * This will also be called after an exception is thrown from the perform method
     */
    void cleanUp() {
    	
    }
    
    /**
     * perform, but send all the output to the bit bucket
     */
    public synchronized void performSilent(NewsSession newsSession) throws Exception {

        Writer w = new NullWriter();
        perform(w, newsSession);

    }

    public void performTimed(Writer out, NewsSession newsSession) throws Exception
    {
        thisStartTime = System.currentTimeMillis();
        perform(out, newsSession);
        accumulatedTime += (System.currentTimeMillis() - thisStartTime);
        thisStartTime = 0;
    }

    /**
     * Each action must implement this.
     * The perform action must not hog the thread, and return in a reasonable
     * amount of time (a few seconds).  If it is not done, it should reschedule
     * itself by adding itself back into one of the queues.
     * 
     * Will be passed a Writer to the log file, and the news session to use.
     */
    protected abstract void perform(Writer out, NewsSession newsSession) throws Exception;

    public void addToFrontOfHigh() {
        synchronized (jobQueueHigh) {
            if (!jobQueueHigh.contains(this)) {
                jobQueueHigh.insertElementAt(this, 0);
            }
        }
        serviceLevelName="High";
    }

    public void addToFrontOfMid() {
        synchronized (jobQueueMid) {
            if (!jobQueueMid.contains(this)) {
                jobQueueMid.insertElementAt(this, 0);
            }
        }
        serviceLevelName="Mid";
    }

    public void addToEndOfMid() {
        synchronized (jobQueueMid) {
            if (!jobQueueMid.contains(this)) {
                jobQueueMid.add(this);
            }
        }
        serviceLevelName="Mid";
    }

    public void addToFrontOfLow() {
        synchronized (jobQueueLow) {
            if (!jobQueueLow.contains(this)) {
                jobQueueLow.insertElementAt(this, 0);
            }
        }
        serviceLevelName="Low";
    }

    public void addToEndOfQueue() {
        synchronized (jobQueueLow) {
            if (!jobQueueLow.contains(this)) {
                jobQueueLow.add(this);
            }
        }
        serviceLevelName="Low";
    }

    public static NewsAction pullFromQueueOrNull() {
        synchronized (jobQueueHigh) {
            if (jobQueueHigh.size() > 0) {
                return jobQueueHigh.remove(0);
            }
        }
        synchronized (jobQueueMid) {
            if (jobQueueMid.size() > 0) {
                return jobQueueMid.remove(0);
            }
        }
        synchronized (jobQueueLow) {
            if (jobQueueLow.size() > 0) {
                return jobQueueLow.remove(0);
            }
        }
        return null;
    }

    public void addToFailedList(Exception e) {
    	failure = e;
        synchronized (failedList) {
            if (!failedList.contains(this)) {
            	failedList.add(this);
            }
        }
        serviceLevelName="FAILED";
    }


    /**
     * It is important that only one thread read from the job queue at a time,
     * only one thread servicing the queue. Whever starting to service the job
     * queue, use markForThisThread() to mark the queue as being serviced by
     * your current thread. Then, before proceeding on every action, check that
     * it is still marked for your thread. If not, give up and let the other
     * thread handle it.
     */
    public static void markForThisThread() {
        Thread thisThread = Thread.currentThread();
        long threadId = thisThread.getId();
        serviceId = threadId;
    }

    /**
     * It is important that only one thread read from the job queue at a time,
     * only one thread servicing the queue. Whever starting to service the job
     * queue, mark the queue as being services by your current thread. Then,
     * before proceeding on every action, use isMarkedForThisThread() to check
     * that it is still marked for your thread. If not, give up and let the
     * other thread handle it.
     */
    public static boolean isMarkedForThisThread() {
        Thread thisThread = Thread.currentThread();
        long threadId = thisThread.getId();
        return (serviceId == threadId);
    }

    public static int getActionCount() {
        int future = jobQueueHigh.size() + jobQueueMid.size() + jobQueueLow.size();

        // things are pulled out of the queue before processing
        // so add one if there is something currently processing.
        if (active) {
            return future + 1;
        }
        return future;
    }

    public static void writeDuration(Writer out, long startTime) throws Exception {
        long diffSeconds = (System.currentTimeMillis()-startTime)/1000;
        long diffFract = (System.currentTimeMillis()-startTime) % 1000;
        out.write(" "+ diffSeconds + "." + diffFract + " seconds");
    }

    /**
     * Removes all future actions from the queue.
     * Does not, otherwise, clean up anything.
     */
    public static void shutDownProcessing() {
        jobQueueHigh.clear();
        jobQueueMid.clear();
        jobQueueLow.clear();
    }

    public String getStatusViewTimed() throws Exception {
        double time = accumulatedTime / 1000.0;
        if (thisStartTime>0) {
            //if this task is currently running, add the new runtime
            time = time + (System.currentTimeMillis()-thisStartTime)/1000.0;
        }
        return getStatusView()+" ("+time+" secs) "+serviceLevelName;
    }
    public String getStatusView() throws Exception {
        return "{"+getClass().getName()+"}";
    }
    static public List<NewsAction> getAllActions() {
        Vector<NewsAction> ret = new Vector<NewsAction>();
        NewsAction tester = NewsBackground.lastActive;
        if (tester!=null) {
            ret.add(tester);
        }
        ret.addAll(jobQueueHigh);
        ret.addAll(jobQueueMid);
        ret.addAll(jobQueueLow);
        return ret;
    }
}
