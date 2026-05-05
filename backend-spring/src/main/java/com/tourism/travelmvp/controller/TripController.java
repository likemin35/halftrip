package com.tourism.travelmvp.controller;

import com.tourism.travelmvp.dto.ApiResponse;
import com.tourism.travelmvp.dto.TripDtos;
import com.tourism.travelmvp.enums.FileCategory;
import com.tourism.travelmvp.service.TripService;
import java.io.IOException;
import java.time.LocalDate;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestPart;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api")
@RequiredArgsConstructor
public class TripController {

    private final TripService tripService;

    @PostMapping("/trips")
    public ApiResponse<TripDtos.TripSummary> createTrip(@RequestBody TripDtos.CreateTripRequest request) {
        return ApiResponse.ok(tripService.createTrip(request));
    }

    @GetMapping("/trips")
    public ApiResponse<List<TripDtos.TripSummary>> getTrips(@RequestParam Long userId) {
        return ApiResponse.ok(tripService.getTrips(userId));
    }

    @GetMapping("/trips/{tripId}")
    public ApiResponse<TripDtos.TripDetail> getTrip(@PathVariable Long tripId) {
        return ApiResponse.ok(tripService.getTripDetail(tripId));
    }

    @PutMapping("/trips/{tripId}")
    public ApiResponse<TripDtos.TripSummary> updateTrip(
            @PathVariable Long tripId,
            @RequestBody TripDtos.UpdateTripRequest request
    ) {
        return ApiResponse.ok(tripService.updateTrip(tripId, request));
    }

    @PostMapping("/trips/{tripId}/places")
    public ApiResponse<List<TripDtos.TripPlaceItem>> addTripPlace(
            @PathVariable Long tripId,
            @RequestBody TripDtos.AddTripPlaceRequest request
    ) {
        return ApiResponse.ok(tripService.addTripPlace(tripId, request));
    }

    @PutMapping("/trips/{tripId}/places")
    public ApiResponse<List<TripDtos.TripPlaceItem>> replaceTripPlaces(
            @PathVariable Long tripId,
            @RequestBody TripDtos.ReplaceTripPlacesRequest request
    ) {
        return ApiResponse.ok(tripService.replaceTripPlaces(tripId, request));
    }

    @PostMapping("/trips/{tripId}/places/reorder")
    public ApiResponse<List<TripDtos.TripPlaceItem>> reorderTripPlaces(
            @PathVariable Long tripId,
            @RequestBody TripDtos.ReorderTripPlacesRequest request
    ) {
        return ApiResponse.ok(tripService.reorderTripPlaces(tripId, request));
    }

    @PostMapping("/trips/{tripId}/uploaded-files")
    public ApiResponse<TripDtos.UploadedFileItem> uploadFile(
            @PathVariable Long tripId,
            @RequestParam FileCategory category,
            @RequestPart MultipartFile file
    ) throws IOException {
        return ApiResponse.ok(tripService.uploadFile(tripId, category, file));
    }

    @GetMapping("/trips/{tripId}/uploaded-files/{uploadedFileId}/binary")
    public ResponseEntity<ByteArrayResource> downloadUploadedFile(
            @PathVariable Long tripId,
            @PathVariable Long uploadedFileId
    ) throws IOException {
        return tripService.downloadUploadedFile(tripId, uploadedFileId);
    }

    @DeleteMapping("/trips/{tripId}/uploaded-files/{uploadedFileId}")
    public ApiResponse<Void> deleteUploadedFile(
            @PathVariable Long tripId,
            @PathVariable Long uploadedFileId
    ) throws IOException {
        tripService.deleteUploadedFile(tripId, uploadedFileId);
        return ApiResponse.ok(null);
    }

    @PostMapping("/trips/{tripId}/receipts/analyze/{uploadedFileId}")
    public ApiResponse<TripDtos.ReceiptItem> analyzeReceipt(
            @PathVariable Long tripId,
            @PathVariable Long uploadedFileId,
            @RequestBody(required = false) TripDtos.AnalyzeReceiptRequest request
    ) {
        return ApiResponse.ok(tripService.analyzeReceipt(tripId, uploadedFileId, request));
    }

