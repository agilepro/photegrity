package com.purplehillsbooks.photegrity;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;

import com.purplehillsbooks.json.JSONException;
import com.purplehillsbooks.json.JSONObject;
import com.purplehillsbooks.streams.HTMLWriter;
import com.purplehillsbooks.streams.MemFile;

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
        boolean allowPartial = NewsGroup.getCurrentGroup().downloadPartialFiles;

        //update the file name and location in case it has changed
        newsFile.refreshMapping();
        bunch.touch();
        long fileStart = System.currentTimeMillis();
        out.write("\nRetrieving file ("+sequenceNum+"): ");
        try {
            HTMLWriter.writeHtml(out, newsFile.getFileName());
            out.flush();
            if (!bunch.hasFolder()) {
                bunch.createFolderIfReasonable();
            }
            File folder = bunch.getFolderPath();
            if (!folder.exists()) {
                throw new JSONException(
                        "Can not retrieve this file. The folder to store in does not exist: ({0})  Create before downloading file.", bunch.getFolderPath());
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
            if (!allowPartial) {
                newsFile.assertComplete();
            }

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

            // yEnc should be parsed for each piece, and UUEncode should be combined first. 
            // But for now those are the only two supported, so it works.
            // To determine this, we have to know which we are dealing with.
            // To know that, we need to get the first batch, and peek at it.
            boolean combineFirstForUUDecode = false;
            
            {
                //could get this from any random part, but start looking at the beginning
            	int firstPart = 1;
            	NewsArticle art = null;
            	while ((art=newsFile.getPartOrNull(firstPart))==null) {
            	    firstPart++;
            	    if (firstPart>numParts) {
            	        throw new Exception("Strange, tried ALL the parts and none seem to be present.  Exiting");
            	    }
            	}
            	art.getMsgBody();
            	int encoding = art.getEncodingType();
            	if (encoding!=NewsArticle.YENC_ENCODING) {
            		combineFirstForUUDecode = true;
            	}
            }
            
            workingTotal = numParts;

            for (int i = 0; i < numParts; i++) {
            	workingPart = i;
                long startTime = System.currentTimeMillis();
                out.write("\n    Part " + (i + 1) + "/" + numParts);
                out.flush();
                NewsArticle art = newsFile.getPartOrNull(i + 1);
                if (art==null) {
                    if (!allowPartial) {
                        throw new Exception("Unable to find part "+i+", but allowPartial is false");
                    }
                    continue;
                }
                if (art.buffer == null) {
                    out.write("("+art.articleNo+") downloading: "); 
                    try {
                        art.getMsgBody();
                    }
                    catch (Exception e) {
                        //just swallow this if doing partials....
                        if (allowPartial) {
                            continue;
                        }
                        else {
                            throw e;
                        }
                    }
                    
                    if (!art.confirmHeadersFromBody(out)) {
                        out.flush();
                        throw new JSONException("HEADERS CHANGED {0}|{1}", art.articleNo, art.getHeaderSubject());
                    }
                }
                else {
                    out.write(" storing: ");
                }
                writeDuration(out,startTime);
                out.flush();
                if (art.buffer != null) {
                    if (combineFirstForUUDecode) {
                        mf.fillWithInputStream(art.getBodyContent());
                        
                    }
                    else {
                        art.streamDecodedContent(memoryBuffer);
                    }
                }
            }
            // now, take the combined input, and decode it into another memFile
            if (combineFirstForUUDecode) {
                //File debugFileFolder = newsFile.getFilePath();
                //File debugFileDump = new File(debugFileFolder.getParent(),"debug.txt");
                //StreamHelper.copyReaderToUTF8File(mf.getReader(), debugFileDump);
                
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
            failure = e;
            String msg = UtilityMethods.getErrorString(e);
            out.write("\n    Fail: " + msg);
            out.flush();
            
            System.out.println("############# ERROR DOWNLOADING FILE #########");
            e.printStackTrace(System.out);
            System.out.println("############# ###################### #########");

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

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        double seconds = getSeconds();
        if (workingPart>0 && workingTotal>0) {
            double timePerUnit = seconds / workingPart;
            jo.put("timeEstimate", timePerUnit * workingTotal);
        }
        jo.put("verb", "Download");
        jo.put("part", workingPart);
        jo.put("total", workingTotal);
        jo.put("file", newsFile.getFilePath());
        return jo;
    }

}
