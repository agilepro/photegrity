package bogus;

import java.io.Writer;
import java.util.ArrayList;

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
    	groupImages.addAll(ImageInfo.imageQuery(query));
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
		
		        //skip the file if it is small enough (190K)
		        if (ii.fileSize<190000) {
		            out.write( " - already small enough." );
		            continue;
		        }
		
		        out.write(Integer.toString(ii.fileSize));
		        int sizeBefore = ii.fileSize;
		        out.flush();
		        Thumb.shrinkFile(ii);
		        long percentShrink = (((long)ii.fileSize)*100)/sizeBefore;
		        out.write(" -- ");
		        out.write(Long.toString(percentShrink));
		        out.write("% --> ");
		        out.write(Integer.toString(ii.fileSize));
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
