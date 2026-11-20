package sg.lookbeyond.workshop;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HalloController {
    private static final Logger LOG = LoggerFactory.getLogger(HalloController.class);
    private final String greeting;
    private final String version;
    private final String hostname;

    public HalloController(@Value("${GREETING:Hallo}") String greeting,
                           @Value("${APP_VERSION:1.0}") String version,
                           @Value("${HOSTNAME:lokal}") String hostname) {
        this.greeting = greeting;
        this.version = version;
        this.hostname = hostname;
    }

    @GetMapping(value = "/", produces = MediaType.TEXT_PLAIN_VALUE)
    public String hallo() {
        return "%s von Pod %s, Version %s%n".formatted(greeting, hostname, version);
    }

    @GetMapping(value = "/fehler", produces = MediaType.TEXT_PLAIN_VALUE)
    public ResponseEntity<String> fehler() {
        LOG.error("FEHLER: Absichtlicher Workshop-Fehler, Pod {}, Version {}", hostname, version);
        return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                .body("Absichtlicher Workshop-Fehler. Die Anwendung laeuft weiter.\n");
    }
}
