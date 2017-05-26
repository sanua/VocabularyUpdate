package com.odysseusinc.util;

import java.io.IOException;

/**
 * Created by Sanders on 3/16/2017.
 */
public class StringBuilderWrapper implements Appendable {
    private static final String IDENT_CHAR = "    ";

    private StringBuilder wrapped = new StringBuilder();

    public Appendable append(CharSequence csq) throws IOException {
        wrapped.append(IDENT_CHAR).append(csq);
        return this;
    }

    public Appendable append(CharSequence csq, int start, int end) throws IOException {
        wrapped.append(IDENT_CHAR).append(csq, start, end);
        return this;

    }

    public Appendable append(char c) throws IOException {
        wrapped.append(IDENT_CHAR).append(c);
        return this;
    }

    public String toString() {
        return wrapped.toString();
    }
}