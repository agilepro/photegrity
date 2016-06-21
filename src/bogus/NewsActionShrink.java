package bogus;

import java.io.File;
import java.io.Writer;
import java.util.ArrayList;
import java.util.Random;
import java.util.Vector;

import org.workcast.streams.HTMLWriter;

/**
 * schedules a file save at a time when the background tasks are doing nothing
 * else...
 */

public class NewsActionShrink extends NewsAction {
	String query;
	ArrayList<ImageInfo> groupImages;
	int position = 0;

    public NewsActionShrink(String _query) throws Exception {
    	query = _query;
    	groupImages = new ArrayList<ImageInfo>();
    	Vector<ImageInfo> origOrder = ImageInfo.imageQuery(query);
    	
    	//now scramble them so that they are not done in the same order every time
    	Random r = new Random();
    	while (origOrder.size()>0) {
    	    int randomIndex = r.nextInt(origOrder.size());
    	    groupImages.add( origOrder.remove(randomIndex) );
    	}
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
    	long stopTime = System.currentTimeMillis()+5000;
    	try {
			while (System.currentTimeMillis() < stopTime) {
		        ImageInfo ii = groupImages.get(position);
		        position++;
		        if (ii == null) {
		            throw new Exception ("null image file where lastnum="+position);
		        }
                out.write("\nShrinking: ");
		        HTMLWriter.writeHtml(out, ii.getRelativePath());
		        HTMLWriter.writeHtml(out, ii.fileName);
		        out.write("   ");
		        File filePath = ii.getFilePath();
		        if (!filePath.exists()) {
		            //file has been moved in the meantime, so ignore this request
		            out.write(" - MISSING!  Has this been moved?  Ignoring.");
		            continue;
		        }

		        //skip the file if it is small enough (190K)
		        if (filePath.length()<190000) {
		            out.write( " - already small enough. Skipping." );
		            continue;
		        }

		        long sizeBefore = filePath.length();
		        out.write(Long.toString(sizeBefore));
		        out.flush();
		        Thumb.shrinkFile(ii);
		        long sizeAfter = filePath.length();
		        long percentShrink = (sizeAfter*100)/sizeBefore;
		        out.write(" -- ");
		        out.write(Long.toString(percentShrink));
		        out.write("% --> ");
		        out.write(Long.toString(sizeAfter));
			}
		    if (position<groupImages.size()) {
		    	addToEndOfQueue();
		    }
    	}
    	catch (Exception e) {
    		//does not re-queue, so it stops processing at this point.
    		this.addToFailedList(e);
    	}
    }

    public String getStatusView() throws Exception {
        return "Shrinking the files '"+query+"' finished "+position+" of "+groupImages.size();
    }

}
