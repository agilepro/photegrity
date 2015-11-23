package bandaid;

import java.util.Enumeration;

public class Member {
	public String id;
	public String email;
	public String name;
	public String password;

	public AppInstance thisApp;

	public Member(AppInstance app, String line) throws Exception {
		try {
			thisApp = app;
			if (line == null) {
				throw new Exception("A null 'line' value was passed to the Member constructor");
			}

			// pattern is id:email:name:password
			int colonPos = line.indexOf(':');
			if (colonPos < 0) {
				throw new Exception("Could not find the first colon");
			}
			id = line.substring(0, colonPos).toLowerCase();
			int startPos = colonPos + 1;
			colonPos = line.indexOf(':', startPos);
			if (colonPos < 0) {
				throw new Exception("Could not find the second colon");
			}
			email = line.substring(startPos, colonPos).toLowerCase();
			startPos = colonPos + 1;
			colonPos = line.indexOf(':', startPos);
			if (colonPos < 0) {
				throw new Exception("Could not find the third colon");
			}
			name = line.substring(startPos, colonPos);
			startPos = colonPos + 1;
			password = line.substring(startPos);
		}
		catch (Exception e) {
			throw new Exception("Unable to construct a member object.", e);
		}
	}

	public Member(AppInstance app, String e, String n, String p) throws Exception {
		thisApp = app;
		// find a suitable id to use
		boolean found = true;
		while (found) {
			// pick an arbitrary number from 1000 - 9999
			id = Long.toString((System.currentTimeMillis() % 9000) + 1000);
			Enumeration<Member> keys = app.byName();
			found = false;
			while (keys.hasMoreElements()) {
				Member mem = keys.nextElement();
				if (id.equals(mem.id)) {
					found = true;
					break;
				}
			}
		}
		email = e;
		name = n;
		password = p;
	}

	public boolean hasPermission(String controlName) throws Exception {
		return thisApp.hasPermission(email, controlName);
	}

}