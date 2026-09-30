package fr.claimflow;

import org.junit.jupiter.api.Test;
import org.springframework.modulith.core.ApplicationModules;
import org.springframework.modulith.docs.Documenter;

/**
 * Frontières des modules (ADR-001) : échoue en cas de cycle entre modules ou d'accès à un
 * sous-package interne d'un autre module. C'est ce test qui bloque la pull request de la démo
 * de fin de sprint 0.
 */
class ArchitectureTest {

    private final ApplicationModules modules = ApplicationModules.of(ClaimFlowApplication.class);

    @Test
    void les_modules_respectent_leurs_frontieres() {
        modules.verify();
    }

    @Test
    void documente_les_modules() {
        // Diagrammes PlantUML régénérés à chaque build, dans target/spring-modulith-docs.
        new Documenter(modules).writeModulesAsPlantUml();
    }
}
