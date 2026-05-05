package com.tourism.travelmvp.config;

import java.nio.file.Files;
import java.nio.file.Path;
import lombok.RequiredArgsConstructor;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.jpa.repository.config.EnableJpaAuditing;
import org.springframework.web.reactive.function.client.WebClient;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableJpaAuditing
@RequiredArgsConstructor
@EnableConfigurationProperties(AppProperties.class)
public class AppConfig {

    private final AppProperties appProperties;

    @Bean
    WebClient fastApiWebClient() {
        return WebClient.builder()
                .baseUrl(appProperties.getFastapiBaseUrl())
                .build();
    }

    @Bean
    WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/api/**")
                        .allowedOriginPatterns(appProperties.getAllowedOrigins())
                        .allowedMethods("*")
                        .allowedHeaders("*");
            }
        };
    }

    @Bean
    Path storageRootPath() throws Exception {
        Path root = Path.of(appProperties.getStorageRoot()).toAbsolutePath().normalize();
        Files.createDirectories(root);
        return root;
    }
}

