package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.LineNumberReader;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;

@SuppressWarnings("serial")
public class HashCounter extends Hashtable<String,Integer> {

    public HashCounter() {
        super();
    }


    public static List<String> sort(Enumeration<String> unsorted) throws Exception {
        try {
            ArrayList<String> sortedKeys = new ArrayList<String>();
            while (unsorted.hasMoreElements()) {
                sortedKeys.add(unsorted.nextElement());
            }

            Comparator<String> sc = new StringComparator();
            Collections.sort(sortedKeys, sc);

            return sortedKeys;
        } catch (Exception e) {
            throw new JSONException("Failure creating a sorted Enumeration object", e);
        }
    }

    public List<String> sortedKeys() {
        ArrayList<String> keyList = new ArrayList<String>();
        for (String key : keySet()) {
            keyList.add(key);
        }
        Comparator<String> sc = new StringComparator();
        Collections.sort(keyList, sc);
        return keyList;
    }


    public List<String> getSortedKeys(Hashtable<String, String> selected) throws Exception {
        try {
            ArrayList<String> sortedKeys = new ArrayList<String>();
            sortedKeys.addAll(keySet());

            Comparator<String> sc = new SelectedComparator(selected);
            Collections.sort(sortedKeys, sc);

            return sortedKeys;
        }
        catch (Exception e) {
            throw new JSONException("Failure creating a sorted Enumeration object", e);
        }
    }

    public void sortKeysByCount(List<String> patterns) throws Exception {
         GroupsByCountComparator sc = new GroupsByCountComparator(this);
         Collections.sort(patterns, sc);
    }


     static class GroupsByCountComparator implements Comparator<String>
     {
         HashCounter counter;
    
         public GroupsByCountComparator(HashCounter _counter) {
             counter = _counter;
         }
    
         public int compare(String name1, String name2)
         {
             int o1size = counter.getCount(name1);
             int o2size = counter.getCount(name2);
    
             if (o1size > o2size) {
                 return -1;
             }
             else if (o1size == o2size) {
                 return 0;
             }
             else {
                 return 1;
             }
         }
    }



    public void decrement(String val) {
        if (containsKey(val)) {
            Integer i = get(val);
            if (i == null) {
                //this really should never happen, so make it invisible
                throw new RuntimeException("Strange, map should contain an element for ("+val+") but got a null back.");
            }
            int ival = i.intValue();
            if (ival <= 1) {
                remove(val);
            }
            else {
                put(val, new Integer(ival - 1));
            }
        }
    }


    public void increment(String val) {
        if (containsKey(val)) {
            Integer i = get(val);
            if (i == null) {
                //this really should never happen, so make it invisible
                throw new RuntimeException("Strange, map should contain an element for ("+val+") but got a null back.");
            }
            put(val, new Integer(i.intValue() + 1));
        }
        else {
            put(val, new Integer(1));
        }
    }

    
    /**
     * increments (or decrements with negative number) by more than one.
     * Pass the amount of change desired.   This saved having to call
     * increment or decrement a number of times.
     */
    public void changeBy(String val, int num) {
        if (containsKey(val)) {
            Integer i = get(val);
            if (i == null) {
                //this really should never happen, so make it invisible
                throw new RuntimeException("Strange, map should contain an element for ("+val+") but got a null back.");
            }
            put(val, new Integer(i.intValue() + num));
        }
        else {
            put(val, new Integer(num));
        }
    }
    

    public int getCount(String val) {
        Integer i = get(val);
        if (i == null) {
            return 0;
        }
        return i.intValue();
    }

    
    public void addAll(HashCounter other) {
        for (String key : other.keySet()) {
            changeBy(key, other.getCount(key));
        }
    }

    public void writeToFile(File summaryFile) throws Exception {
        try {
            FileWriter fw = new FileWriter(summaryFile);

            for (String p3 : sortedKeys()) {
                Integer i3 = get(p3);
                if (i3.intValue() > 1) {
                    fw.write(p3);
                    fw.write("\t");
                    fw.write(i3.toString());
                    fw.write("\n");
                }
            }
            fw.flush();
            fw.close();
        }
        catch (Exception e) {
            throw new JSONException("Unable to write a HashCounter to file ({0})",e,summaryFile);
        }
    }


    public void loadFromFile(File summaryFile) throws Exception {
        try {
            if (!summaryFile.exists()) {
                return; // empty
            }
            FileReader fr = new FileReader(summaryFile);
            LineNumberReader lnr = new LineNumberReader(fr);

            while (true) {
                String line = lnr.readLine();
                if (line == null) {
                    break;
                }

                int pos = line.indexOf("\t");
                if (pos < 1) {
                    // if no tab in line, then ignore it
                    continue;
                }

                String name = line.substring(0, pos);
                String quant = line.substring(pos + 1);
                Integer i = new Integer(Integer.parseInt(quant));
                put(name, i);

            }
            fr.close();
        }
        catch (Exception e) {
            throw new JSONException("Unable to read a HashCounter from file ({0})",e,summaryFile);
        }
    }

    static class StringComparator implements Comparator<String> {
        public StringComparator() {
        }

        public int compare(String o1, String o2) {
            return o1.compareToIgnoreCase(o2);
        }
    }

    static class SelectedComparator implements Comparator<String> {
        Hashtable<String, String> selected;

        public SelectedComparator(Hashtable<String, String> s) {
            selected = s;
        }

        public int compare(String o1, String o2) {
            boolean sel1 = (selected.get(o1) != null);
            boolean sel2 = (selected.get(o2) != null);
            if (sel1 == sel2) {
                return o1.compareToIgnoreCase(o2);
            }
            else {
                if (sel1) {
                    return -1;
                }
                else {
                    return 1;
                }
            }
        }
    }


    public JSONObject getJSON() throws Exception {
        JSONObject jo = new JSONObject();
        for (String key : sortedKeys()) {
            jo.put(key, getCount(key));
        }
        return jo;
    }
}