    @PostMapping("/trips/{tripId}/lodging-info")
    public ApiResponse<TripDtos.LodgingInfoItem> upsertLodgingInfo(
            @PathVariable Long tripId,
            @RequestBody TripDtos.LodgingInfoRequest request
    ) {
        return ApiResponse.ok(tripService.upsertLodgingInfo(tripId, request));
    }

    @PostMapping("/trips/{tripId}/lodging-info/extract/{uploadedFileId}")
    public ApiResponse<TripDtos.LodgingInfoItem> extractLodgingInfo(
            @PathVariable Long tripId,
            @PathVariable Long uploadedFileId
    ) {
        return ApiResponse.ok(tripService.extractLodgingInfo(tripId, uploadedFileId));
    }

    @PutMapping("/trips/{tripId}/lodging-form")
    public ApiResponse<TripDtos.LodgingFormData> saveLodgingForm(
            @PathVariable Long tripId,
            @RequestBody TripDtos.SaveLodgingFormRequest request
    ) {
        return ApiResponse.ok(tripService.saveLodgingForm(tripId, request));
    }

    @GetMapping("/trips/{tripId}/settlement-summary")
    public ApiResponse<TripDtos.SettlementSummary> getSettlementSummary(@PathVariable Long tripId) {
        return ApiResponse.ok(tripService.getSettlementSummary(tripId));
    }

    @PostMapping("/trips/{tripId}/settlement-apply")
    public ApiResponse<TripDtos.SettlementApplyResponse> applySettlement(@PathVariable Long tripId) {
        return ApiResponse.ok(tripService.applySettlement(tripId));
    }

    @GetMapping("/trips/settlement-reminder-targets")
    public ApiResponse<List<TripDtos.TripSummary>> getSettlementReminderTargets(@RequestParam LocalDate date) {
        return ApiResponse.ok(tripService.getSettlementReminderTargets(date));
    }

    @GetMapping("/integrations/lodging-form/{tripId}")
    public ApiResponse<TripDtos.LodgingFormData> getLodgingFormData(@PathVariable Long tripId) {
        return ApiResponse.ok(tripService.getLodgingFormData(tripId));
    }

    @PutMapping("/integrations/lodging-form/{tripId}/template-layout")
    public ApiResponse<TripDtos.LodgingFormData> saveLodgingTemplateLayout(
            @PathVariable Long tripId,
            @RequestBody TripDtos.SaveLodgingFormTemplateLayoutRequest request
    ) {
        return ApiResponse.ok(tripService.saveLodgingTemplateLayout(tripId, request));
    }

    @PostMapping("/integrations/lodging-form/{tripId}/analyze-template")
    public ApiResponse<TripDtos.LodgingFormData> analyzeLodgingTemplate(@PathVariable Long tripId) throws IOException {
        return ApiResponse.ok(tripService.analyzeLodgingTemplate(tripId));
    }

    @GetMapping("/integrations/lodging-form/{tripId}/pdf")
    public ResponseEntity<ByteArrayResource> downloadLodgingFormPdf(@PathVariable Long tripId) throws IOException {
        return tripService.downloadLodgingFormPdf(tripId);
    }

    @GetMapping("/integrations/lodging-form/{tripId}/template-pdf")
    public ResponseEntity<ByteArrayResource> downloadLodgingTemplatePdf(@PathVariable Long tripId) throws IOException {
        return tripService.downloadLodgingTemplatePdf(tripId);
    }

    @GetMapping("/integrations/pdf/merge/{tripId}")
    public ResponseEntity<ByteArrayResource> mergePdf(
            @PathVariable Long tripId,
            @RequestParam List<Long> uploadedFileIds
    ) throws IOException {
        return tripService.mergeFilesAsPdf(tripId, uploadedFileIds);
    }
}
