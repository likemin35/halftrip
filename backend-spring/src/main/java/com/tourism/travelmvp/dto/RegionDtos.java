package com.tourism.travelmvp.dto;

import java.util.List;

public final class RegionDtos {

    private RegionDtos() {
    }

    public record RegionSummary(Long id,
                                String name,
                                String province,
                                Integer refundConditionAmount,
                                Integer mockBudgetRemaining,
                                String halfPriceApplyUrl,
                                String digitalTourCardApplyUrl,
                                String dataSourceNote,
                                String statusCode,
                                Boolean digitalBenefitAvailable,
                                Integer displayOrder,
                                Double mapTopPercent,
                                Double mapLeftPercent,
                                String residenceRestrictionNote,
                                boolean matchedByResidence) {
    }

    public record RegionDetail(RegionSummary region,
                               List<PlaceItem> halfPricePlaces,
                               List<DigitalPlaceItem> digitalTourCardPlaces,
                               List<MerchantItem> merchants,
                               List<OnlineMallItem> onlineMalls) {
    }

    public record PlaceItem(Long id,
                            String name,
                            String address,
                            String description,
                            Double latitude,
                            Double longitude,
                            Boolean eligibleForRefund) {
    }

    public record DigitalPlaceItem(Long id,
                                   String name,
                                   String address,
                                   String discountDescription,
                                   Double latitude,
                                   Double longitude) {
    }

    public record MerchantItem(Long id, String name, String address, String category) {
    }

    public record OnlineMallItem(Long id, String name, String mallUrl, String description) {
    }
}
