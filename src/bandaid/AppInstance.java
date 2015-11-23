package bandaid;

import bandaid.PhotoSession;
import bogus.UtilityMethods;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStreamReader;
import java.io.LineNumberReader;
import java.io.OutputStreamWriter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Vector;

/**
 * The whole point of this class is to provide a place to store settings that
 * are unique to a particular application instance. This will define all the
 * various settings, such as where the user data is defined as well as were all
 * the files are stored. This object has to hold whatever caches there are so
 * that caches are not mixed across applications.
 */
public class AppInstance {

	private static Hashtable<String, AppInstance> knownApps = new Hashtable<String, AppInstance>();

	private Hashtable<String, PhotoSession> knownSessions = null;
	private Hashtable<String, String> vals = null;

	public ArrayList<Event> allEvents = null;
	public Hashtable<String, Member> allMembers = null;
	public Hashtable<String, Hashtable<String, String>> controlLists = null;

	public String mainDir;

	/**
	 * pass the path to the config directory and this will load all the
	 * parameters for an application
	 */
	public static AppInstance findApp(String mainDir) throws Exception {
		if (knownApps == null) {
			knownApps = new Hashtable<String, AppInstance>();
		}

		AppInstance a = knownApps.get(mainDir);
		if (a != null) {
			return a;
		}

		a = new AppInstance(mainDir);
		return a;
	}

	private AppInstance(String d) throws Exception {
		mainDir = d;
		if (!d.endsWith("/")) {
			mainDir = d + "/";
		}

		File confFile = new File(d + "theApp.conf");
		if (!confFile.exists()) {
			throw new Exception(
					"The config file (theApp.conf) was not found in the data directory (" + mainDir
							+ ").");
		}
		knownSessions = new Hashtable<String, PhotoSession>();
		vals = new Hashtable<String, String>();
		controlLists = new Hashtable<String, Hashtable<String, String>>();

		FileInputStream fis = new FileInputStream(confFile);
		InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
		LineNumberReader lnr = new LineNumberReader(isr);

		String line;
		while ((line = lnr.readLine()) != null) {
			// ignore comments
			if (line.startsWith("#")) {
				continue;
			}
			int colonPos = line.indexOf(':');
			if (colonPos < 0) {
				continue;
			}
			String name = line.substring(0, colonPos).trim();
			String val = line.substring(colonPos + 1).trim();
			vals.put(name, val);
		}
		lnr.close();
	}

	public PhotoSession findSession(String userName, String password) throws Exception {
		if (userName == null) {
			throw new Exception("Must specify a 'userName' in order to get a PhotoSession");
		}
		synchronized (knownSessions) {
			userName = userName.toLowerCase();
			PhotoSession ps = knownSessions.get(userName);
			if (ps != null) {
				return ps;
			}

			ps = new PhotoSession(userName, password, this);
			knownSessions.put(userName, ps);
			return ps;
		}
	}

	public synchronized void readMembersFile() throws Exception {
		int lineNo = 0;
		String fileName = mainDir + "Members.txt";
		if (allMembers != null) {
			return;
		}
		StringBuffer debug = new StringBuffer();
		try {
			Hashtable<String, Member> tMembers = new Hashtable<String, Member>();
			File eventFile = new File(fileName);
			if (!eventFile.exists()) {
				throw new Exception("The file (Members.txt) was not found in the data directory ("
						+ mainDir + ")");
			}
			FileInputStream fis = new FileInputStream(eventFile);
			InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
			LineNumberReader lnr = new LineNumberReader(isr);

			String line = lnr.readLine();
			while (line != null) {
				lineNo++;
				// debug.append(" starting line "+lineNo);
				if (line.length() < 3) {
					continue; // line too short
				}
				if (line.charAt(0) == '#') {
					continue; // comment out line
				}
				debug.append(", construct member,");
				Member mem = new Member(this, line);
				// debug.append(" putting in table,");
				tMembers.put(mem.id, mem);
				// debug.append(" reading new line,");
				line = lnr.readLine();
			}
			allMembers = tMembers;
			lnr.close();
		}
		catch (Exception e) {
			throw new Exception("Unable to read the members file (" + fileName + ") at line "
					+ lineNo + ".  " + debug.toString() + UtilityMethods.getErrorString(e));
		}
	}

	public synchronized void saveMembersFile() throws Exception {
		try {
			File eventFile = new File(mainDir + "Members.txt");
			FileOutputStream fos = new FileOutputStream(eventFile);
			OutputStreamWriter osw = new OutputStreamWriter(fos, "UTF-8");
			Enumeration<Member> e = allMembers.elements();
			while (e.hasMoreElements()) {
				Member mem = e.nextElement();
				osw.write(mem.id);
				osw.write(":");
				osw.write(mem.email);
				osw.write(":");
				osw.write(mem.name);
				osw.write(":");
				osw.write(mem.password);
				osw.write("\n");
			}
			osw.flush();
			fos.close();
		}
		catch (Exception e) {
			throw new Exception("Unable to save members file. " + UtilityMethods.getErrorString(e));
		}
	}

	public synchronized void addMember(String email, String name, String password) throws Exception {
		if (email.indexOf(':') >= 0) {
			throw new Exception("The email address is not allowed to have a colon in it");
		}
		if (name.indexOf(':') >= 0) {
			throw new Exception("The name is not allowed to have a colon in it");
		}
		if (password.indexOf(':') >= 0) {
			throw new Exception("The password is not allowed to have a colon in it");
		}
		Member mem = new Member(this, email.toLowerCase(), name, password);
		allMembers.put(mem.id, mem);
	}

