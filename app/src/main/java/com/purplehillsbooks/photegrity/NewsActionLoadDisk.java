package com.purplehillsbooks.photegrity;

import java.io.Writer;

import com.purplehillsbooks.json.JSONObject;

/**
 * schedules a file save at a time when the background tasks are doing nothing
 * else...
 */

public class NewsActionLoadDisk extends NewsAction {
    DiskMgr diskToLoad;

    public NewsActionLoadDisk(DiskMgr dm) throws Exception {
        diskToLoad = dm;
        diskToLoad.loadingNow = true;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        long startTime = System.currentTimeMillis();
        out.write("\nPreparing to load "+diskToLoad.diskName);
        out.flush();
        diskToLoad.loadDiskImages(out);
        diskToLoad.loadingNow = false;
        long secs = (System.currentTimeMillis()-startTime)/1000;
        out.write("\nFinished loading "+diskToLoad.diskName+" in "+secs+" seconds.");
        out.flush();
    }

    public String getStatusView() throws Exception {
        return "Loading the disk '"+diskToLoad.diskName+"'";
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }

}
