package wordwrap.architecture;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;

import static com.tngtech.archunit.library.dependencies.SlicesRuleDefinition.slices;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

/**
 * GATE 2 of the gauntlet. Executable form of architecture.md.
 * Deterministic: it either passes or it does not. No agent gets a vote.
 */
class ArchitectureTest {

    private static JavaClasses production;

    @BeforeAll
    static void importProductionCode() {
        production = new ClassFileImporter()
                .withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
                .importPackages("wordwrap");
    }

    @Test
    void domain_must_not_depend_on_cli() {
        noClasses().that().resideInAPackage("..domain..")
                .should().dependOnClassesThat().resideInAPackage("..cli..")
                .check(production);
    }

    @Test
    void domain_must_not_do_io() {
        noClasses().that().resideInAPackage("..domain..")
                .should().dependOnClassesThat().resideInAnyPackage("java.io..", "java.nio.file..")
                .check(production);
    }

    @Test
    void domain_must_not_print() {
        noClasses().that().resideInAPackage("..domain..")
                .should().accessField(System.class, "out")
                .orShould().accessField(System.class, "err")
                .check(production);
    }

    @Test
    void there_must_be_no_package_cycles() {
        slices().matching("wordwrap.(*)..").should().beFreeOfCycles()
                .check(production);
    }
}
