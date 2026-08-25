package wordwrap.acceptance;

import io.cucumber.java.en.Given;
import io.cucumber.java.en.Then;
import io.cucumber.java.en.When;
import wordwrap.domain.WordWrapper;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;

public class WordWrapSteps {

    private String text;
    private String result;
    private String refusal;

    @Given("the text {string}")
    public void the_text(String text) {
        this.text = text;
    }

    @When("I wrap it to a width of {int}")
    public void i_wrap_it_to_a_width_of(int width) {
        try {
            result = new WordWrapper().wrap(text, width);
        } catch (IllegalArgumentException e) {
            refusal = e.getMessage();
        }
    }

    @Then("I should get the lines:")
    public void i_should_get_the_lines(String expected) {
        assertEquals(expected.replace("\\n", "\n"), result);
    }

    @Then("the system refuses with {string}")
    public void the_system_refuses_with(String message) {
        assertNotNull(refusal);
        assertEquals(message, refusal);
    }
}
