package wordwrap.domain;

public class WordWrapper {

    public String wrap(String text, int width) {
        if (width <= 0) {
            throw new IllegalArgumentException("width must be greater than zero");
        }
        if (text.length() <= width) {
            return text;
        }
        int breakAt = breakPoint(text, width);
        return text.substring(0, breakAt).stripTrailing()
                + "\n"
                + wrap(text.substring(breakAt).stripLeading(), width);
    }

    private int breakPoint(String text, int width) {
        int lastSpace = text.lastIndexOf(' ', width);
        return lastSpace > 0 ? lastSpace : width;
    }
}
