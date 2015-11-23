package bogus;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;

import org.workcast.streams.HTMLWriter;
import org.workcast.streams.MemFile;

import bandaid.Thumbnail;

/**
 * represents a news group on a news server
 */

public class NewsActionDownloadFile extends NewsAction {
    private NewsBunch bunch;
    private NewsFile  newsFile;
    private int sequenceNum;
    private int workingPart;
    private int workingTotal;
    private boolean cancelable;

    public NewsActionDownloadFile(NewsFile _file, boolean _cancelable) throws Exception {
        newsFile = _file;
        sequenceNum = _file.getSequenceNumber();
        bunch = _file.getNewsBunch();
        cancelable = _cancelable;
        _file.markDownloading();
        bunch.touch();
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {

        //f we have no connection, then don't try to download
        if (!NewsGroup.connect) {
            if (newsFile != null) {
                newsFile.clearDownloading();
            }
            return;
        }

        //update the file name and location in case it has changed
        newsFile.refreshMapping();
        bunch.touch();
        long fileStart = System.currentTimeMillis();
        out.write("\nRetrieving file ("+sequenceNum+"): ");
        try {
            HTMLWriter.writeHtml(out, newsFile.getFileName());
            out.flush();
            if (!bunch.hasFolder()) {
                throw new Exception(
                        "Can not retrieve file. NewsPattern does not have a file path to store to.  Pattern = ("
                                + bunch.digest + ")");
            }
            File folder = bunch.getFolderPath();
            if (!folder.exists()) {
                throw new Exception(
                        "Can not retrieve this file. The folder to store in does not exist: ("
                                + bunch.getFolderPath() + ")  Create before downloading file.");
            }
            File theFilePath = newsFile.getFilePath();
            if (theFilePath.exists()) {
                // in this case, we are all done, just return
                out.write(" - done, file exists at "+theFilePath);
                return;
            }
            if (cancelable && bunch.pState != NewsBunch.STATE_DOWNLOAD) {
                // newsPattern is no longer wanting downloading
                out.write("\nArticle Download Cancelled: ");
                HTMLWriter.writeHtml(out, theFilePath.toString());
                return;
            }

            //throws an exception explaining if not complete
            newsFile.assertComplete();

            int numParts = newsFile.partsExpected();
            if (numParts <= 0) {
                numParts = 1;
            }

            // use a memfile to get all the decoded parts, and actually create
            // the
            // file only when all the parts are in. Could do this with a
            // temporary file.
            MemFile mf = new MemFile();
            OutputStream memoryBuffer = mf.getOutputStream();

            // this is not the perfect way to do this. yEnc should be parsed for
            // each piece, and UUEncode should be combined first. But for now
            // those are the only two supported, so it works.
            boolean combineFirst = !bunch.isYEnc;
            
            workingTotal = numParts;

            for (int i = 0; i < numParts; i++) {
            	workingPart = i;
                long startTime = System.currentTimeMillis();
                out.write("\n    Part " + (i + 1) + "/" + numParts);
                out.flush();
                NewsArticle art = newsFile.getPartOrFail(i + 1);
                if (art.buffer == null) {
                    out.write(" downloading: ");
                    art.getMsgBody();
                }
                else {
                    out.write(" storing: ");
                }
                writeDuration(out,startTime);
                out.flush();
                if (art.buffer != null) {
                    if (combineFirst) {
                        mf.fillWithInputStream(art.getBodyContent());
                    }
                    else {
                        art.streamDecodedContent(memoryBuffer);
                    }
                }
            }
            // now, take the combined input, and decode it into another memFile
            if (combineFirst) {
                MemFile mf2 = new MemFile();
                InputStream in1 = mf.getInputStream();
                UUDecoderStream uuds = new UUDecoderStream(in1);
                mf2.fillWithInputStream(uuds);
                mf = mf2;
            }
            
            //make sure you have latest file name and location
            newsFile.refreshMapping();
            String fileName = newsFile.getFileName();
            if ((fileName.endsWith(".jpg") || fileName.endsWith(".JPG")) && bunch.shrinkFiles) {
                // now shrink the image if needed: 1200x1000 quality 85%
                if (mf.totalBytes() > 195000) {
                    MemFile mf3 = new MemFile();
                    InputStream in2 = mf.getInputStream();
                    OutputStream out3 = mf3.getOutputStream();
                    Thumbnail.scalePhoto(in2, out3, 1200, 1000, 85);
                    if (mf3.totalBytes() <= 195000 && mf3.totalBytes() < mf.totalBytes() - 5000) {
                        int percent = (mf3.totalBytes() * 100) / mf.totalBytes();
                        out.write("\n    Shrunk(q85) to " + percent + "% from " + mf.totalBytes()
                                + " to " + mf3.totalBytes());
                        mf = mf3;
                    }
                }
                // Try again if that didn't work: 1200x1000 quality 80%
                if (mf.totalBytes() > 195000) {
                    MemFile mf4 = new MemFile();
                    InputStream in2 = mf.getInputStream();
                    OutputStream out4 = mf4.getOutputStream();
                    Thumbnail.scalePhoto(in2, out4, 1200, 1000, 80);
                    if (mf4.totalBytes() <= 195000 && mf4.totalBytes() < mf.totalBytes() - 5000) {
                        int percent = (mf4.totalBytes() * 100) / mf.totalBytes();
                        out.write("\n    Shrunk(q80) to " + percent + "% from " + mf.totalBytes()
                                + " to " + mf4.totalBytes());
                        mf = mf4;
                    }
                }
                // Try a third time if that did not work, really shrink it here:
                // 1000x900 quality 80%
                if (mf.totalBytes() > 195000) {
                    MemFile mf5 = new MemFile();
                    InputStream in2 = mf.getInputStream();
                    OutputStream out5 = mf5.getOutputStream();
                    Thumbnail.scalePhoto(in2, out5, 1000, 900, 80);
                    if (mf5.totalBytes() < mf.totalBytes() - 5000) {
                        int percent = (mf5.totalBytes() * 100) / mf.totalBytes();
                        out.write("\n    Shrunk(q80s) to " + percent + "% from " + mf.totalBytes()
                                + " to " + mf5.totalBytes() + ": ");
                        mf = mf5;
                    }
                }
            }

            // now write it to disk
            newsFile.refreshMapping();
            FileOutputStream fos = new FileOutputStream(newsFile.getFilePath());
            mf.outToOutputStream(fos);
            fos.flush();
            fos.close();
            newsFile.clearBodies(); // free up the memory space
            bunch.fileDown++;

            // this code registers this new file in the image system, but only if the
            //disk manager is loaded
            DiskMgr disk = bunch.getDiskMgr();
            if (disk != null) {
                disk.refreshDiskFolder(folder);
            }

            writeDuration(out,fileStart);
            //record the total number of bytes written to the file, and time
            Stats.addStats(fileStart, 0, mf.totalBytes(), System.currentTimeMillis()-fileStart);
            out.flush();
        }
        catch (Exception e) {
            if (newsFile != null) {
                newsFile.setFailMsg(e);
            }
            String msg = UtilityMethods.getErrorString(e);
            out.write("\n    Fail: " + msg);
            out.flush();

            //this will get the thread to reset the
            if (msg.contains("SocketException")) {
                throw e;
            }
        }
        finally {
            if (newsFile != null) {
                newsFile.clearDownloading();
            }
        }
    }

    public String getStatusView() throws Exception {
        return "Download "+workingPart+"/"+workingTotal+" of file "+newsFile.getFilePath();
    }

}
