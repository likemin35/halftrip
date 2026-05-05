package com.tourism.travelmvp.dto;

import com.tourism.travelmvp.enums.FileCategory;
import com.tourism.travelmvp.enums.PaymentType;
import com.tourism.travelmvp.enums.PlaceCategory;
import com.tourism.travelmvp.enums.ReceiptReviewStatus;
import com.tourism.travelmvp.enums.ReceiptUsageScope;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class TripDtos {

    private TripDtos() {
    }

    public record CreateTripRequest(Long userId,
                                    String applicantName,
                                    String phoneNumber,
                                    String residence,
                                    LocalDate startDate,
                                    LocalDate endDate,
                                    Integer travelerCount,
                                    Long regionId) {
    }

    public record UpdateTripRequest(String applicantName,
                                    String phoneNumber,
                                    String residence,
                                    LocalDate startDate,
                                    LocalDate endDate,
                                    Integer travelerCount,
                                    String status) {
    }

    public record TripSummary(Long id,
                              Long regionId,
                              String regionName,
                              String applicantName,
                              LocalDate startDate,
                              LocalDate endDate,
                              Integer travelerCount,
                              String status,
                              Integer totalSpentAmount,
                              Integer refundConditionAmount,
                              Boolean settlementApplied) {
    }

    public record TripDetail(TripSummary trip,
                             List<TripPlaceItem> selectedPlaces,
                             List<UploadedFileItem> uploadedFiles,
                             List<ReceiptItem> receipts,
                             LodgingInfoItem lodgingInfo,
                             SettlementSummary settlementSummary) {
    }

    public record AddTripPlaceRequest(PlaceCategory placeType,
                                      Long referencePlaceId,
                                      String placeName,
                                      String address,
                                      Double latitude,
                                      Double longitude) {
    }

    public record ReplaceTripPlacesRequest(List<AddTripPlaceRequest> places) {
    }

    public record ReorderTripPlacesRequest(List<Long> orderedTripPlaceIds) {
    }

    public record TripPlaceItem(Long id,
                                PlaceCategory placeType,
                                Long referencePlaceId,
                                String placeName,
                                String address,
                                Integer visitOrder,
                                Double latitude,
                                Double longitude,
                                Boolean checked) {
    }

    public record UploadedFileItem(Long id,
                                   FileCategory fileCategory,
                                   String originalFileName,
                                   String storagePath,
                                   Long fileSize,
                                   String mimeType,
                                   LocalDateTime createdAt) {
    }

    public record AnalyzeReceiptRequest(ReceiptUsageScope usageScope) {
    }

    public record ReceiptItem(Long id,
                              Long uploadedFileId,
                              PaymentType paymentType,
                              ReceiptUsageScope usageScope,
                              ReceiptReviewStatus reviewStatus,
                              Integer amount,
                              Integer eligibleAmount,
                              String reviewReason,
                              String rawText) {
    }

    public record LodgingInfoRequest(String lodgingName,
                                     String representativeName,
                                     String phoneNumber,
                                     String address,
                                     String signatureSvgPath,
                                     Boolean agreedPersonalInfo,
                                     Boolean agreedStayProof,
                                     Long uploadedFileId) {
    }

    public record LodgingInfoItem(Long id,
                                  String lodgingName,
                                  String representativeName,
                                  String phoneNumber,
                                  String address,
                                  String signatureSvgPath,
                                  Boolean agreedPersonalInfo,
                                  Boolean agreedStayProof,
                                  Long uploadedFileId) {
    }

    public record SettlementSummary(Integer totalSpentAmount,
                                    Integer refundConditionAmount,
                                    Integer remainingAmount,
                                    String statusMessage) {
    }

    public record SettlementApplyResponse(Long tripId, String status, LocalDateTime settlementAppliedAt) {
    }

    public record LodgingFormFieldItem(String key,
                                       String label,
                                       String type,
                                       Double x,
                                       Double y,
                                       Double width,
                                       Double height,
                                       Boolean editable,
                                       Boolean multiline,
                                       String helperText) {
    }

    public record LodgingFormTemplateItem(Long templateId,
                                          String templateKey,
                                          String templateName,
                                          String sourceFormat,
                                          String previewTitle,
                                          String previewSubtitle,
                                          List<LodgingFormFieldItem> fields,
                                          List<String> notes) {
    }

    public record LodgingFormInstanceItem(Long instanceId,
                                          String status,
                                          Map<String, Object> payload,
                                          LocalDateTime lastSavedAt,
                                          String renderedPdfFileName) {
    }

    public record LodgingFormData(Long tripId,
                                  String regionName,
                                  LodgingFormTemplateItem template,
                                  LodgingFormInstanceItem instance,
                                  List<String> todos) {
    }

    public record SaveLodgingFormRequest(Map<String, Object> payload, String status) {
    }

    public record SaveLodgingFormTemplateLayoutRequest(List<LodgingFormFieldItem> fields) {
    }
}
