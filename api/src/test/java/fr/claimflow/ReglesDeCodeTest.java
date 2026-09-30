package fr.claimflow;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.fields;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noMethods;
import static com.tngtech.archunit.library.GeneralCodingRules.NO_CLASSES_SHOULD_ACCESS_STANDARD_STREAMS;
import static com.tngtech.archunit.library.GeneralCodingRules.NO_CLASSES_SHOULD_USE_FIELD_INJECTION;
import static com.tngtech.archunit.library.GeneralCodingRules.NO_CLASSES_SHOULD_USE_JAVA_UTIL_LOGGING;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * Règles de code vérifiées à chaque build. Elles traduisent les ADR en contrôles automatiques et
 * s'appliquent au code écrit à la main comme au code produit avec l'IA (AGENTS.md).
 * Le code généré depuis le contrat OpenAPI est exclu.
 */
@AnalyzeClasses(packages = "fr.claimflow", importOptions = ImportOption.DoNotIncludeTests.class)
class ReglesDeCodeTest {

    private static final String CODE_GENERE = "fr.claimflow.openapi..";

    @ArchTest
    static final ArchRule pas_de_flottant_pour_l_argent = fields()
            .that().areDeclaredInClassesThat().resideOutsideOfPackage(CODE_GENERE)
            .should().notHaveRawType(double.class)
            .andShould().notHaveRawType(float.class)
            .andShould().notHaveRawType(Double.class)
            .andShould().notHaveRawType(Float.class)
            .because("les montants sont des BigDecimal encapsulés dans Montant (ADR-012)");

    @ArchTest
    static final ArchRule pas_de_setter_de_statut = noMethods()
            .that().areDeclaredInClassesThat().resideOutsideOfPackage(CODE_GENERE)
            .should().haveNameMatching("set[Ss]tatut.*")
            .because("le statut n'évolue que par les commandes de la machine à états (ADR-004)");

    @ArchTest
    static final ArchRule le_domaine_ignore_le_web = noClasses()
            .that().resideInAPackage("fr.claimflow..domain..")
            .should().dependOnClassesThat()
            .resideInAnyPackage("org.springframework.web..", "jakarta.servlet..", CODE_GENERE)
            .because("le domaine ne connaît ni HTTP ni le contrat d'API");

    @ArchTest
    static final ArchRule pas_de_date_historique = noClasses()
            .that().resideOutsideOfPackage(CODE_GENERE)
            .should().dependOnClassesThat().haveFullyQualifiedName("java.util.Date")
            .because("les dates métier sont des LocalDate et les horodatages des Instant (AGENTS.md)");

    @ArchTest
    static final ArchRule pas_d_injection_par_champ = NO_CLASSES_SHOULD_USE_FIELD_INJECTION;

    @ArchTest
    static final ArchRule pas_de_sortie_console = NO_CLASSES_SHOULD_ACCESS_STANDARD_STREAMS;

    @ArchTest
    static final ArchRule pas_de_java_util_logging = NO_CLASSES_SHOULD_USE_JAVA_UTIL_LOGGING;
}
