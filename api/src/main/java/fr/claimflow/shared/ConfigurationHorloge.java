package fr.claimflow.shared;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Horloge de l'application. Les dates métier utilisent le fuseau Europe/Paris et l'horloge peut
 * être remplacée par une horloge figée dans les tests.
 */
@Configuration(proxyBeanMethods = false)
class ConfigurationHorloge {

    @Bean
    Clock horloge() {
        return Clock.system(ZoneId.of("Europe/Paris"));
    }
}
