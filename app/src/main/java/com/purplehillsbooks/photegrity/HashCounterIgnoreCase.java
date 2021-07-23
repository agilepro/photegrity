package com.purplehillsbooks.photegrity;

public class HashCounterIgnoreCase extends HashCounter {

	private static final long serialVersionUID = 1L;

	public HashCounterIgnoreCase() {
		super();
	}

	public void decrement(String val) throws Exception {
		super.decrement(val.toLowerCase());
	}

	public void increment(String val) throws Exception {
		super.increment(val.toLowerCase());
	}

	public int getCount(String val) {
		return super.getCount(val.toLowerCase());
	}

}
