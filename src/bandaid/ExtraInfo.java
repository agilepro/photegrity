package bandaid;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStreamWriter;
import java.util.Hashtable;

public class ExtraInfo {

	String path;
	Hashtable<String, String> comments;
	Hashtable<String, Integer> ratings;

	public ExtraInfo(String npath) throws Exception {
		path = npath;
		comments = new Hashtable<String, String>();
		ratings = new Hashtable<String, Integer>();
		readInfo();
	}

	public String getComment(String fileName) {
		String lsFileName = fileName.toLowerCase();
		return comments.get(lsFileName);
	}

	public int getRating(String fileName) {
		String lsFileName = fileName.toLowerCase();
		Integer i = ratings.get(lsFileName);
		if (i == null) {
			return 0;
		}
		return i.intValue();
	}

	public void setComment(String fileName, String comment) throws Exception {
		String lsFileName = fileName.toLowerCase();
		comments.put(lsFileName, comment);
		storeInfo();
	}

	public void setRating(String fileName, int rating) throws Exception {
		String lsFileName = fileName.toLowerCase();
		ratings.put(lsFileName, new Integer(rating));
		storeInfo();
	}

	public void storeInfo() throws Exception {
		File thumbDir = new File("g:/Thumbs/" + path);
		if (!thumbDir.exists()) {
			throw new Exception("Sorry, I can not find that photo directory: " + path);
		}
		if (!thumbDir.isDirectory()) {
			throw new Exception(
					"Sorry, the path given must be a valid directory with photos in it: " + path);
		}

		File outFile = new File("g:/Photos/" + path + "/photo.info");
		FileOutputStream fos = new FileOutputStream(outFile);
		OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");

		File[] children = thumbDir.listFiles();
		for (int i = 0; i < children.length; i++) {
			String fileName = children[i].getName();
			String lsFileName = fileName.toLowerCase();
			if (!lsFileName.endsWith(".jpg")) {
				continue;
			}
			String cmt = comments.get(lsFileName);
			Integer rating = ratings.get(lsFileName);
			if (cmt == null && rating == null) {
				continue;
			}
			if (cmt == null) {
				cmt = "";
			}
			if (rating == null) {
				rating = new Integer(0);
			}

			osw.write(fileName);
			osw.write('\t');
			osw.write(rating.toString());
			osw.write('\t');
			osw.write(PhotoInfo.convertToLiteral(cmt));
			osw.write('\n');
		}
		osw.flush();
		osw.close();
	}

	public void readInfo() throws Exception {
		File inFile = new File("g:/Photos/" + path + "/photo.info");

		// if the file does not exist, then don't complain, there are
		// simply no comments to read in, go ahead with everything else.
		if (!inFile.exists()) {
			return;
		}
		FileInputStream fis = new FileInputStream(inFile);
		InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
		LineNumberReader lnr = new LineNumberReader(isr);
		String line;
		while ((line = lnr.readLine()) != null) {
			int tabPos = line.indexOf('\t');
			if (tabPos < 0) {
				lnr.close();
				throw new Exception("ExtraInfo record (line) does not have any tabs in it.");
			}
			String fileName = line.substring(0, tabPos);
			String lsFileName = fileName.toLowerCase();
			int startPos = tabPos + 1;
			tabPos = line.indexOf('\t', startPos);
			String ratStr = line.substring(startPos, tabPos);
			int ratval = convertInt(ratStr);
			String cmtEnc = line.substring(tabPos + 1);
			String cmt = PhotoInfo.convertFromLiteral(cmtEnc);
			comments.put(lsFileName, cmt);
			ratings.put(lsFileName, new Integer(ratval));
		}
		lnr.close();
	}

	static public int convertInt(String s) {
		int val = 0;
		if (s == null) {
			return 0;
		}
		for (int i = 0; i < s.length(); i++) {
			char c = s.charAt(i);
			if (c >= '0' && c <= '9') {
				val = val * 10 + (c) - 48;
			}
		}
		return val;
	}
}