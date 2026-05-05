package com.tourism.travelmvp.dto;

import com.tourism.travelmvp.enums.PaymentType;
import java.util.List;
import java.util.Map;

public final class IntegrationDtos {

    private IntegrationDtos() {
    }

    public record ReceiptOcrResponse(PaymentType paymentType, String rawText, List<String> candidates) {
    }

    public record ReceiptAmountResponse(Integer amount, String currency, String rawText) {
    }

    public record LodgingExtractResponse(String lodgingName,
                                         String representativeName,
                                         String phoneNumber,
                                         String address,
                                         List<String> warnings) {
    }

    public record LodgingFormDataResponse(String templateName, Object payload, List<String> todos) {
    }

    public record TemplateAnalysisField(
            String key,
            String type,
            Double x,
            Double y,
            Double width,
            Double height,
            Boolean editable,
            Boolean multiline
    ) {
        public Map<String, Object> toSchemaMap() {
            return Map.of(
                    "key", key,
                    "type", type,
                    "x", x,
                    "y", y,
                    "width", width,
                    "height", height,
                    "editable", editable,
                    "multiline", multiline
            );
        }
    }

    public record TemplateAnalysisResponse(
            List<TemplateAnalysisField> fields,
            List<String> warnings,
            boolean usedAi
    ) {
    }
}
