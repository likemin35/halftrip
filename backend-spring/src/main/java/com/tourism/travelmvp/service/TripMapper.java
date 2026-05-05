package com.tourism.travelmvp.service;

import com.tourism.travelmvp.dto.RegionDtos;
import com.tourism.travelmvp.dto.TripDtos;
import com.tourism.travelmvp.entity.DigitalTourCardPlace;
import com.tourism.travelmvp.entity.LodgingInfo;
import com.tourism.travelmvp.entity.Merchant;
import com.tourism.travelmvp.entity.OnlineMall;
import com.tourism.travelmvp.entity.Place;
import com.tourism.travelmvp.entity.Region;
import com.tourism.travelmvp.entity.Receipt;
import com.tourism.travelmvp.entity.Trip;
import com.tourism.travelmvp.entity.TripPlace;
import com.tourism.travelmvp.entity.UploadedFile;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public final class TripMapper {

    private TripMapper() {
    }

    public static TripDtos.TripSummary toTripSummary(Trip trip, LocalDate today) {
        String status = trip.getSettlementApplied() ? "정산 신청 완료"
                : trip.getEndDate().isBefore(today) ? "정산 준비"
                : "여행중";
        return new TripDtos.TripSummary(
                trip.getId(),
                trip.getRegion().getId(),
                trip.getRegion().getName(),
                trip.getApplicantName(),
                trip.getStartDate(),
                trip.getEndDate(),
                trip.getTravelerCount(),
                status,
                trip.getTotalSpentAmount(),
                trip.getRefundConditionAmount(),
                trip.getSettlementApplied());
    }

    public static TripDtos.TripPlaceItem toTripPlaceItem(TripPlace item) {
        return new TripDtos.TripPlaceItem(
                item.getId(),
                item.getPlaceType(),
                item.getReferencePlaceId(),
                item.getPlaceName(),
                item.getAddress(),
                item.getVisitOrder(),
                item.getLatitude(),
                item.getLongitude(),
                item.getChecked());
    }

    public static TripDtos.UploadedFileItem toUploadedFileItem(UploadedFile file) {
        return new TripDtos.UploadedFileItem(
                file.getId(),
                file.getFileCategory(),
                file.getOriginalFileName(),
                file.getStoragePath(),
                file.getFileSize(),
                file.getMimeType(),
                file.getCreatedAt());
    }

    public static TripDtos.ReceiptItem toReceiptItem(Receipt receipt) {
        return new TripDtos.ReceiptItem(
                receipt.getId(),
                receipt.getUploadedFile().getId(),
                receipt.getPaymentType(),
                receipt.getUsageScope(),
                receipt.getReviewStatus(),
                receipt.getAmount(),
                receipt.getEligibleAmount(),
                receipt.getReviewReason(),
                receipt.getRawText());
    }

    public static TripDtos.LodgingInfoItem toLodgingInfoItem(LodgingInfo info) {
        return new TripDtos.LodgingInfoItem(
                info.getId(),
                info.getLodgingName(),
                info.getRepresentativeName(),
                info.getPhoneNumber(),
                info.getAddress(),
                info.getSignatureSvgPath(),
                info.getAgreedPersonalInfo(),
                info.getAgreedStayProof(),
                info.getUploadedFile() == null ? null : info.getUploadedFile().getId());
    }

    public static RegionDtos.RegionSummary toRegionSummary(Region region, boolean matchedByResidence) {
        return new RegionDtos.RegionSummary(
                region.getId(),
                region.getName(),
                region.getProvince(),
                region.getRefundConditionAmount(),
                region.getMockBudgetRemaining(),
                region.getHalfPriceApplyUrl(),
                region.getDigitalTourCardApplyUrl(),
                region.getDataSourceNote(),
                region.getStatusCode(),
                region.getDigitalBenefitAvailable(),
                region.getDisplayOrder(),
                region.getMapTopPercent(),
                region.getMapLeftPercent(),
                region.getResidenceRestrictionNote(),
                matchedByResidence);
    }

    public static RegionDtos.PlaceItem toPlaceItem(Place place) {
        return new RegionDtos.PlaceItem(
                place.getId(),
                place.getName(),
                place.getAddress(),
                place.getDescription(),
                place.getLatitude(),
                place.getLongitude(),
                place.getEligibleForRefund());
    }

    public static RegionDtos.DigitalPlaceItem toDigitalPlaceItem(DigitalTourCardPlace place) {
        return new RegionDtos.DigitalPlaceItem(
                place.getId(),
                place.getName(),
                place.getAddress(),
                place.getDiscountDescription(),
                place.getLatitude(),
                place.getLongitude());
    }

    public static RegionDtos.MerchantItem toMerchantItem(Merchant merchant) {
        return new RegionDtos.MerchantItem(merchant.getId(), merchant.getName(), merchant.getAddress(), merchant.getCategory());
    }

    public static RegionDtos.OnlineMallItem toOnlineMallItem(OnlineMall mall) {
        return new RegionDtos.OnlineMallItem(mall.getId(), mall.getName(), mall.getMallUrl(), mall.getDescription());
    }

    @SuppressWarnings("unchecked")
    public static List<String> stringList(Object source) {
        if (source == null) {
            return Collections.emptyList();
        }
        List<Object> rawList = (List<Object>) source;
        List<String> result = new ArrayList<>();
        for (Object item : rawList) {
            result.add(String.valueOf(item));
        }
        return result;
    }

    public static String nullableString(Object source) {
        return source == null ? null : String.valueOf(source);
    }
}
