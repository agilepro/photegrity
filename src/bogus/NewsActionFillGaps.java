package bogus;

import java.io.Writer;
import java.util.ArrayList;
import java.util.List;

import com.purplehillsbooks.json.JSONObject;

/**
 * represents a news group on a news server
 */

public class NewsActionFillGaps extends NewsAction {
    long start;
    long end;
    int maxGap;
    int curStep;   //the current iteration, 0 ... count

    public NewsActionFillGaps(long _start, long _end, int _maxGap) throws Exception {
        start  = _start;
        end    = _end;
        maxGap = _maxGap;
        curStep = 0;
    }

    /**
     * call this to perform the action
     */
    public synchronized void perform(Writer out, NewsSession newsSession) throws Exception {
        if (!NewsGroup.connect) {
            //no connection, so cancel, and leave right away
            return;
        }
        //no more than 5 seconds on this
        long timeOut = System.currentTimeMillis()+5000;
        out.write("\nFillingGaps Headers "+start+"--"+end+"/"+maxGap);

        NewsGroup newsGroup = NewsGroup.getCurrentGroup();
        
        List<NewsArticle> allArts = newsGroup.getArticles();
        List<NewsArticle> selArts = new ArrayList<NewsArticle>();
        for (NewsArticle art : allArts) {
            if (art.articleNo>=start && art.articleNo<=end) {
                NewsArticleError nae = newsGroup.getError(art.articleNo);
                if (nae==null) {
                    selArts.add(art);
                }
            }
        }
        out.write("\n     articles in range: "+selArts.size());
        
        NewsArticle.sortByNumber(selArts);
        
        long lastNum = start-1;
        for (NewsArticle art : selArts) {
            long gapStart = lastNum;
            int diff = (int)(art.articleNo-lastNum);
            lastNum = art.articleNo;
            if (diff<=maxGap) {
                continue;
            }
            
            int count = (diff/maxGap);
            int newGapSize = (diff/(count+1));
            out.write("\n     gap found at  "+gapStart+" size="+diff+"  gaps="+count+" size="+newGapSize);
            out.flush();
            for (int step = 0; step<count; step++) {
                long neededArt = gapStart + (step+1)*newGapSize;
                
                //if there already is an error, try the next one....
                //to avoid repeatedly trying only the error articles.
                NewsArticleError nae = newsGroup.getError(neededArt);
                while (nae!=null && neededArt<end) {
                    out.write("\n        --x-error-x--  "+neededArt);
                    nae = newsGroup.getError(++neededArt);
                }
                try {
                    out.write("\n        fetching  "+neededArt);
                    newsGroup.getArticleOrNull(neededArt);
                }
                catch (Exception e) {
                    out.write("\n EXCEPTION: "+e);
                }
                
                //skip when we are out of time
                if (System.currentTimeMillis() > timeOut) {
                    out.write("\n     timed out");
                    out.flush();
                    addToEndOfMid();
                    return;
                }
            }
        }
        out.write("\n     all completed all gaps addressed.");
        
    }

    public String getStatusView() throws Exception {
        return "Fill Gaps "+start+".."+end+" by "+maxGap;
    }

    public JSONObject statusObject() throws Exception {
        JSONObject jo = super.statusObject();
        return jo;
    }

}
