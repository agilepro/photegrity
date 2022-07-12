package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.streams.CSVHelper;

public class Stats {

    private long timeStamp;
    private long rawBytes;
    private long finishedBytes;
    private long duration;

    private static long rawTotal;
    private static long finishedTotal;
    private static long durationTotal;
    private static long fileCount;
    private static boolean needRecalc;

    private static long rawTotalGlobal;
    private static long finishedTotalGlobal;
    private static long durationTotalGlobal;
    private static long fileCountGlobal;



    private static List<Stats> history = new ArrayList<Stats>();
    private static File outputFolder;
    private static String outputFileName;

    private Stats() {

    }

    public static synchronized void addStats(long time, long raw, long finished, long workTime) {
        Stats newStat = new Stats();
        newStat.timeStamp = time;
        newStat.rawBytes = raw;
        newStat.finishedBytes = finished;
        newStat.duration = workTime;
        history.add(newStat);
        needRecalc = true;
    }

    private static synchronized void recalcStats() {
        long newRaw = 0;
        long newFin = 0;
        long newDur = 0;
        long newFileCount = 0;
        for (Stats s : history) {
            newRaw += s.rawBytes;
            newFin += s.finishedBytes;
            if (s.finishedBytes>0) {
                newFileCount++;
            }
            else {
                //only count the time downloading, don't care about the other
                newDur += s.duration;
            }
        }
        rawTotal = newRaw;
        finishedTotal = newFin;
        durationTotal = newDur;
        fileCount = newFileCount;
        needRecalc = false;
    }

    /**
     * This goes and reads all the stats files on the disk, and counts all
     * the bytes read across all the files after the specified date.
     * This tells you how much the system has read over all that time.
     */
    public static synchronized void recalcGlobalsFromDate(long startTime) throws Exception {
        // save so that the file on disk is up to date
        saveStats();
        // recalc so the numbers are current
        recalcStats();

        // start with negative because the result will NOT include the
        // current history count.  (This is countered by reading the current file
        // along with the others).
        long newRaw = -rawTotal;
        long newFin = -finishedTotal;
        long newDur = -durationTotal;
        long newFileCount = -fileCount;

        List<File> newsFileList = DiskMgr.getNewsFiles();
        for (File newsFile : newsFileList)  {
            File folder = newsFile.getParentFile();
            for (File child : folder.listFiles()) {
                if (child.getName().endsWith(".stats")) {
                    FileInputStream fis = new FileInputStream(child);
                    Reader content = new InputStreamReader(fis, "UTF-8");
                    List<String> vals = CSVHelper.parseLine(content);
                    while (vals!=null) {
                        long tstamp = UtilityMethods.safeConvertLong(vals.get(0));
                        if (tstamp>=startTime) {
                            newRaw += UtilityMethods.safeConvertLong(vals.get(1));
                            newDur += UtilityMethods.safeConvertLong(vals.get(3));
                            long finAmt = UtilityMethods.safeConvertLong(vals.get(2));
                            newFin += finAmt;
                            if (finAmt>0) {
                                newFileCount++;
                            }
                        }
                        vals = CSVHelper.parseLine(content);
                    }
                    content.close();
                    fis.close();
                }
            }
        }

        rawTotalGlobal = newRaw;
        finishedTotalGlobal = newFin;
        durationTotalGlobal = newDur;
        fileCountGlobal = newFileCount;

    }


    /**
     * Pass in an array of timestamp values, each value marks the beginning
     * of a bin that will collect statistics.  Returned is a vector with
     * statistics for each bin, for the time period from the starttime of that
     * bin, to the start time of the next bin (or until current time for the last
     * bin).
     */
    public static synchronized List<Stats> recalcBins(long[] binStamps) throws Exception {

        ArrayList<Stats> res  = new ArrayList<Stats>();
        for (@SuppressWarnings("unused") long binVal : binStamps) {
            //create a bunch of empty stats objects
            res.add(new Stats());
        }

        List<File> newsFileList = DiskMgr.getNewsFiles();
        for (File newsFile : newsFileList)  {
            File folder = newsFile.getParentFile();
            for (File child : folder.listFiles()) {
                if (child.getName().endsWith(".stats")) {
                    FileInputStream fis = new FileInputStream(child);
                    Reader content = new InputStreamReader(fis, "UTF-8");
                    List<String> vals = CSVHelper.parseLine(content);
                    while (vals!=null) {
                        long tstamp = UtilityMethods.safeConvertLong(vals.get(0));
                        //find the first bin that is less than this timestamp
                        int binNum = binStamps.length-1;
                        while (binNum>=0 && tstamp<binStamps[binNum]) {
                            binNum--;
                        }
                        if (binNum==0 && tstamp<binStamps[0]) {
                            //special case when event is before the first bin, skip
                            continue;
                        }

                        Stats stat = res.get(binNum);
                        stat.rawBytes += UtilityMethods.safeConvertLong(vals.get(1));
                        long finAmt = UtilityMethods.safeConvertLong(vals.get(2));
                        stat.finishedBytes += finAmt;
                        stat.duration += UtilityMethods.safeConvertLong(vals.get(3));
                        vals = CSVHelper.parseLine(content);
                    }
                    content.close();
                    fis.close();
                }
            }
        }
        return res;
    }




    public static long getTotalRawBytes() {
        if (needRecalc) {
            recalcStats();
        }
        return rawTotalGlobal + rawTotal;
    }

    public static long getTotalFinishedBytes() {
        if (needRecalc) {
            recalcStats();
        }
        return finishedTotalGlobal + finishedTotal;
    }

    public static long getTotalDuration() {
        if (needRecalc) {
            recalcStats();
        }
        return durationTotalGlobal + durationTotal;
    }

    public static long getTotalFiles() {
        if (needRecalc) {
            recalcStats();
        }
        return fileCountGlobal + fileCount;
    }

    /**
     * Throws away all statistics it might be holding currently,
     * and initializes the cache and output file name.
     * Call this every time you open a news group and pass
     * the folder for the news group.
     * @param containingFolder is the place where the file will be created
     */
    public static void initializeStats(File containingFolder) {
        history = new ArrayList<Stats>();
        outputFolder = containingFolder;
        outputFileName = "s"+System.currentTimeMillis();
    }

    public static void saveStats() throws Exception {
        File destFile = new File(outputFolder, outputFileName + ".stats");
        File tempFile = new File(outputFolder, outputFileName + ".stats.temp");
        if (tempFile.exists()) {
            tempFile.delete();
        }
        FileOutputStream fos = new FileOutputStream(tempFile);
        Writer fw = new OutputStreamWriter(fos, "UTF-8");

        for (Stats stat : history) {
            ArrayList<String> values = new ArrayList<String>();
            values.add(Long.toString(stat.timeStamp));
            values.add(Long.toString(stat.rawBytes));
            values.add(Long.toString(stat.finishedBytes));
            values.add(Long.toString(stat.duration));
            CSVHelper.writeLine(fw, values);
        }

        fw.flush();
        fw.close();

        if (destFile.exists()) {
            destFile.delete();
        }
        tempFile.renameTo(destFile);
    }




}
