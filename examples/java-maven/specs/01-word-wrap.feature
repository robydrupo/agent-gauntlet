Feature: Word wrap
  Text is broken into lines that fit inside a given column width.

  Scenario Outline: wrapping text to a width
    Given the text "<text>"
    When I wrap it to a width of <width>
    Then I should get the lines:
      """
      <result>
      """

    Examples:
      | text                | width | result              |
      | hello               | 5     | hello               |
      | hello world         | 5     | hello\nworld        |
      | the quick brown fox | 5     | the\nquick\nbrown\nfox |
      | abcdefghijk         | 5     | abcde\nfghij\nk     |
      | ab cdef             | 5     | ab\ncdef            |

  Scenario: empty text stays empty
    Given the text ""
    When I wrap it to a width of 5
    Then I should get the lines:
      """
      """

  Scenario: a width of zero is refused
    Given the text "hello world"
    When I wrap it to a width of 0
    Then the system refuses with "width must be greater than zero"
