package bogus;

import java.io.File;
import java.io.FileOutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.Date;

public class NewsBackground extends Thread {
    private Writer out;
    public static NewsBackground singleton;
    public static NewsAction lastActive;

    public NewsBackground(File containingFolder) throws Exception {
        File destFile = new File(containingFolder, "NewsProcessing" + System.currentTimeMillis()
                + ".log");
        FileOutputStream fos = new FileOutputStream(destFile);
        out = new OutputStreamWriter(fos, "UTF-8");
    }

    public static void startNewsThread(File containingFolder) throws Exception {

        singleton = new NewsBackground(containingFolder);
        singleton.start();
    }

    public void run() {
        NewsSession newsSession = null;
        int sequentialErrorCount = 0;
        while (this == singleton) {
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
                }
                NewsAction.active = true;
                act.performTimed(out, newsSession);
                sequentialErrorCount = 0;
            }
            catch (Exception e) {
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
                        out.write("\nSleeping 60 seconds...<br/>");
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
            out.write("\n\nGAVE UP PROCESSING TO ANOTHER THREAD\n");
            out.flush();
            out.close();
        }
        catch (Exception cantreportthiseither) {
            // nothing we can do here we are shutting down
        }
    }

}
