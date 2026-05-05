package com.tourism.travelmvp.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;

@Getter
@Setter
@ConfigurationProperties(prefix = "app")
public class AppProperties {

    private String fastapiBaseUrl;
    private String allowedOrigins;
    private Boolean mockExternalData = Boolean.TRUE;
    private String storageRoot = "./uploads";
}

