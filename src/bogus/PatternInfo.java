package bogus;

import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

public class PatternInfo
{
    public String    pattern;

    public int       count;
    public int       min;
    public int       max;
    public boolean   hasNegZero = false;

    public Hashtable<String,PatternInfo> diskMap;

    public Vector<ImageInfo> allImages;

    public PatternInfo(ImageInfo ii)
    {
        pattern = ii.getPattern();
        count = 0;
        min = ii.value;
        max = ii.value;
        diskMap = new Hashtable<String,PatternInfo>(12);
        allImages = new Vector<ImageInfo>();

        // it does not matter what we put in the hash table, the
        // test is just that something is there.
        this.addImage(ii);
    }

    public void addImage(ImageInfo ii)
    {
        count++;
        if (ii.value < min) {
            min = ii.value;
        }
        if (ii.value > max) {
            max = ii.value;
        }
        if (ii.value==0 && ii.isIndex) {
            hasNegZero = true;
        }
        diskMap.put(ii.diskMgr.diskName, this);
        allImages.addElement(ii);
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

    public void removeImage(ImageInfo ii)
    {
        count--;
        allImages.remove(ii);
    }

    public String getPattern() {
        return pattern;
    }

}
