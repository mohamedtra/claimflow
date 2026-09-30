package fr.claimflow;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Point d'entrée de l'API ClaimFlow.
 *
 * <p>Monolithe modulaire (ADR-001) : chaque package placé directement sous {@code fr.claimflow} est un
 * module Spring Modulith. Seul son package racine est visible des autres modules ; ses sous-packages
 * ({@code domain}, {@code application}, {@code infrastructure}, {@code web}) sont internes.
 */
@SpringBootApplication
public class ClaimFlowApplication {

    public static void main(String[] args) {
        SpringApplication.run(ClaimFlowApplication.class, args);
    }
}
