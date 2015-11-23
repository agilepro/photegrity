package bogus;

import java.util.Collections;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;
import bogus.Exception2;

@SuppressWarnings("serial")
public class NumericCounter extends Hashtable<Integer,Integer>
{

    public
    NumericCounter()
    {
        super();
    }


    public Vector<Integer> getSortedKeys()
        throws Exception
    {
        try {
            Vector<Integer> sortedKeys = new Vector<Integer>();
            Enumeration<Integer> unsorted = keys();
            while (unsorted.hasMoreElements()) {
                sortedKeys.add(unsorted.nextElement());
            }
            Collections.sort(sortedKeys);
            return sortedKeys;
        }
        catch (Exception e) {
            throw new Exception2("Failure creating a sorted Enumeration object", e);
        }
    }



    public void decrement(int val) throws Exception {
        Integer key = new Integer(val);
        if (containsKey(key)) {
            Integer i = get(val);
            if (i == null) {
                throw new Exception("Strange, map should contain an element for (" + val
                        + ") but got a null back.");
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
                throw new Exception("Strange, map should contain an element for (" + val
                        + ") but got a null back.");
            }
            put(key, new Integer(i.intValue() + 1));
        }
        else {
            put(key, new Integer(1));
        }
    }

}
