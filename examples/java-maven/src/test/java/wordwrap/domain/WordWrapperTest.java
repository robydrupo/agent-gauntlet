package wordwrap.domain;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class WordWrapperTest {

    private final WordWrapper wrapper = new WordWrapper();

    @Test
    void empty_text_wraps_to_empty_text() {
        assertEquals("", wrapper.wrap("", 5));
    }

    @Test
    void text_shorter_than_the_width_is_untouched() {
        assertEquals("hi", wrapper.wrap("hi", 5));
    }

    @Test
    void text_exactly_the_width_is_untouched() {
        assertEquals("hello", wrapper.wrap("hello", 5));
    }

    @Test
    void breaks_at_the_last_space_that_fits() {
        assertEquals("hello\nworld", wrapper.wrap("hello world", 5));
    }

    @Test
    void the_space_broken_on_does_not_start_the_next_line() {
        assertEquals("ab\ncd", wrapper.wrap("ab cd", 3));
    }

    @Test
    void a_whole_word_moves_down_rather_than_being_split() {
        assertEquals("ab\ncdef", wrapper.wrap("ab cdef", 5));
    }

    @Test
    void a_word_longer_than_the_width_is_split_at_the_width() {
        assertEquals("abcde\nfghij\nk", wrapper.wrap("abcdefghijk", 5));
    }

    @Test
    void wraps_across_many_lines() {
        assertEquals("the\nquick\nbrown\nfox", wrapper.wrap("the quick brown fox", 5));
    }

    @Test
    void a_leading_space_is_not_treated_as_a_break_point() {
        assertEquals(" abcd\ne", wrapper.wrap(" abcde", 5));
    }

    @Test
    void a_width_of_zero_is_rejected() {
        assertThrows(IllegalArgumentException.class, () -> wrapper.wrap("anything", 0));
    }

    @Test
    void a_negative_width_is_rejected() {
        assertThrows(IllegalArgumentException.class, () -> wrapper.wrap("anything", -1));
    }
}