	public synchronized void removeMember(String id) throws Exception {
		allMembers.remove(id);
	}

	public synchronized Member findMember(String emailKey) throws Exception {
		if (emailKey == null) {
			return null;
		}
		if (allMembers == null) {
			readMembersFile();
		}
		Enumeration<Member> keys = byName();
		while (keys.hasMoreElements()) {
			Member mem = keys.nextElement();
			if (emailKey.equals(mem.email)) {
				return mem;
			}
		}
		return null;
	}

	public synchronized Member findMemberById(String id) throws Exception {
		if (id == null) {
			return null;
		}
		if (allMembers == null) {
			readMembersFile();
		}
		Enumeration<Member> keys = byName();
		while (keys.hasMoreElements()) {
			Member mem = keys.nextElement();
			if (id.equals(mem.id)) {
				return mem;
			}
		}
		return null;
	}

	public synchronized Member authenticateMember(String userName, String password)
			throws Exception {
		if (userName == null) {
			Thread.sleep(3000);
			throw new Exception("You must provide a User Name!");
		}
		if (password == null) {
			Thread.sleep(3000);
			throw new Exception("You must provide a Password!");
		}
		userName = userName.trim().toLowerCase();
		password = password.trim();
		if (userName.length() == 0 || password.length() == 0) {
			Thread.sleep(3000);
			throw new Exception("You must provide a User Name and Password!");
		}

		Member mem = findMember(userName);

		if (mem == null) {
			Thread.sleep(3000); // sleep 3 seconds on any failure to make it
								// hard to guess using automated means.
			throw new Exception("Either your username (" + userName
					+ ") or your password is not valid.  Press the backbutton and try again");
		}

		if (!password.equals(mem.password)) {
			Thread.sleep(3000);
			throw new Exception("Either your username (" + userName
					+ ") or your password is not valid.  Press the backbutton and try again");
		}
		return mem;
	}

	public synchronized Member findRequiredMember(String emailKey) throws Exception {
		Member mem = findMember(emailKey);
		if (mem == null) {
			throw new Exception("Can not find any member with the address of '" + emailKey + "'.");
		}
		return mem;
	}

	public synchronized Enumeration<String> keys() throws Exception {
		return sortEnumeration(allMembers.keys());
	}

	public synchronized Enumeration<Member> byEmail() throws Exception {
		try {
			if (allMembers == null) {
				readMembersFile();
			}
			Vector<Member> keys = new Vector<Member>();
			Enumeration<Member> basic = allMembers.elements();
			while (basic.hasMoreElements()) {
				keys.add(basic.nextElement());
			}
			Comparator<Member> sc = new MemberEmailComparator();
			Collections.sort(keys, sc);
			return keys.elements();
		}
		catch (Exception e) {
			throw new Exception("Failure creating a sorted Enumeration object.  ", e);
		}
	}

	public synchronized Enumeration<Member> byName() throws Exception {
		try {
			if (allMembers == null) {
				readMembersFile();
			}
			Vector<Member> keys = new Vector<Member>();
			Enumeration<Member> basic = allMembers.elements();
			while (basic.hasMoreElements()) {
				keys.add(basic.nextElement());
			}
			Comparator<Member> sc = new MemberNameComparator();
			Collections.sort(keys, sc);
			return keys.elements();
		}
		catch (Exception e) {
			throw new Exception("Failure creating a sorted Enumeration object.  ",e);
		}
	}

	static class StringComparator implements Comparator<String> {
		public StringComparator() {
		}

		public int compare(String o1, String o2) {
			return o1.compareToIgnoreCase(o2);
		}
	}

	static class MemberNameComparator implements Comparator<Member> {
		public MemberNameComparator() {
		}

		public int compare(Member o1, Member o2) {
			return o1.name.compareToIgnoreCase(o2.name);
		}
	}

	static class MemberEmailComparator implements Comparator<Member> {
		public MemberEmailComparator() {
		}

		public int compare(Member o1, Member o2) {
			return o1.email.compareToIgnoreCase(o2.email);
		}
	}

	public synchronized Enumeration<String> sortEnumeration(Enumeration<String> unsorted)
			throws Exception {
		try {
			Vector<String> keys = new Vector<String>();
			while (unsorted.hasMoreElements()) {
				keys.add(unsorted.nextElement());
			}

			Comparator<String> sc = new StringComparator();
			Collections.sort(keys, sc);

			return keys.elements();
		}
		catch (Exception e) {
			throw new Exception("Failure creating a sorted Enumeration object.  ", e);
		}
	}

	public boolean hasPermission(String email, String controlName) throws Exception {
		Hashtable<String, String> oneList = controlLists.get(controlName);

		if (oneList == null) {
			File eventFile = new File(mainDir + controlName + ".acl");
			if (!eventFile.exists()) {
				throw new Exception("The file '" + eventFile.getName()
						+ "' was not found in the data directory");
			}

			FileInputStream fis = new FileInputStream(eventFile);
			InputStreamReader isr = new InputStreamReader(fis, "UTF-8");
			LineNumberReader lnr = new LineNumberReader(isr);

			oneList = new Hashtable<String, String>();

			String line;
			while ((line = lnr.readLine()) != null) {
				line = line.trim();
				oneList.put(line, line);
			}
			controlLists.put(controlName, oneList);
			lnr.close();
		}
		return (oneList.get(email) != null);
	}

	public String getParam(String name, String defval) {
		String res = vals.get(name);
		if (res == null) {
			res = defval;
		}
		return res;
	}
}