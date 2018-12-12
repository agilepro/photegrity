package bogus;

import java.io.File;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.LineNumberReader;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

import com.purplehillsbooks.json.JSONException;

@SuppressWarnings("serial")
public class HashCounter extends Hashtable<String,Integer>
{

    public
    HashCounter()
    {
        super();
    }


    public static Enumeration<String> sort(Enumeration<String> unsorted) throws Exception {
        try {
            Vector<String> sortedKeys = new Vector<String>();
            while (unsorted.hasMoreElements()) {
                sortedKeys.add(unsorted.nextElement());
            }

            Comparator<String> sc = new StringComparator();
            Collections.sort(sortedKeys, sc);

            return sortedKeys.elements();
        } catch (Exception e) {
            throw new JSONException("Failure creating a sorted Enumeration object", e);
        }
    }

    public Vector<String> sortedKeys() {
        Vector<String> keyList = new Vector<String>();
        for (String key : keySet()) {
            keyList.add(key);
        }
        Comparator<String> sc = new StringComparator();
        Collections.sort(keyList, sc);
        return keyList;
    }


    public Vector<String> getSortedKeys(Hashtable<String, Object> selected) throws Exception {
        try {
            Vector<String> sortedKeys = new Vector<String>();
            sortedKeys.addAll(keySet());

            Comparator<String> sc = new SelectedComparator(selected);
            Collections.sort(sortedKeys, sc);

            return sortedKeys;
        }
        catch (Exception e) {
            throw new JSONException("Failure creating a sorted Enumeration object", e);
        }
    }



    public void decrement(String val) throws Exception {
        if (containsKey(val)) {
            Integer i = get(val);
            if (i == null) {
                throw new JSONException("Strange, map should contain an element for ({0}) but got a null back.", val);
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


    public void increment(String val) throws Exception {
        if (containsKey(val)) {
            Integer i = get(val);
            if (i == null) {
                throw new Exception("Strange, map should contain an element for (" + val
                        + ") but got a null back.");
            }
            put(val, new Integer(i.intValue() + 1));
        }
        else {
            put(val, new Integer(1));
        }
    }


    public int getCount(String val) {
        Integer i = get(val);
        if (i == null) {
            return 0;
        }
        return i.intValue();
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
        Hashtable<String, Object> selected;

        public SelectedComparator(Hashtable<String, Object> s) {
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


}
