package inc.odysses.utils;

import java.io.IOException;

/**
 * Created by Sanders on 3/16/2017.
 */
public class StringBuilderWrapper implements java.lang.Appendable {
    private static final String IDENT_CHAR = "    ";

    private StringBuilder wrapped = new StringBuilder();

    @Override
    public Appendable append(CharSequence csq) throws IOException {
        wrapped.append(IDENT_CHAR).append(csq);
        return this;
    }
    @Override
    public Appendable append(CharSequence csq, int start, int end) throws IOException {
        wrapped.append(IDENT_CHAR).append(csq, start, end);
        return this;

    }
    @Override
    public Appendable append(char c) throws IOException {
        wrapped.append(IDENT_CHAR).append(c);
        return this;
    }
    @Override
    public String toString() {
        return wrapped.toString();
    }
}