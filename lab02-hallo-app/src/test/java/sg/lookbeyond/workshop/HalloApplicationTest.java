package sg.lookbeyond.workshop;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;

import static org.hamcrest.Matchers.containsString;
import static org.hamcrest.Matchers.not;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.content;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest(properties = {"GREETING=Guten Tag", "APP_VERSION=2.0", "HOSTNAME=test-pod",
        "DB_PASSWORT=secret-must-never-be-returned"})
@AutoConfigureMockMvc
class HalloApplicationTest {
    @Autowired
    private MockMvc mvc;

    @Test
    void responseIdentifiesPodAndVersionWithoutLeakingSecret() throws Exception {
        mvc.perform(get("/"))
                .andExpect(status().isOk())
                .andExpect(content().string("Guten Tag von Pod test-pod, Version 2.0\n"))
                .andExpect(content().string(not(containsString("secret-must-never-be-returned"))));
    }

    @Test
    void actuatorExposesProbesWithoutConfigurationValues() throws Exception {
        mvc.perform(get("/actuator/health/liveness"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("UP"));
        mvc.perform(get("/actuator/health/readiness"))
                .andExpect(status().isOk()).andExpect(jsonPath("$.status").value("UP"));
        mvc.perform(get("/actuator/env")).andExpect(status().isNotFound());
    }

    @Test
    void exerciseErrorDoesNotMakeTheApplicationUnhealthy() throws Exception {
        mvc.perform(get("/fehler")).andExpect(status().isInternalServerError());
        mvc.perform(get("/actuator/health/liveness")).andExpect(status().isOk());
        mvc.perform(get("/")).andExpect(status().isOk());
    }
}
