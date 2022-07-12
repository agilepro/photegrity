package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.List;

import com.purplehillsbooks.streams.CSVHelper;

public class LocalMapping {

    public PosPat source;
    public PosPat dest;
    public boolean enabled = false;
    
    //desire amount is initialized to zero
    //set to 1,2,3,4 to automatically get that many files
    //set to -1 to disable the getting if files
    //set to 9999 (any large number) to get all the files
    public int     desireAmt = 0;

    private static Hashtable<String, LocalMapping> allMapping = new Hashtable<String, LocalMapping>();
    
    private LocalMapping(PosPat s, PosPat d, boolean en, int desired) {
        source = s;
        dest = d;
        enabled = en;
        desireAmt = desired;
    }

    public static LocalMapping createMapping(PosPat s, PosPat d) {
        LocalMapping newOne = new LocalMapping(s,d,false,0);
        String index = s.getSymbol();
        allMapping.put(index, newOne);
        return newOne;
    }

    public static void clearMapping(PosPat s) {
        String index = s.getSymbol();
        allMapping.remove(index);
    }
    
    /**
     * returns null if no mapping is found
     */
    public static LocalMapping getMapping(PosPat s) {
        String index = s.getSymbol();
        LocalMapping map = allMapping.get(index);
        return map;
    }

    /**
     * returns null if no mapping is found
     */
    public static PosPat getMapDestination(PosPat s) {
        LocalMapping map = getMapping(s);
        if (map!=null) {
            return map.dest;
        }
        return null;
    }
    
    /**
     * Sets to the enabled mode, then searches for any files
     * matching the source pattern, and moves them to the destination
     * OK to call this multiple times ... it will move any files
     * that are hanging around for any reason.
     * If a file already exists at destination, then source file
     * is simply deleted, and the existing dest file is left alone.
     */
    public void enableAndMoveFiles() throws Exception {
        source.moveAllFiles(dest);
        enabled = true;
    }
    
    /**
     * Set to disabled, but do not move any files back.
     */
    public void disableAndAbandon() {
        enabled = false;
    }
    
    /**
     * Set to disabled, but recall any files back to local folder.
     */
    public void disableAndRetrieveFiles() throws Exception {
        dest.moveAllFiles(source);
        enabled = false;
    }
    
    
    public synchronized static void storeData(File folder) throws Exception {
        File tempFile = new File(folder, "~temp~Local~Mapping");
        File dataFile = new File(folder,"newsLocalMap.csv");
        if (tempFile.exists()) {
            tempFile.delete();
        }
        FileOutputStream fos = new FileOutputStream(tempFile);
        Writer fw = new OutputStreamWriter(fos, "UTF-8");

        for (LocalMapping map : allMapping.values()) {
            ArrayList<String> values = new ArrayList<String>();
            values.add(map.source.getSymbol());
            values.add(map.dest.getSymbol());
            if (map.enabled) {
                values.add("enabled");
            }
            else {
                values.add("disabled");
            }
            values.add(Integer.toString(map.desireAmt));
            CSVHelper.writeLine(fw, values);            
        }

        fw.flush();
        fw.close();

        if (dataFile.exists()) {
            dataFile.delete();
        }
        tempFile.renameTo(dataFile);
        
    }
    
    public synchronized static void readData(File folder) throws Exception {
        Hashtable<String, LocalMapping> tempStore = new Hashtable<String, LocalMapping>();
        
        File destFile = new File(folder, "newsLocalMap.csv");
        if (!destFile.exists()) {
            //no file, no data, we are good
            allMapping = tempStore;
            return;
        }
        FileInputStream fis = new FileInputStream(destFile);
        Reader fr = new InputStreamReader(fis, "UTF-8");

        List<String> values = CSVHelper.parseLine(fr);
        while (values != null) {
            PosPat s = PosPat.getPosPatFromSymbolOrNull(values.get(0));
            PosPat d = PosPat.getPosPatFromSymbolOrNull(values.get(1));
            boolean enabled = "enabled".equals(values.get(2));
            int desired = 0;
            if (values.size()>3) {
                desired = Integer.parseInt(values.get(3));
            }
            if (s!=null && d!=null) {
                tempStore.put(values.get(0), new LocalMapping(s,d,enabled, desired));
            }
            values = CSVHelper.parseLine(fr);
        }

        fr.close();
        allMapping = tempStore;
    }
}
