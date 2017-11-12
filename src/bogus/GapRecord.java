package bogus;

import java.util.Collections;
import java.util.Comparator;
import java.util.List;

public class GapRecord {

    public int sizeOfGap;
    public int countOfGaps;
    public long firstGapPosition;
    
    public GapRecord(int size, long firstPos) {
        sizeOfGap = size;
        countOfGaps = 1;
        firstGapPosition = firstPos;
    }
    
    public void increment() {
        countOfGaps++;
    }
    
    public static void recordGap(List<GapRecord> list, int size, long startPos) {
        GapRecord gr = findGapRecord(size, list);
        if (gr==null) {
            gr = new GapRecord(size, startPos);
            list.add(gr);
        }
        else {
            gr.increment();
        }
    }
    public static GapRecord findGapRecord(int size, List<GapRecord> list) {
        for (GapRecord gr : list) {
            if (gr.sizeOfGap==size) {
                return gr;
            }
        }
        return null;
    }
    public static void sortBySize(List<GapRecord> list) {
        Collections.sort(list, new GapComparator());
    }
    
    static class GapComparator implements Comparator<GapRecord> {
        @Override
        public int compare(GapRecord arg0, GapRecord arg1) {
            // Returns a negative integer, zero, or a positive integer as the first argument 
            // is less than, equal to, or greater than the second.
            return arg1.sizeOfGap - arg0.sizeOfGap;
        }
    }
    
    
}
