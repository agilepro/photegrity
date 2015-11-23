package bandaid;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStreamWriter;
import java.text.DateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Date;
import java.util.Hashtable;
import java.util.Iterator;

public class Event {

	public long dateMillis;
	public long startMillis;
	public long durMillis;
	public String fileName;
	public String name;
	public String description;

	public Hashtable<String, Attend> attendance;

	private AppInstance thisApp = null;

	public static DateFormat dForm = DateFormat.getDateInstance(DateFormat.MEDIUM);
	public static DateFormat tForm = DateFormat.getTimeInstance(DateFormat.SHORT);
	public static DateFormat dtForm = DateFormat.getDateTimeInstance(DateFormat.MEDIUM,
			DateFormat.MEDIUM);

	public Event(AppInstance a) {
		thisApp = a;
		dateMillis = (new Date()).getTime();
		startMillis = 0;
		durMillis = 0;
		name = "Unknown";
		attendance = new Hashtable<String, Attend>();
		description = "";
	}

	public static Event readEventFile(AppInstance app, String fn) throws Exception {
		try {
			File eventFile = new File(app.mainDir + fn);
			if (!eventFile.exists()) {
				throw new Exception("The file (" + fn + ") was not found in the data directory ("
						+ app.mainDir + ")");
			}

			FileInputStream fis = new FileInputStream(eventFile);
			InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
			LineNumberReader lnr = new LineNumberReader(isr);

			Event newEvent = new Event(app);
			newEvent.fileName = fn;
			String line = lnr.readLine();
			if (line == null) {
				fis.close();
				return newEvent;
			}

			newEvent.name = line;
			line = lnr.readLine();
			if (line == null) {
				fis.close();
				return newEvent;
			}
			newEvent.dateMillis = Long.parseLong(line);
			line = lnr.readLine();
			if (line == null) {
				fis.close();
				return newEvent;
			}
			newEvent.startMillis = Long.parseLong(line);
			line = lnr.readLine();
			if (line == null) {
				fis.close();
				return newEvent;
			}
			newEvent.durMillis = Long.parseLong(line);

			line = lnr.readLine();
			if (line == null) {
				fis.close();
				return newEvent;
			}
			StringBuffer desc = new StringBuffer();
			while (line.startsWith("d:")) {
				desc.append(line.substring(2));
				desc.append('\n');
				line = lnr.readLine();
				if (line == null) {
					newEvent.description = desc.toString();
					lnr.close();
					return newEvent;
				}
			}
			newEvent.description = desc.toString();

			while (line.startsWith("a:")) {
				Attend a = Attend.parseAttendLine(line);
				newEvent.attendance.put(a.person, a);
				line = lnr.readLine();
				if (line == null) {
					lnr.close();
					return newEvent;
				}
			}

			lnr.close();
			return newEvent;
		}
		catch (Exception e) {
			throw new Exception("Unable to read the event file '" + fn + "' because ", e);
		}
	}

	public static void loadAllEvents(AppInstance app) throws Exception {
		if (app.allEvents != null) {
			return; // already loaded
		}
		ArrayList<Event> newEvents = new ArrayList<Event>();

		File thumbDir = new File(app.mainDir);
		if (!thumbDir.exists()) {
			throw new Exception(
					"Sorry, system is not configured correctly, the data directory is missing )"
							+ app.mainDir + ").");
		}
		if (!thumbDir.isDirectory()) {
			throw new Exception(
					"Sorry, system is not configured correctly, the data directory is missing )"
							+ app.mainDir + ").");
		}

		File[] children = thumbDir.listFiles();
		for (int i = 0; i < children.length; i++) {
			File cFile = children[i];
			String fileName = cFile.getName();
			if (fileName.endsWith(".event")) {
				Event ev = Event.readEventFile(app, fileName);
				newEvents.add(ev);
			}
		}

		app.allEvents = newEvents;
	}

