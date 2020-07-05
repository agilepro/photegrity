package bogus;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.Date;

public class NewsBackground extends Thread {
    private Writer out;
    public static NewsBackground singleton = null;
    public static NewsAction lastActive;
    public File logFolder;
    public File logFile;
    long lastSaveTime = System.currentTimeMillis();
    boolean timeToStop = false;
    boolean hasStopped = false;

    private NewsBackground(File containingFolder) throws Exception {
        setLoggingFile(containingFolder);
    }

    public static void startNewsThread(File containingFolder) throws Exception {
        if (singleton==null) {
            singleton = new NewsBackground(containingFolder);
            singleton.start();
        }
        else {
            singleton.setLoggingFile(containingFolder);
        }
        System.out.println("NEWS THREAD: running: "+singleton.logFile);
    }
    
    public void setLoggingFile(File containingFolder) throws Exception {
        if (containingFolder.equals(logFolder)) {
            return;  //nothing to do
        }
        Writer oldOutput = out;
        File oldLogFile = logFile;
        
        logFolder = containingFolder;
        logFile = new File(containingFolder, "NewsProcessing" + System.currentTimeMillis() + ".log");
        
        FileOutputStream fos = new FileOutputStream(logFile);
        out = new OutputStreamWriter(fos, "UTF-8");
        out.write("Start Background Processing "+new Date()+"\n");
        
        if (oldOutput!=null) {
            oldOutput.write("\n\nTERMINATING logging here at "+new Date());
            oldOutput.write("\nLogging will continue at "+logFile+"\n");
            oldOutput.flush();
            oldOutput.close();
            out.write("Previous log file (closed): "+oldLogFile+"\n");
        }
    }

    public void run() {
        try {
            out.write("STARTING PROCESSING TO File:"+singleton.logFile);
            out.write("\n"+(new Date()).toString()+"\n");
        }
        catch (Exception e) {
            //nothing to do here, log file could not be written, something badly wrong?
            System.out.println("Unable to write to file: "+singleton.logFile);
            return;
        }
        NewsSession newsSession = null;
        int sequentialErrorCount = 0;
        while (!timeToStop && this == singleton) {
            try {
                NewsGroup newsGroup = NewsGroup.getCurrentGroup();
                NewsAction act = NewsAction.pullFromQueueOrNull();

                //if group is closed, clear out the action queue
                while (!newsGroup.isReady && act!=null) {
                    act = NewsAction.pullFromQueueOrNull();
                }

                lastActive = act;
                if (act == null) {
                    if (newsSession != null) {
                        if (newsGroup.isReady) {
                            newsGroup.saveCache();
                            lastSaveTime = System.currentTimeMillis();
                            out.write("\n----------Completed SAVED "+(new Date()).toString()+"\n\n");
                        }
                        else {
                            out.write("\n----------NO SAVE!!!! ABORTED? "+(new Date()).toString()+"\n\n");
                        }
                        newsSession.disconnect();
                        newsSession = null;
                    }
                    NewsAction.active = false;
                    lastActive = null;  //just to be sure
                    out.flush();
                    Thread.sleep(2000);
                    continue;
                }

                if (act.requestedAbort) {
                    //simply by not calling perform it will not get a chance to
                    //reinsert itself in any queue
                    act.cleanUp();
                    continue;
                }

                if (newsSession == null) {
                    out.write("\n==========" + (new Date()).toString());
                    newsSession = NewsGroup.session;
                    newsSession.connect();
                    lastSaveTime = System.currentTimeMillis();
                }
                NewsAction.active = true;
                act.performTimed(out, newsSession);
                sequentialErrorCount = 0;
                
                //every 5 minutes save everything after successful perform of action
                if (System.currentTimeMillis()-lastSaveTime > 300000) {
                    newsGroup.saveCache();
                    lastSaveTime = System.currentTimeMillis();
                    out.write("\n----------Automaticalley SAVED "+(new Date()).toString()+"\n\n");
                }
            }
            catch (Throwable e) {
                sequentialErrorCount++;
                newsSession = null;
                if (lastActive != null) {
                    lastActive.cleanUp();
                }
                String msg = UtilityMethods.getErrorString(e);
                try {
                    out.write("\n*** ("+sequentialErrorCount+") ");
                    out.write(msg);
                    out.write("\n==========");
                    if (msg.contains("Unable to authenticate")) {
                        out.write("\nSleeping 20 seconds...<br/>");
                        out.flush();
                        // sleep for 20 seconds when getting the unauthenticate
                        // problem
                        Thread.sleep(20000);
                    }
                }
                catch (Exception cantreportthis) {
                }
            }
        }
        try {
            out.write("\n\nGAVE UP PROCESSING TO THREAD:"+singleton.logFile);
            out.write("\n"+(new Date()).toString()+"\n");
            out.flush();
            out.close();
        }
        catch (Exception cantreportthiseither) {
            // nothing we can do here we are shutting down
        }
        hasStopped = true;
    }
}
