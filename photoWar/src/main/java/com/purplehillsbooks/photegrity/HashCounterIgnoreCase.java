package com.purplehillsbooks.photegrity;

public class HashCounterIgnoreCase extends HashCounter {

    private static final long serialVersionUID = 1L;

    public HashCounterIgnoreCase() {
        super();
    }

    @Override
    public void decrement(String val) {
        super.decrement(val.toLowerCase());
    }

    @Override
    public void increment(String val) {
        super.increment(val.toLowerCase());
    }

    @Override
    public int getCount(String val) {
        return super.getCount(val.toLowerCase());
    }

    @Override
    public void changeBy(String val, int num) {
        super.changeBy(val.toLowerCase(), num);
    }
}
