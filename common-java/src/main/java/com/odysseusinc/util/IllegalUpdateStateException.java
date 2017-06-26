package com.odysseusinc.util;

/**
 * Created by Sanders on 6/26/2017.
 */
public class IllegalUpdateStateException extends Exception {
    public IllegalUpdateStateException(String message) {
        super(message);
    }
    public IllegalUpdateStateException(Throwable cause) {
        super(cause);
    }
    public IllegalUpdateStateException(String message, Throwable cause) {
        super(message, cause);
    }
}