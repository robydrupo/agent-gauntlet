package wordwrap.cli;

import wordwrap.domain.WordWrapper;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class Main {

    public static void main(String[] args) throws IOException {
        if (args.length != 1) {
            System.err.println("usage: wordwrap <width>   (text is read from stdin)");
            System.exit(2);
        }
        String text = readAll(System.in);
        try {
            System.out.println(new WordWrapper().wrap(text, Integer.parseInt(args[0])));
        } catch (IllegalArgumentException e) {
            System.err.println("error: " + e.getMessage());
            System.exit(1);
        }
    }

    private static String readAll(InputStream in) throws IOException {
        ByteArrayOutputStream buffer = new ByteArrayOutputStream();
        in.transferTo(buffer);
        return buffer.toString(StandardCharsets.UTF_8).strip();
    }
}
