package test;

import com.fasterxml.jackson.databind.JsonNode;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.TestInfo;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.EnumSource;
import test.helm.Helm;
import test.model.Product;

import java.util.Map;

import static test.jackson.JsonNodeAssert.assertThat;

/**
 * Tests the various permutations of the "<product>.securityContext" and "<product>.containerSecurityContext" value structure in the Helm charts
 */
class SecurityContextTest {
    private Helm helm;

    @BeforeEach
    void initHelm(TestInfo testInfo) {
        helm = new Helm(testInfo);
    }

    @ParameterizedTest
    @EnumSource(value = Product.class)
    void test_pod_security_context(Product product) throws Exception {

        final var resources = helm.captureKubeResourcesFromHelmChart(product, Map.of(
                product + ".securityContext.fsGroup", "1000"));

        JsonNode podSpec = resources.getStatefulSet(product.getHelmReleaseName()).getPodSpec();
        assertThat(podSpec.path("securityContext").path("fsGroup")).hasValueEqualTo(1000);

    }

    @ParameterizedTest
    @EnumSource(value = Product.class)
    void test_container_security_context(Product product) throws Exception {

        final var resources = helm.captureKubeResourcesFromHelmChart(product, Map.of(
                product + ".containerSecurityContext.runAsGroup", "2000"));

        JsonNode containerSecurityContext = resources.getStatefulSet(product.getHelmReleaseName())
                .getContainer()
                .getSecurityContext();
        assertThat(containerSecurityContext.path("runAsGroup")).hasValueEqualTo(2000);
    }
}