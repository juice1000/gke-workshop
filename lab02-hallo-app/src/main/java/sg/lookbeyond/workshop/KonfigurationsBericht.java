package sg.lookbeyond.workshop;

import java.nio.file.Files;
import java.nio.file.Path;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.stereotype.Component;

/**
 * Eine Logzeile beim Start: woher die Konfiguration kam, nie der Wert.
 * So laesst sich in den Logs belegen, welche Konfiguration ein Pod wirklich bekam.
 */
@Component
public class KonfigurationsBericht implements ApplicationRunner {
    private static final Logger LOG = LoggerFactory.getLogger(KonfigurationsBericht.class);
    private final String secretsDir;

    public KonfigurationsBericht(@Value("${SECRETS_DIR:/var/secrets}") String secretsDir) {
        this.secretsDir = secretsDir;
    }

    @Override
    public void run(ApplicationArguments args) {
        LOG.info("Konfiguration: GREETING {}, DB_PASSWORT {}", greetingQuelle(), passwortQuelle());
    }

    String greetingQuelle() {
        return System.getenv("GREETING") != null ? "aus Umgebungsvariable (ConfigMap)" : "Standardwert";
    }

    String passwortQuelle() {
        if (Files.isRegularFile(Path.of(secretsDir, "DB_PASSWORT"))) {
            return "aus Datei " + secretsDir;
        }
        if (System.getenv("DB_PASSWORT") != null) {
            return "aus Umgebungsvariable (Kubernetes Secret)";
        }
        return "nicht gesetzt";
    }
}
