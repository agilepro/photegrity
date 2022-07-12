package com.purplehillsbooks.photegrity;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.json.JSONException;

@SuppressWarnings("serial")
public class NumericCounter extends Hashtable<Integer,Integer> {

    public NumericCounter() {
        super();
    }


    public List<Integer> getSortedKeys() throws Exception {
        try {
            ArrayList<Integer> sortedKeys = new ArrayList<Integer>();
            Enumeration<Integer> unsorted = keys();
            while (unsorted.hasMoreElements()) {
                sortedKeys.add(unsorted.nextElement());
            }
            Collections.sort(sortedKeys);
            return sortedKeys;
        }
        catch (Exception e) {
            throw new JSONException("Failure creating a sorted Enumeration object", e);
        }
    }



    public void decrement(int val) throws Exception {
        Integer key = new Integer(val);
        if (containsKey(key)) {
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

    public void increment(int val) throws Exception {
        Integer key = new Integer(val);
        if (containsKey(key)) {
            Integer i = get(key);
            if (i == null) {
                throw new JSONException("Strange, map should contain an element for ({0}) but got a null back.", val);
            }
            put(key, new Integer(i.intValue() + 1));
        }
        else {
            put(key, new Integer(1));
        }
    }

}
