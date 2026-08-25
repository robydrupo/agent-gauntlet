package wordwrap.acceptance;

import org.junit.platform.suite.api.ConfigurationParameter;
import org.junit.platform.suite.api.IncludeEngines;
import org.junit.platform.suite.api.SelectDirectories;
import org.junit.platform.suite.api.Suite;

import static io.cucumber.junit.platform.engine.Constants.GLUE_PROPERTY_NAME;
import static io.cucumber.junit.platform.engine.Constants.PLUGIN_PROPERTY_NAME;

/**
 * Harness, not agent output. Runs every .feature file the Specifier wrote into specs/.
 * Step definitions live beside this class and are written by the Coder agent.
 */
@Suite
@IncludeEngines("cucumber")
@SelectDirectories("specs")
@ConfigurationParameter(key = GLUE_PROPERTY_NAME, value = "wordwrap.acceptance")
@ConfigurationParameter(key = PLUGIN_PROPERTY_NAME, value = "pretty")
public class RunCucumberTest {
}
