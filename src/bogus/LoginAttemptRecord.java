/********************************************************************************
 *                                                                              *
 *  COPYRIGHT (C) 1997-2002 FUJITSU SOFTWARE CORPORATION.  ALL RIGHTS RESERVED. *
 *                                                                              *
 ********************************************************************************/
package bogus;

import java.util.Hashtable;

import com.purplehillsbooks.json.JSONException;

/**
 * This class help to support user authentication failure counting and lockout
 * timing. It maintains a hashtable of login attempt counts along with
 * timestamps of the attempt. Every failure to login increments the count up to
 * a threshold. After the threshold is reached, a timeperiod must be waited
 * before further login attempts can be tried.
 * 
 */
public class LoginAttemptRecord {

	String ipAddress;
	int attemptCount;
	long timeOfLastAttempt;

	public static int loginLimit = 6;
	public static int loginLockoutMinutes = 10;

	static Hashtable<String, LoginAttemptRecord> attemptMap = new Hashtable<String, LoginAttemptRecord>();

	private LoginAttemptRecord(String addr) {
		ipAddress = addr;
		attemptCount = 1;
		timeOfLastAttempt = System.currentTimeMillis();
	}

	public static void checkLoginThreshold(String addr) throws Exception {
		LoginAttemptRecord lar = getRecord(addr);

		// no record, then all is OK
		if (lar == null) {
			return;
		}

		// see if under limit
		if (lar.attemptCount <= loginLimit) {
			return;
		}

		// see if waited long enough, if so clear record
		if (lar.timeOfLastAttempt + (loginLockoutMinutes * 60000) < System.currentTimeMillis()) {
			attemptMap.remove(addr);
			return;
		}

		// now complain about it
		Exception me = new JSONException("You have reached the login attempt limit of {0}. You will be locked out for {1} minutes.",
		        loginLimit,loginLockoutMinutes);
		throw me;
	}

	public static synchronized void incrementCount(String addr) {
		LoginAttemptRecord lar = getRecord(addr);

		if (lar == null) {
			lar = new LoginAttemptRecord(addr);
			attemptMap.put(addr, lar);
		}
		else {
			lar.attemptCount++;
			lar.timeOfLastAttempt = System.currentTimeMillis();
		}
	}

	public static synchronized void clearCount(String addr) {
		attemptMap.remove(addr);
	}

	public static int triesLeft(String addr) {
		LoginAttemptRecord lar = getRecord(addr);
		if (lar == null) {
			return loginLimit;
		}
		return (loginLimit - lar.attemptCount + 1);
	}

	public static LoginAttemptRecord getRecord(String addr) {
		return attemptMap.get(addr);
	}

}
