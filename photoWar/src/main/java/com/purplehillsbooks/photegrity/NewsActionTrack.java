package com.purplehillsbooks.photegrity;

import java.io.Writer;

import com.purplehillsbooks.json.JSONObject;

/**
 * schedules a file save at a time when the background tasks are doing nothing
 * else...
 */

public class NewsActionTrack extends NewsAction {

    String oldPath;
    String oldPattern;
    String newPath;
    String newPattern;

    public NewsActionTrack(String _oldPath, String _oldPattern, String _newPath,
            String _newPattern) throws Exception {
        oldPath    = _oldPath;
        oldPattern = _oldPattern;
        newPath    = _newPath;
        newPattern = _newPattern;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        NewsBunch.trackMovedFilesInternal(out, oldPath, oldPattern, newPath, newPattern);
    }

    public String getStatusView() throws Exception {
        return "Tracking "+oldPath+oldPattern+" TO "+newPath+newPattern;
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }


}
