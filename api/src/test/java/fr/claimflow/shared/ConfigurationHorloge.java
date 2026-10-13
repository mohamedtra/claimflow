package fr.claimflow.shared;

import java.time.Clock;
import java.time.ZoneId;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

/**
 * Horloge de l'application. Les dates métier sont celles de Paris : un sinistre survenu à 0 h 30
 * l'est le jour même, et non la veille comme en UTC. Injectée, elle peut être figée en test.
 */
@Configuration(proxyBeanMethods = false)
class ConfigurationHorloge {

    @Bean
    @Primary
    Clock horloge() {
        return Clock.system(ZoneId.of("Europe/Paris"));
    }
}
