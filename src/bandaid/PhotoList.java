package bandaid;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.Hashtable;
import java.util.Iterator;

public class PhotoList {

	public Hashtable<String, PhotoInfo> selection = new Hashtable<String, PhotoInfo>();
	public ArrayList<PhotoInfo> selOrder = new ArrayList<PhotoInfo>();
	public String selName = "";

	public PhotoList() {
	}

	public void saveFile(String fileName) throws Exception {
		fileName = cleanFileName(fileName);
		try {
			File outFile = new File("C:\\sandbox\\TroopData\\" + cleanFileName(fileName) + ".folio");
			FileOutputStream fos = new FileOutputStream(outFile);
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");

			for (PhotoInfo pi : selOrder) {
				pi.writeRecord(osw);
			}
			osw.flush();
			osw.close();
			selName = fileName;
		}
		catch (Exception e) {
			throw new Exception("Unable to save photolist to '" + fileName + "', because ", e);
		}
	}

	public void clear() {
		selection.clear();
		selOrder.clear();
		selName = "";
	}

	public void appendFile(String fileName) throws Exception {
		int lineNum = 0;
		fileName = cleanFileName(fileName);
		try {
			File inFile = new File("C:\\sandbox\\TroopData\\" + cleanFileName(fileName) + ".folio");
			FileInputStream fis = new FileInputStream(inFile);
			InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
			LineNumberReader lnr = new LineNumberReader(isr);

			String line;
			while ((line = lnr.readLine()) != null) {
				lineNum++;
				PhotoInfo pi = new PhotoInfo(null);
				pi.parseRecord(line);
				// eliminate duplicates
				if (!selection.containsKey(pi.fileName)) {
					selOrder.add(pi);
					selection.put(pi.fileName, pi);
				}
			}
			isr.close();
			fis.close();
			selName = fileName;
		}
		catch (Exception e) {
			throw new Exception("Unable to load photolist to '" + fileName + "', at line "
					+ lineNum + " because ", e);
		}
	}

	public void add(String fileName) throws Exception {
		PhotoInfo pi = selection.get(fileName);
		if (pi != null) {
			throw new Exception("That photo is already selected ... got here somehow by error.");
		}
		pi = new PhotoInfo(fileName);
		selection.put(fileName, pi);
		selOrder.add(pi);
	}

	public void remove(String fileName) throws Exception {
		PhotoInfo pi = selection.get(fileName);
		if (pi == null) {
			throw new Exception("Can't find that photo in the selection ... got here by error.");
		}
		selection.remove(fileName);
		selOrder.remove(pi);
	}

	public void moveUp(String fileName) throws Exception {
		PhotoInfo pi = selection.get(fileName);
		if (pi == null) {
			throw new Exception("Can't move the photo, Can't find the photo in the selection.");
		}
		int pos = selOrder.indexOf(pi);
		if (pos < 0) {
			throw new Exception("Got a negative index, this should be impossible.");
		}
		if (pos > 0) {
			selOrder.set(pos, selOrder.get(pos - 1));
			selOrder.set(pos - 1, pi);
		}
	}

	public void moveDown(String fileName) throws Exception {
		PhotoInfo pi = selection.get(fileName);
		if (pi == null) {
			throw new Exception("Can't move the photo, Can't find the photo in the selection.");
		}
		int pos = selOrder.indexOf(pi);
		if (pos < 0) {
			throw new Exception("Got a negative index, this should be impossible.");
		}
		if (pos < selOrder.size() - 1) {
			selOrder.set(pos, selOrder.get(pos + 1));
			selOrder.set(pos + 1, pi);
		}
	}

	public Iterator<PhotoInfo> iterator() {
		return selOrder.iterator();
	}

	public boolean containsKey(String key) {
		return selection.containsKey(key);
	}

	public PhotoInfo get(String key) {
		return selection.get(key);
	}

	public String cleanFileName(String rawName) {
		StringBuffer res = new StringBuffer();
		for (int i = 0; i < rawName.length(); i++) {

			char ch = rawName.charAt(i);
			if (((ch >= 'a') && (ch <= 'z')) || ((ch >= 'A') && (ch <= 'Z'))
					|| ((ch >= '0') && (ch <= '9')) || (ch == '_')) {
				res.append(ch);
			}
		}
		return res.toString();
	}

}