	public void saveEventFile() throws Exception {
		if (name == null) {
			throw new Exception("How did the name field get null?");
		}
		try {
			File eventFile = new File(thisApp.mainDir + fileName);
			FileOutputStream fos = new FileOutputStream(eventFile);
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");

			osw.write(name);
			osw.write("\n");

			osw.write(Long.toString(dateMillis));
			osw.write("\n");
			osw.write(Long.toString(startMillis));
			osw.write("\n");
			osw.write(Long.toString(durMillis));
			osw.write("\n");

			int startPos = 0;
			int newlinePos = description.indexOf('\n');
			while (newlinePos >= startPos) {
				osw.write("d:");
				osw.write(description.substring(startPos, newlinePos));
				osw.write("\n");
				startPos = newlinePos + 1;
				newlinePos = description.indexOf('\n', startPos);
			}
			osw.write("d:");
			osw.write(description.substring(startPos));
			osw.write("\n");

			for (String key : attendance.keySet()) {
				Attend at = attendance.get(key);
				if (at == null) {
					throw new Exception("Huh?  got a key, but element is null?");
				}
				at.writeLine(osw);
			}

			osw.flush();
			osw.close();

		}
		catch (Exception e) {
			throw new Exception("Unable to save the event information to the file '" + fileName
					+ "' because ", e);
		}
	}

	public static Event findEvent(AppInstance app, String name) throws Exception {
		if (app.allEvents == null) {
			loadAllEvents(app);
		}
		Iterator<Event> it = app.allEvents.iterator();
		while (it.hasNext()) {
			Event ev = it.next();
			if (ev.fileName.equals(name)) {
				return ev;
			}
		}
		return null;
	}

	public static Event findRequiredEvent(AppInstance app, String name) throws Exception {
		Event ev = findEvent(app, name);
		if (ev == null) {
			throw new Exception("Can not find any event named '" + name + "'.");
		}
		return ev;
	}

	public Attend getAttendance(String email) throws Exception {
		Attend att = attendance.get(email);
		if (att != null) {
			return att;
		}
		return new Attend(email, 0, "");
	}

	public void setAttendance(Attend newVal) {
		if (newVal.status == 0 && newVal.comment.length() == 0) {
			// this is the special default case, so instead 'delete' the entry
			// if it exists
			attendance.remove(newVal.person);
		}
		else {
			attendance.put(newVal.person, newVal);
		}
	}

	public String getDateStr() {
		// Calendar rightNow = Calendar.getInstance();
		return dForm.format(new Date(dateMillis + startMillis));
	}

	public String getStartTime() {
		return tForm.format(new Date(dateMillis + startMillis));
	}

	public String getEndTime() {
		return tForm.format(new Date(dateMillis + startMillis + durMillis));
	}

	public String getTimeRange() {
		StringBuffer tx = new StringBuffer();
		String dt = tForm.format(new Date(dateMillis + startMillis));
		int spacePos = dt.indexOf(" ");
		tx.append(dt.substring(0, spacePos));
		tx.append(" - ");
		dt = tForm.format(new Date(dateMillis + startMillis + durMillis));
		spacePos = dt.indexOf(" ");
		tx.append(dt.substring(0, spacePos));
		return tx.toString();
	}

	public void setDateStr(String dStr) throws Exception {
		Calendar cal = Calendar.getInstance();
		cal.setTime(dForm.parse(dStr));
		int year = cal.get(Calendar.YEAR);
		int month = cal.get(Calendar.MONTH);
		int day = cal.get(Calendar.DATE);
		cal.set(year, month, day, 0, 0, 0);
		dateMillis = cal.getTimeInMillis();
	}

	public void setStartTime(String dStr) throws Exception {
		long endTime = startMillis + durMillis;
		// the 8 hour correction is a time zone correction to find the time of
		// day in this time zone.
		// should find a way to derive this from the local settings
		startMillis = tForm.parse(dStr).getTime() - (8 * 60 * 60 * 1000);
		durMillis = endTime - startMillis;
	}

	public void setEndTime(String dStr) throws Exception {
		durMillis = (tForm.parse(dStr).getTime()) - (8 * 60 * 60 * 1000) - startMillis;
	}

}