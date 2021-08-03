package com.purplehillsbooks.photegrity;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import com.purplehillsbooks.json.JSONObject;

public class PatternInfo {
    public String    pattern;

    public int       count;
    public int       min;
    public int       max;
    public boolean   hasNegZero = false;

    public Hashtable<String,PatternInfo> diskMap;

    public Vector<JSONObject> allImages;

    public PatternInfo(JSONObject image) throws Exception {
        pattern = image.getString("pattern");
        count = 0;
        int value = image.getInt("value");
        min = value;
        max = value;
        diskMap = new Hashtable<String,PatternInfo>(12);
        allImages = new Vector<JSONObject>();

        // it does not matter what we put in the hash table, the
        // test is just that something is there.
        this.addImage(image);
    }
    
    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        jo.put("count", count);
        jo.put("min", min);
        jo.put("max", max);
        jo.put("hasNegZero", hasNegZero);
        jo.put("pattern", pattern);
        return jo;
    }

    public void addImage(JSONObject image) throws Exception {
        count++;
        int value = image.getInt("value");
        if (value < min) {
            min = value;
        }
        if (value > max) {
            max = value;
        }
        if (value==0 && pattern.indexOf("!")>=0) {
            hasNegZero = true;
        }
        diskMap.put(image.getString("disk"), this);
        allImages.add(image);
    }

    public String[] getDisks()
    {
        int last = diskMap.size();
        String[] retval = new String[last];
        Enumeration<String> e = diskMap.keys();
        for (int i=0; i<last; i++) {
            retval[i] = e.nextElement();
        }
        return retval;
    }

    public void removeImage(JSONObject ii)
    {
        count--;
        allImages.remove(ii);
    }

    public String getPattern() {
        return pattern;
    }

}
