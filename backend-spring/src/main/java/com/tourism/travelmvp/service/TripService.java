package com.tourism.travelmvp.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.tourism.travelmvp.client.FastApiClient;
import com.tourism.travelmvp.dto.IntegrationDtos;
import com.tourism.travelmvp.dto.TripDtos;
import com.tourism.travelmvp.entity.LodgingFormInstance;
import com.tourism.travelmvp.entity.LodgingFormTemplate;
import com.tourism.travelmvp.entity.LodgingInfo;
import com.tourism.travelmvp.entity.Region;
import com.tourism.travelmvp.entity.Receipt;
import com.tourism.travelmvp.entity.Trip;
import com.tourism.travelmvp.entity.TripPlace;
import com.tourism.travelmvp.entity.UploadedFile;
import com.tourism.travelmvp.entity.User;
import com.tourism.travelmvp.enums.FileCategory;
import com.tourism.travelmvp.enums.PaymentType;
import com.tourism.travelmvp.enums.ReceiptReviewStatus;
import com.tourism.travelmvp.enums.ReceiptUsageScope;
import com.tourism.travelmvp.enums.TripStatus;
import com.tourism.travelmvp.exception.NotFoundException;
import com.tourism.travelmvp.repository.LodgingFormInstanceRepository;
import com.tourism.travelmvp.repository.LodgingFormTemplateRepository;
import com.tourism.travelmvp.repository.LodgingInfoRepository;
import com.tourism.travelmvp.repository.ReceiptRepository;
import com.tourism.travelmvp.repository.RegionRepository;
import com.tourism.travelmvp.repository.TripPlaceRepository;
import com.tourism.travelmvp.repository.TripRepository;
import com.tourism.travelmvp.repository.UploadedFileRepository;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.core.io.Resource;
import org.springframework.core.io.ResourceLoader;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class TripService {

    private static final String TEMPLATE_SCHEMA_RESOURCE_PREFIX = "classpath:lodging-form-templates/";
    private static final TypeReference<List<Map<String, Object>>> FIELD_SCHEMA_TYPE = new TypeReference<>() {
    };
    private static final TypeReference<Map<String, Object>> PAYLOAD_TYPE = new TypeReference<>() {
    };

    private final TripRepository tripRepository;
    private final TripPlaceRepository tripPlaceRepository;
    private final UploadedFileRepository uploadedFileRepository;
    private final ReceiptRepository receiptRepository;
    private final LodgingInfoRepository lodgingInfoRepository;
    private final LodgingFormTemplateRepository lodgingFormTemplateRepository;
    private final LodgingFormInstanceRepository lodgingFormInstanceRepository;
    private final RegionRepository regionRepository;
    private final UserService userService;
    private final StorageService storageService;
    private final FastApiClient fastApiClient;
    private final ObjectMapper objectMapper;
    private final ResourceLoader resourceLoader;

    @Transactional
    public TripDtos.TripSummary createTrip(TripDtos.CreateTripRequest request) {
        User user = userService.findUser(request.userId());
        Region region = regionRepository.findById(request.regionId())
                .orElseThrow(() -> new NotFoundException("Region not found"));
        Trip trip = new Trip();
        trip.setUser(user);
        trip.setRegion(region);
        trip.setApplicantName(request.applicantName());
        trip.setPhoneNumber(request.phoneNumber());
        trip.setResidence(request.residence());
        trip.setStartDate(request.startDate());
        trip.setEndDate(request.endDate());
        trip.setTravelerCount(request.travelerCount() == null || request.travelerCount() < 1 ? 1 : request.travelerCount());
        trip.setStatus(TripStatus.TRAVELING);
        trip.setRefundConditionAmount(region.getRefundConditionAmount());
        trip = tripRepository.save(trip);
        return TripMapper.toTripSummary(trip, LocalDate.now());
    }

    @Transactional(readOnly = true)
    public List<TripDtos.TripSummary> getTrips(Long userId) {
        return tripRepository.findByUserIdOrderByStartDateDesc(userId).stream()
                .map(trip -> TripMapper.toTripSummary(trip, LocalDate.now()))
                .toList();
    }

    @Transactional(readOnly = true)
    public TripDtos.TripDetail getTripDetail(Long tripId) {
        Trip trip = findTrip(tripId);
        List<TripDtos.TripPlaceItem> places = tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId).stream()
                .map(TripMapper::toTripPlaceItem)
                .toList();
        List<TripDtos.UploadedFileItem> uploadedFiles = uploadedFileRepository.findByTripIdOrderByCreatedAtAsc(tripId).stream()
                .map(TripMapper::toUploadedFileItem)
                .toList();
        List<TripDtos.ReceiptItem> receipts = receiptRepository.findByUploadedFileTripIdOrderByCreatedAtAsc(tripId).stream()
                .map(TripMapper::toReceiptItem)
                .toList();
        TripDtos.LodgingInfoItem lodgingInfo = lodgingInfoRepository.findByTripId(tripId)
                .map(TripMapper::toLodgingInfoItem)
                .orElse(null);
        return new TripDtos.TripDetail(
                TripMapper.toTripSummary(trip, LocalDate.now()),
                places,
                uploadedFiles,
                receipts,
                lodgingInfo,
                buildSettlementSummary(trip));
    }

    @Transactional
    public List<TripDtos.TripPlaceItem> addTripPlace(Long tripId, TripDtos.AddTripPlaceRequest request) {
        Trip trip = findTrip(tripId);
        int nextOrder = tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId).size() + 1;
        TripPlace tripPlace = new TripPlace();
        tripPlace.setTrip(trip);
        tripPlace.setPlaceType(request.placeType());
        tripPlace.setReferencePlaceId(request.referencePlaceId());
        tripPlace.setPlaceName(request.placeName());
        tripPlace.setAddress(request.address());
        tripPlace.setLatitude(request.latitude());
        tripPlace.setLongitude(request.longitude());
        tripPlace.setVisitOrder(nextOrder);
        tripPlaceRepository.save(tripPlace);
        return tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId).stream()
                .map(TripMapper::toTripPlaceItem)
                .toList();
    }

    @Transactional
    public List<TripDtos.TripPlaceItem> replaceTripPlaces(Long tripId, TripDtos.ReplaceTripPlacesRequest request) {
        Trip trip = findTrip(tripId);
        List<TripPlace> existing = tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId);
        tripPlaceRepository.deleteAll(existing);

        int order = 1;
        List<TripPlace> replacements = new ArrayList<>();
        for (TripDtos.AddTripPlaceRequest placeRequest : request.places()) {
            TripPlace tripPlace = new TripPlace();
            tripPlace.setTrip(trip);
            tripPlace.setPlaceType(placeRequest.placeType());
            tripPlace.setReferencePlaceId(placeRequest.referencePlaceId());
            tripPlace.setPlaceName(placeRequest.placeName());
            tripPlace.setAddress(placeRequest.address());
            tripPlace.setLatitude(placeRequest.latitude());
            tripPlace.setLongitude(placeRequest.longitude());
            tripPlace.setVisitOrder(order++);
            replacements.add(tripPlace);
        }
        tripPlaceRepository.saveAll(replacements);
        return tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId).stream()
                .map(TripMapper::toTripPlaceItem)
                .toList();
    }

    @Transactional
    public List<TripDtos.TripPlaceItem> reorderTripPlaces(Long tripId, TripDtos.ReorderTripPlacesRequest request) {
        Trip trip = findTrip(tripId);
        List<TripPlace> places = tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId);
        Map<Long, TripPlace> byId = new LinkedHashMap<>();
        for (TripPlace place : places) {
            byId.put(place.getId(), place);
        }
        int index = 1;
        for (Long id : request.orderedTripPlaceIds()) {
            TripPlace place = byId.get(id);
            if (place != null && place.getTrip().getId().equals(trip.getId())) {
                place.setVisitOrder(index++);
            }
        }
        tripPlaceRepository.saveAll(places);
        return tripPlaceRepository.findByTripIdOrderByVisitOrderAsc(tripId).stream()
                .map(TripMapper::toTripPlaceItem)
                .toList();
    }

    @Transactional
    public TripDtos.UploadedFileItem uploadFile(Long tripId, FileCategory category, MultipartFile file) throws IOException {
        Trip trip = findTrip(tripId);
        UploadedFile uploadedFile = storageService.storeTripFile(trip, category, file);
        return TripMapper.toUploadedFileItem(uploadedFile);
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ByteArrayResource> downloadUploadedFile(Long tripId, Long uploadedFileId) throws IOException {
        UploadedFile uploadedFile = findUploadedFile(uploadedFileId);
        if (!uploadedFile.getTrip().getId().equals(tripId)) {
            throw new NotFoundException("Uploaded file does not belong to the trip");
        }
        byte[] fileBytes = storageService.readBytes(uploadedFile);
        return toFileResponse(fileBytes, uploadedFile.getOriginalFileName(), uploadedFile.getMimeType(), true);
    }

    @Transactional
    public void deleteUploadedFile(Long tripId, Long uploadedFileId) throws IOException {
        UploadedFile uploadedFile = findUploadedFile(uploadedFileId);
        if (!uploadedFile.getTrip().getId().equals(tripId)) {
            throw new NotFoundException("Uploaded file does not belong to the trip");
        }

        receiptRepository.findByUploadedFileId(uploadedFileId).ifPresent(receiptRepository::delete);
        lodgingInfoRepository.findByTripId(tripId).ifPresent(lodgingInfo -> {
            if (lodgingInfo.getUploadedFile() != null
                    && uploadedFileId.equals(lodgingInfo.getUploadedFile().getId())) {
                lodgingInfo.setUploadedFile(null);
                lodgingInfoRepository.save(lodgingInfo);
            }
        });

        storageService.deleteStoredFile(uploadedFile);
        uploadedFileRepository.delete(uploadedFile);
        recalculateTripSpentAmount(uploadedFile.getTrip());
    }

    @Transactional
    public TripDtos.ReceiptItem analyzeReceipt(
            Long tripId,
            Long uploadedFileId,
            TripDtos.AnalyzeReceiptRequest request
    ) {
        UploadedFile uploadedFile = findUploadedFile(uploadedFileId);
        if (!uploadedFile.getTrip().getId().equals(tripId)) {
            throw new NotFoundException("Uploaded file does not belong to the trip");
        }
        Trip trip = uploadedFile.getTrip();
        Path filePath = storageService.resolvePath(uploadedFile);
        IntegrationDtos.ReceiptOcrResponse ocrResponse = fastApiClient.analyzeReceipt(filePath);
        IntegrationDtos.ReceiptAmountResponse amountResponse = fastApiClient.extractReceiptAmount(filePath);
        PaymentType paymentType = ocrResponse.paymentType() == null ? PaymentType.UNKNOWN : ocrResponse.paymentType();
        String rawText = amountResponse.rawText() == null || amountResponse.rawText().isBlank()
                ? ocrResponse.rawText()
                : amountResponse.rawText();
        ReceiptUsageScope usageScope = resolveReceiptUsageScope(request, uploadedFile.getOriginalFileName(), rawText);
        ReceiptReviewOutcome reviewOutcome = reviewReceipt(
                trip,
                usageScope,
                paymentType,
                amountResponse.amount(),
                rawText,
                uploadedFile.getOriginalFileName()
        );

        Receipt receipt = receiptRepository.findByUploadedFileId(uploadedFileId).orElseGet(Receipt::new);
        receipt.setUploadedFile(uploadedFile);
        receipt.setPaymentType(paymentType);
        receipt.setUsageScope(usageScope);
        receipt.setReviewStatus(reviewOutcome.reviewStatus());
        receipt.setAmount(amountResponse.amount());
        receipt.setEligibleAmount(reviewOutcome.eligibleAmount());
        receipt.setReviewReason(reviewOutcome.reviewReason());
        receipt.setRawText(rawText);
        receipt = receiptRepository.save(receipt);
        recalculateTripSpentAmount(trip);
        return TripMapper.toReceiptItem(receipt);
    }

    @Transactional
    public TripDtos.LodgingInfoItem upsertLodgingInfo(Long tripId, TripDtos.LodgingInfoRequest request) {
        Trip trip = findTrip(tripId);
        LodgingInfo lodgingInfo = lodgingInfoRepository.findByTripId(tripId).orElseGet(LodgingInfo::new);
        lodgingInfo.setTrip(trip);
        lodgingInfo.setLodgingName(request.lodgingName());
        lodgingInfo.setRepresentativeName(request.representativeName());
        lodgingInfo.setPhoneNumber(request.phoneNumber());
        lodgingInfo.setAddress(request.address());
        lodgingInfo.setSignatureSvgPath(request.signatureSvgPath());
        lodgingInfo.setAgreedPersonalInfo(Boolean.TRUE.equals(request.agreedPersonalInfo()));
        lodgingInfo.setAgreedStayProof(Boolean.TRUE.equals(request.agreedStayProof()));
        if (request.uploadedFileId() != null) {
            lodgingInfo.setUploadedFile(findUploadedFile(request.uploadedFileId()));
        }
        lodgingInfo = lodgingInfoRepository.save(lodgingInfo);
        return TripMapper.toLodgingInfoItem(lodgingInfo);
    }

    @Transactional
    public TripDtos.LodgingInfoItem extractLodgingInfo(Long tripId, Long uploadedFileId) {
        Trip trip = findTrip(tripId);
        UploadedFile uploadedFile = findUploadedFile(uploadedFileId);
        if (!uploadedFile.getTrip().getId().equals(trip.getId())) {
            throw new NotFoundException("Uploaded file does not belong to the trip");
        }
        IntegrationDtos.LodgingExtractResponse response = fastApiClient.extractLodgingInfo(storageService.resolvePath(uploadedFile));
        TripDtos.LodgingInfoRequest request = new TripDtos.LodgingInfoRequest(
                response.lodgingName(),
                response.representativeName(),
                response.phoneNumber(),
                response.address(),
                null,
                Boolean.FALSE,
                Boolean.FALSE,
                uploadedFileId);
        return upsertLodgingInfo(tripId, request);
    }

    @Transactional(readOnly = true)
    public TripDtos.SettlementSummary getSettlementSummary(Long tripId) {
        return buildSettlementSummary(findTrip(tripId));
    }

    @Transactional
    public TripDtos.SettlementApplyResponse applySettlement(Long tripId) {
        Trip trip = findTrip(tripId);
        trip.setSettlementApplied(Boolean.TRUE);
        trip.setSettlementAppliedAt(LocalDateTime.now());
        trip.setStatus(TripStatus.SETTLEMENT_COMPLETED);
        tripRepository.save(trip);
        return new TripDtos.SettlementApplyResponse(trip.getId(), "정산 신청 완료", trip.getSettlementAppliedAt());
    }

    @Transactional(readOnly = true)
    public List<TripDtos.TripSummary> getSettlementReminderTargets(LocalDate date) {
        return tripRepository.findByEndDateLessThanEqualAndSettlementAppliedFalse(date).stream()
                .map(trip -> TripMapper.toTripSummary(trip, date))
                .toList();
    }

    @Transactional(readOnly = true)
    public TripDtos.LodgingFormData getLodgingFormData(Long tripId) {
        Trip trip = findTrip(tripId);
        LodgingFormTemplate template = findActiveTemplate(trip.getRegion().getId());
        LodgingFormInstance instance = lodgingFormInstanceRepository.findByTripId(tripId).orElse(null);
        LodgingInfo lodgingInfo = lodgingInfoRepository.findByTripId(tripId).orElse(null);

        List<TripDtos.LodgingFormFieldItem> fields = buildFieldItems(template);
        Map<String, Object> payload = normalizeLodgingFormPayload(
                fields,
                mergePayloads(buildBasePayload(trip, lodgingInfo), instance == null ? null : parsePayload(instance.getPayloadJson())),
                trip,
                lodgingInfo);

        TripDtos.LodgingFormTemplateItem templateItem = new TripDtos.LodgingFormTemplateItem(
                template.getId(),
                template.getTemplateKey(),
                template.getTemplateName(),
                template.getSourceFormat(),
                template.getPreviewTitle(),
                template.getPreviewSubtitle(),
                fields,
                buildTemplateNotes(template));

        TripDtos.LodgingFormInstanceItem instanceItem = new TripDtos.LodgingFormInstanceItem(
                instance == null ? null : instance.getId(),
                instance == null ? "DRAFT" : instance.getStatus(),
                payload,
                instance == null ? null : instance.getUpdatedAt(),
                instance == null ? null : instance.getRenderedPdfFileName());

        return new TripDtos.LodgingFormData(
                trip.getId(),
                trip.getRegion().getName(),
                templateItem,
                instanceItem,
                List.of(
                        "실제 지역별 HWP/PDF 원본이 도착하면 동일 키 구조로 템플릿만 교체할 수 있습니다.",
                        "현재는 공통 배치 템플릿을 사용하며 전자서명과 체크 상태를 저장합니다."));
    }

    @Transactional
    public TripDtos.LodgingFormData saveLodgingForm(Long tripId, TripDtos.SaveLodgingFormRequest request) {
        Trip trip = findTrip(tripId);
        LodgingFormTemplate template = findActiveTemplate(trip.getRegion().getId());
        LodgingFormInstance instance = lodgingFormInstanceRepository.findByTripId(tripId).orElseGet(LodgingFormInstance::new);
        LodgingInfo lodgingInfo = lodgingInfoRepository.findByTripId(tripId).orElse(null);
        List<TripDtos.LodgingFormFieldItem> fields = buildFieldItems(template);
        Map<String, Object> payload = normalizeLodgingFormPayload(
                fields,
                mergePayloads(buildBasePayload(trip, lodgingInfo), request.payload()),
                trip,
                lodgingInfo);

        instance.setTrip(trip);
        instance.setTemplate(template);
        instance.setTemplateSnapshotJson(resolveTemplateSchemaJson(template));
        instance.setPayloadJson(writeJson(payload));
        instance.setStatus(request.status() == null || request.status().isBlank() ? "DRAFT" : request.status());
        lodgingFormInstanceRepository.save(instance);

        syncLodgingInfoFromPayload(trip, payload);
        return getLodgingFormData(tripId);
    }

    @Transactional
    public TripDtos.LodgingFormData saveLodgingTemplateLayout(
            Long tripId,
            TripDtos.SaveLodgingFormTemplateLayoutRequest request
    ) {
        Trip trip = findTrip(tripId);
        LodgingFormTemplate template = findActiveTemplate(trip.getRegion().getId());
        List<Map<String, Object>> schema = new ArrayList<>();
        for (TripDtos.LodgingFormFieldItem field : request.fields()) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("key", field.key());
            item.put("label", field.label());
            item.put("type", field.type());
            item.put("x", field.x());
            item.put("y", field.y());
            item.put("width", field.width());
            item.put("height", field.height());
            item.put("editable", field.editable());
            item.put("multiline", field.multiline());
            item.put("helperText", field.helperText());
            schema.add(item);
        }
        template.setTemplateSchemaJson(writeJson(schema));
        template.setDataSourceNote("DB_LAYOUT");
        lodgingFormTemplateRepository.save(template);
        return getLodgingFormData(tripId);
    }

    @Transactional
    public ResponseEntity<ByteArrayResource> downloadLodgingFormPdf(Long tripId) throws IOException {
        byte[] pdfBytes = renderLodgingFormPdfBytes(tripId);
        Trip trip = findTrip(tripId);
        lodgingFormInstanceRepository.findByTripId(tripId).ifPresent(instance -> {
            instance.setRenderedPdfFileName("trip-" + tripId + "-lodging-form.pdf");
            instance.setLastRenderedAt(LocalDateTime.now());
            lodgingFormInstanceRepository.save(instance);
        });
        return toPdfResponse(pdfBytes, "trip-" + trip.getId() + "-lodging-form.pdf");
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ByteArrayResource> downloadLodgingTemplatePdf(Long tripId) throws IOException {
        Trip trip = findTrip(tripId);
        LodgingFormTemplate template = findActiveTemplate(trip.getRegion().getId());
        Path templatePath = resolveTemplatePdfPath(template);
        byte[] pdfBytes = Files.readAllBytes(templatePath);
        return toPdfResponse(pdfBytes, template.getTemplateName(), true);
    }

    @Transactional
    public TripDtos.LodgingFormData analyzeLodgingTemplate(Long tripId) throws IOException {
        Trip trip = findTrip(tripId);
        LodgingFormTemplate template = findActiveTemplate(trip.getRegion().getId());
        List<TripDtos.LodgingFormFieldItem> currentFields = buildFieldItems(template);

        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("template_name", template.getTemplateName());
        requestBody.put("region_name", trip.getRegion().getName());
        requestBody.put("render_asset_path", template.getRenderAssetPath());
        requestBody.put("current_fields", currentFields);

        IntegrationDtos.TemplateAnalysisResponse response = fastApiClient.analyzeLodgingTemplate(requestBody);
        if (!response.fields().isEmpty()) {
            List<Map<String, Object>> analyzedSchema = response.fields().stream()
                    .map(IntegrationDtos.TemplateAnalysisField::toSchemaMap)
                    .toList();
            template.setTemplateSchemaJson(writeJson(analyzedSchema));
            template.setDataSourceNote(response.usedAi() ? "AI_ANALYZED_TEMPLATE" : "HEURISTIC_ANALYZED_TEMPLATE");
            if (response.usedAi()) {
                template.setPreviewSubtitle("원본 PDF 양식 연결됨: " + template.getTemplateName() + ". AI 좌표 보정이 적용되었습니다.");
            } else {
                template.setPreviewSubtitle(
                        "Heuristic mapping kept for " + template.getTemplateName()
                                + ". Download the result PDF and verify the field positions."
                );
            }
            lodgingFormTemplateRepository.save(template);
        }
        return getLodgingFormData(tripId);
    }

    @Transactional(readOnly = true)
    public ResponseEntity<ByteArrayResource> mergeFilesAsPdf(Long tripId, List<Long> uploadedFileIds) throws IOException {
        findTrip(tripId);
        List<Path> filePaths = new ArrayList<>();
        Path tempLodgingPdf = null;
        try {
            for (Long uploadedFileId : uploadedFileIds) {
                UploadedFile file = findUploadedFile(uploadedFileId);
                filePaths.add(storageService.resolvePath(file));
            }
            byte[] lodgingPdf = maybeRenderLodgingFormPdfBytes(tripId);
            if (lodgingPdf != null) {
                tempLodgingPdf = Files.createTempFile("lodging-form-", ".pdf");
                Files.write(tempLodgingPdf, lodgingPdf);
                filePaths.add(tempLodgingPdf);
            }
            byte[] pdfBytes = fastApiClient.mergePdfs(filePaths);
            return toPdfResponse(pdfBytes, "trip-" + tripId + "-documents.pdf");
        } finally {
            if (tempLodgingPdf != null) {
                Files.deleteIfExists(tempLodgingPdf);
            }
        }
    }

    @Transactional
    public TripDtos.TripSummary updateTrip(Long tripId, TripDtos.UpdateTripRequest request) {
        Trip trip = findTrip(tripId);
        trip.setApplicantName(request.applicantName());
        trip.setPhoneNumber(request.phoneNumber());
        trip.setResidence(request.residence());
        trip.setStartDate(request.startDate());
        trip.setEndDate(request.endDate());
        if (request.travelerCount() != null && request.travelerCount() > 0) {
            trip.setTravelerCount(request.travelerCount());
        }
        tripRepository.save(trip);
        return TripMapper.toTripSummary(trip, LocalDate.now());
    }

    public Trip findTrip(Long tripId) {
        return tripRepository.findById(tripId)
                .orElseThrow(() -> new NotFoundException("Trip not found"));
    }

    public UploadedFile findUploadedFile(Long uploadedFileId) {
        return uploadedFileRepository.findById(uploadedFileId)
                .orElseThrow(() -> new NotFoundException("Uploaded file not found"));
    }

    private TripDtos.SettlementSummary buildSettlementSummary(Trip trip) {
        int remaining = Math.max(trip.getRefundConditionAmount() - trip.getTotalSpentAmount(), 0);
        String statusMessage = "현재 %d원 소비 / 환급 조건 %d원까지 %d원 남음"
                .formatted(trip.getTotalSpentAmount(), trip.getRefundConditionAmount(), remaining);
        return new TripDtos.SettlementSummary(
                trip.getTotalSpentAmount(),
                trip.getRefundConditionAmount(),
                remaining,
                statusMessage);
    }

    private void recalculateTripSpentAmount(Trip trip) {
        int total = receiptRepository.findByUploadedFileTripIdOrderByCreatedAtAsc(trip.getId()).stream()
                .filter(receipt -> receipt.getReviewStatus() == ReceiptReviewStatus.APPROVED)
                .map(Receipt::getEligibleAmount)
                .filter(amount -> amount != null)
                .mapToInt(Integer::intValue)
                .sum();
        trip.setTotalSpentAmount(total);
        trip.setStatus(trip.getSettlementApplied() ? TripStatus.SETTLEMENT_COMPLETED
                : trip.getEndDate().isBefore(LocalDate.now()) ? TripStatus.SETTLEMENT_READY : TripStatus.TRAVELING);
        tripRepository.save(trip);
    }

    private ReceiptUsageScope resolveReceiptUsageScope(
            TripDtos.AnalyzeReceiptRequest request,
            String originalFileName,
            String rawText
    ) {
        if (request != null && request.usageScope() == ReceiptUsageScope.LODGING) {
            return request.usageScope();
        }
        String source = (originalFileName + " " + rawText).toLowerCase();
        if (source.contains("숙박")
                || source.contains("호텔")
                || source.contains("모텔")
                || source.contains("리조트")
                || source.contains("펜션")
                || source.contains("guesthouse")) {
            return ReceiptUsageScope.LODGING;
        }
        if (request != null && request.usageScope() != null) {
            return request.usageScope();
        }
        return ReceiptUsageScope.GENERAL;
    }

    private void maybeAutofillWandoLodgingInfoFromReceipt(
            Trip trip,
            UploadedFile uploadedFile,
            ReceiptUsageScope usageScope
    ) {
        if (!isWandoRegion(trip.getRegion()) || usageScope != ReceiptUsageScope.LODGING) {
            return;
        }

        IntegrationDtos.LodgingExtractResponse response =
                fastApiClient.extractLodgingInfo(storageService.resolvePath(uploadedFile));
        boolean hasExtractedValue =
                !nullSafe(response.lodgingName()).isBlank()
                        || !nullSafe(response.address()).isBlank()
                        || !nullSafe(response.representativeName()).isBlank()
                        || !nullSafe(response.phoneNumber()).isBlank();
        if (!hasExtractedValue) {
            return;
        }

        LodgingInfo lodgingInfo = lodgingInfoRepository.findByTripId(trip.getId()).orElseGet(LodgingInfo::new);
        lodgingInfo.setTrip(trip);
        lodgingInfo.setLodgingName(firstNonBlank(response.lodgingName(), lodgingInfo.getLodgingName()));
        lodgingInfo.setAddress(firstNonBlank(response.address(), lodgingInfo.getAddress()));
        lodgingInfo.setRepresentativeName(firstNonBlank(
                response.representativeName(),
                lodgingInfo.getRepresentativeName()));
        lodgingInfo.setPhoneNumber(firstNonBlank(response.phoneNumber(), lodgingInfo.getPhoneNumber()));
        lodgingInfo.setUploadedFile(uploadedFile);
        lodgingInfoRepository.save(lodgingInfo);
    }

    private ReceiptReviewOutcome reviewReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String rawText,
            String originalFileName
    ) {
        String source = normalizeReceiptSource(rawText, originalFileName);
        String regionName = trip.getRegion() == null ? "" : nullSafe(trip.getRegion().getName());
        return switch (regionName) {
            case "완도" -> reviewWandoReceipt(usageScope, paymentType, amount);
            case "고흥" -> reviewGoheungReceipt(trip, usageScope, paymentType, amount, source);
            case "해남" -> reviewHaenamReceipt(trip, usageScope, paymentType, amount, source);
            case "남해" -> reviewNamhaeReceipt(trip, usageScope, paymentType, amount, source);
            case "강진" -> reviewGangjinReceipt(trip, usageScope, paymentType, amount, source);
            case "하동" -> reviewHadongReceipt(trip, usageScope, paymentType, amount, source);
            case "영암" -> reviewYeongamReceipt(trip, usageScope, paymentType, amount, source);
            case "밀양" -> reviewMilyangReceipt(trip, usageScope, paymentType, amount, source);
            case "영광" -> reviewYeonggwangReceipt(trip, usageScope, paymentType, amount, source);
            case "합천" -> reviewHapcheonReceipt(trip, usageScope, paymentType, amount, source);
            case "고창" -> reviewGochangReceipt(trip, usageScope, paymentType, amount, source);
            case "거창" -> reviewGeochangReceipt(trip, usageScope, paymentType, amount, source);
            case "제천" -> reviewJecheonReceipt(trip, usageScope, paymentType, amount, source);
            case "영월" -> reviewYeongwolReceipt(trip, usageScope, paymentType, amount, source);
            case "평창" -> reviewPyeongchangReceipt(trip, usageScope, paymentType, amount, source);
            default -> reviewDefaultReceipt(usageScope, paymentType, amount, rawText, originalFileName);
        };
    }

    private boolean isWandoRegion(Region region) {
        return region != null && "완도".equals(region.getName());
    }

    private ReceiptReviewOutcome reviewWandoReceipt(
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount
    ) {
        Set<PaymentType> generalApproved = Set.of(
                PaymentType.CREDIT_CARD,
                PaymentType.CHECK_CARD,
                PaymentType.ONLINE_PAYMENT
        );
        Set<PaymentType> lodgingApproved = Set.of(
                PaymentType.CREDIT_CARD,
                PaymentType.CHECK_CARD,
                PaymentType.ONLINE_PAYMENT,
                PaymentType.CASH_RECEIPT
        );
        Set<PaymentType> approvedTypes = usageScope == ReceiptUsageScope.LODGING ? lodgingApproved : generalApproved;
        if (approvedTypes.contains(paymentType)) {
            return new ReceiptReviewOutcome(
                    ReceiptReviewStatus.APPROVED,
                    amount == null ? 0 : amount,
                    usageScope == ReceiptUsageScope.LODGING && paymentType == PaymentType.CASH_RECEIPT
                            ? "완도 숙박업소 관련 결제는 현금영수증도 인정됩니다."
                            : "완도 정산 규칙에 맞는 결제 영수증입니다."
            );
        }
        return new ReceiptReviewOutcome(
                ReceiptReviewStatus.REJECTED,
                0,
                switch (paymentType) {
                    case CASH_RECEIPT -> usageScope == ReceiptUsageScope.LODGING
                            ? "현금영수증은 숙박업소 관련 결제일 때만 인정됩니다."
                            : "완도 일반 소비는 현금영수증이 인정되지 않습니다.";
                    case BANK_TRANSFER -> "계좌이체 내역은 완도 정산 증빙으로 인정되지 않습니다.";
                    case SIMPLE_RECEIPT -> "간이영수증은 완도 정산 증빙으로 인정되지 않습니다.";
                    case UNKNOWN -> "결제수단을 판별하지 못해 자동 심사를 통과하지 못했습니다.";
                    default -> "완도 정산 규칙에 맞지 않는 영수증입니다.";
                }
        );
    }

    private ReceiptReviewOutcome reviewDefaultReceipt(
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String rawText,
            String originalFileName
    ) {
        if (paymentType == PaymentType.CREDIT_CARD
                || paymentType == PaymentType.CHECK_CARD
                || paymentType == PaymentType.ONLINE_PAYMENT) {
            return new ReceiptReviewOutcome(
                    ReceiptReviewStatus.APPROVED,
                    amount == null ? 0 : amount,
                    "기본 MVP 규칙으로 승인되었습니다. 지역별 세부 정산 규칙은 TODO입니다."
            );
        }
        return new ReceiptReviewOutcome(
                ReceiptReviewStatus.REJECTED,
                0,
                "기본 MVP 규칙상 비승인 처리되었습니다. 지역별 세부 정산 규칙 연동은 TODO입니다."
        );
    }

    private ReceiptReviewOutcome reviewGoheungReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (usageScope == ReceiptUsageScope.LODGING) {
            if (isGoheungLocalCurrencyReceipt(source)) {
                return approve(amount, "고흥 숙박 결제는 고흥사랑상품권 거래내역으로 인정됩니다.");
            }
            if (isCardPayment(paymentType)) {
                return approve(amount, "고흥 숙박업소 결제는 카드영수증도 인정됩니다.");
            }
            return reject("고흥 숙박은 고흥사랑상품권 거래내역 또는 카드영수증만 인정됩니다.");
        }
        if (isGoheungPaperVoucher(source)) {
            return reject("지류형 고흥사랑상품권 이용금액은 정산 신청이 불가합니다.");
        }
        if (isGoheungLocalCurrencyReceipt(source) && hasApplicantPhone(source, trip)) {
            return approve(amount, "신청 대표자 휴대전화가 기재된 고흥사랑상품권 거래내역으로 확인되었습니다.");
        }
        if (isGoheungLocalCurrencyReceipt(source)) {
            return reject("고흥 일반 소비는 신청 대표자 휴대전화가 기재된 CHAK 거래내역만 인정됩니다.");
        }
        return reject("고흥 일반 소비는 모바일 고흥사랑상품권(QR/카드결제) 거래내역만 인정됩니다.");
    }

    private ReceiptReviewOutcome reviewHaenamReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (isCardPayment(paymentType)) {
            return approve(amount, "해남은 신청대표자 명의 카드 영수증을 인정합니다.");
        }
        if (paymentType == PaymentType.CASH_RECEIPT) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "해남은 신청대표자 휴대전화가 기재된 현금영수증을 인정합니다.");
        }
        if (isChakReceipt(source)) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "해남은 신청대표자 휴대전화가 기재된 CHAK 거래내역을 인정합니다.");
        }
        return reject("해남은 카드영수증, 현금영수증, 휴대전화 번호가 기재된 CHAK 거래내역만 인정됩니다.");
    }

    private ReceiptReviewOutcome reviewNamhaeReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (containsAnyKeyword(source,
                "사우스케이프오너스클럽",
                "쏠비치 호텔 남해",
                "쏠비치호텔남해",
                "쏠비치 빌라 남해",
                "쏠비치빌라남해",
                "아난티 남해",
                "아난티남해",
                "스포츠파크 호텔",
                "스포츠파크호텔",
                "라피스 호텔",
                "라피스호텔")) {
            return reject("남해는 연 매출 30억원 이상 제외 업체 결제분을 인정하지 않습니다.");
        }
        if (isCardPayment(paymentType)) {
            return approve(amount, "남해는 신청대표자 명의 카드 결제를 인정합니다.");
        }
        if (usageScope == ReceiptUsageScope.LODGING && paymentType == PaymentType.ONLINE_PAYMENT && hasLodgingPlatformKeyword(source)) {
            return approve(amount, "남해는 숙박 결제 플랫폼 영수증을 인정합니다.");
        }
        if (isBepayOrZeroPayReceipt(source) || containsAnyKeyword(source, "반반남해")) {
            return approve(amount, "남해는 비플페이 반반남해 전용 지역사랑상품권 거래내역을 인정합니다.");
        }
        return reject("남해는 반반남해 상품권 거래내역, 카드 결제, 숙박 플랫폼 영수증만 인정됩니다.");
    }

    private ReceiptReviewOutcome reviewGangjinReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (isCardPayment(paymentType)) {
            return approve(amount, "강진은 신청대표자 명의 카드영수증을 인정합니다.");
        }
        if (paymentType == PaymentType.CASH_RECEIPT) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "강진은 휴대폰번호가 기재된 현금영수증을 인정합니다.");
        }
        if (isChakReceipt(source)) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "강진은 휴대폰번호가 기재된 CHAK 거래내역을 인정합니다.");
        }
        return reject("강진은 카드영수증, 현금영수증, 휴대폰번호가 기재된 CHAK 거래내역만 인정됩니다.");
    }

    private ReceiptReviewOutcome reviewHadongReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (usageScope == ReceiptUsageScope.LODGING) {
            if (paymentType == PaymentType.CREDIT_CARD
                    || paymentType == PaymentType.CHECK_CARD
                    || paymentType == PaymentType.CASH_RECEIPT
                    || paymentType == PaymentType.ONLINE_PAYMENT) {
                return approve(amount, "하동 숙박은 카드영수증, 현금영수증, 온라인 결제 영수증을 인정합니다.");
            }
            return reject("하동 숙박은 카드영수증, 현금영수증, 온라인 결제 영수증만 인정됩니다.");
        }
        if (isZeroPayReceipt(source)) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "하동 일반 소비는 신청 대표자 휴대폰의 제로페이 거래내역만 인정합니다.");
        }
        return reject("하동 일반 소비는 신청 대표자 휴대폰의 제로페이 거래내역만 인정되며 개인카드와 현금은 불인정입니다.");
    }

    private ReceiptReviewOutcome reviewYeongamReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (containsAnyKeyword(source, "정책수당")) {
            return reject("영암은 월출페이 정책수당 결제분을 인정하지 않습니다.");
        }
        if (isCardPayment(paymentType) || paymentType == PaymentType.CASH_RECEIPT) {
            return approve(amount, "영암은 카드영수증과 현금영수증을 인정합니다.");
        }
        if (containsAnyKeyword(source, "월출페이")) {
            return approve(amount, "영암은 월출페이 지출내역을 인정합니다.");
        }
        return reject("영암은 현금영수증, 카드영수증, 월출페이 지출내역만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewMilyangReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (usageScope == ReceiptUsageScope.LODGING) {
            if ((paymentType == PaymentType.CREDIT_CARD || paymentType == PaymentType.CHECK_CARD) && hasLodgingPlatformKeyword(source)) {
                return approve(amount, "밀양 숙박은 인터넷 숙박 예약 카드 결제 영수증을 인정합니다.");
            }
            if (paymentType == PaymentType.ONLINE_PAYMENT && hasLodgingPlatformKeyword(source)) {
                return approve(amount, "밀양 숙박은 인터넷 숙박 예약 결제 영수증을 인정합니다.");
            }
            return reject("밀양 숙박은 인터넷 숙박 예약 결제 영수증 또는 카드 결제 영수증만 인정합니다.");
        }
        if (isZeroPayReceipt(source)) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "밀양 일반 소비는 신청 대표자 본인명의 휴대폰 제로페이 사용내역만 인정합니다.");
        }
        return reject("밀양 일반 소비는 제로페이 사용내역만 인정되며 카드영수증, 간이영수증, 계좌이체내역은 불인정입니다.");
    }

    private ReceiptReviewOutcome reviewYeonggwangReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (isCardPayment(paymentType)) {
            return approve(amount, "영광은 신청 대표자 명의 카드 영수증을 인정합니다.");
        }
        if (paymentType == PaymentType.CASH_RECEIPT) {
            return approveWithPhoneCheck(amount, hasApplicantPhone(source, trip), "영광은 휴대폰번호가 기재된 현금 영수증을 인정합니다.");
        }
        if (containsAnyKeyword(source, "그리고")) {
            return approve(amount, "영광은 '그리고' 앱 또는 카드 거래내역 영수증을 인정합니다.");
        }
        return reject("영광은 카드영수증, 휴대폰번호가 기재된 현금영수증, '그리고' 앱 거래내역만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewHapcheonReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (usageScope == ReceiptUsageScope.LODGING) {
            if (paymentType == PaymentType.CREDIT_CARD
                    || paymentType == PaymentType.CHECK_CARD
                    || paymentType == PaymentType.CASH_RECEIPT
                    || paymentType == PaymentType.ONLINE_PAYMENT) {
                return approve(amount, "합천 숙박은 카드영수증, 현금영수증, 온라인 결제 영수증을 인정합니다.");
            }
            return reject("합천 숙박은 카드영수증, 현금영수증, 온라인 결제 영수증만 인정됩니다.");
        }
        if (isZeroPayReceipt(source) && containsAnyKeyword(source, "합천", "반값여행", "상품권")) {
            return approve(amount, "합천은 모바일 합천반값여행 상품권 제로페이 사용내역만 인정합니다.");
        }
        return reject("합천 일반 소비는 제로페이 앱의 모바일 합천반값여행 상품권 사용내역만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewGochangReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (usageScope == ReceiptUsageScope.LODGING) {
            if (paymentType == PaymentType.CREDIT_CARD || paymentType == PaymentType.CHECK_CARD) {
                return approve(amount, "고창 숙박은 카드 결제 영수증을 인정합니다.");
            }
            if (paymentType == PaymentType.ONLINE_PAYMENT && hasLodgingPlatformKeyword(source)) {
                return approve(amount, "고창 숙박은 온라인 숙박 예약 결제 영수증을 인정합니다.");
            }
            return reject("고창 숙박은 카드 결제 영수증 또는 온라인 숙박 예약 결제 영수증만 인정합니다.");
        }
        if (paymentType == PaymentType.CREDIT_CARD) {
            return approve(amount, "고창은 개인 신용카드 지출 영수증을 인정합니다.");
        }
        if (containsAnyKeyword(source, "고창사랑카드")) {
            return approve(amount, "고창은 고창사랑카드 사용 영수증을 인정합니다.");
        }
        return reject("고창 일반 소비는 개인 신용카드 또는 고창사랑카드 영수증만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewGeochangReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (usageScope == ReceiptUsageScope.LODGING) {
            if (paymentType == PaymentType.CREDIT_CARD
                    || paymentType == PaymentType.CHECK_CARD
                    || paymentType == PaymentType.CASH_RECEIPT
                    || paymentType == PaymentType.ONLINE_PAYMENT) {
                return approve(amount, "거창 숙박은 카드영수증, 현금영수증, 온라인 결제 영수증을 인정합니다.");
            }
            return reject("거창 숙박은 카드영수증, 현금영수증, 온라인 결제 영수증만 인정됩니다.");
        }
        if (isZeroPayReceipt(source) && containsAnyKeyword(source, "거창", "반값여행", "상품권")) {
            return approve(amount, "거창은 모바일 거창반값여행 정책발행용 상품권 전자영수증만 인정합니다.");
        }
        return reject("거창 일반 소비는 제로페이 앱의 거창반값여행 정책발행용 상품권 전자영수증만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewJecheonReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (containsAnyKeyword(source, "에어비앤비", "airbnb")) {
            return reject("제천은 에어비앤비 결제분을 인정하지 않습니다.");
        }
        if (usageScope == ReceiptUsageScope.LODGING) {
            if (paymentType == PaymentType.CREDIT_CARD
                    || paymentType == PaymentType.CHECK_CARD
                    || paymentType == PaymentType.ONLINE_PAYMENT) {
                return approve(amount, "제천 숙박업 결제는 카드 또는 온라인 결제 영수증을 인정합니다.");
            }
            return reject("제천 숙박은 카드 또는 온라인 결제 영수증만 인정합니다.");
        }
        if ((paymentType == PaymentType.CREDIT_CARD
                || paymentType == PaymentType.CHECK_CARD
                || paymentType == PaymentType.ONLINE_PAYMENT)
                && containsAnyKeyword(source,
                "케이블카",
                "모노레일",
                "유람선",
                "크루즈",
                "시티투어",
                "관광택시",
                "가스트로투어")) {
            return approve(amount, "제천 일반 소비는 허용된 관광 상품 결제만 카드 결제가 인정됩니다.");
        }
        return reject("제천 일반 소비는 숙박업 또는 케이블카·유람선·시티투어·관광택시·가스트로투어 결제만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewYeongwolReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (containsAnyKeyword(source, "주유소", "카센타", "카센터", "금은방", "보습학원", "학원", "유흥")) {
            return reject("영월은 주유소, 카센터, 금은방, 학원, 유흥시설 결제분을 인정하지 않습니다.");
        }
        if (paymentType == PaymentType.BANK_TRANSFER || paymentType == PaymentType.SIMPLE_RECEIPT) {
            return reject("영월은 계좌이체, 간이영수증을 인정하지 않습니다.");
        }
        if (paymentType == PaymentType.CREDIT_CARD || paymentType == PaymentType.CHECK_CARD || paymentType == PaymentType.CASH_RECEIPT) {
            return approve(amount, "영월은 신용카드, 체크카드, 현금영수증을 인정합니다.");
        }
        if (containsAnyKeyword(source, "지역화폐", "chak", "체크페이", "제로페이", "비플페이")) {
            return approve(amount, "영월은 지역화폐 거래내역을 인정합니다.");
        }
        return reject("영월은 신용카드, 체크카드, 지역화폐, 현금영수증만 인정합니다.");
    }

    private ReceiptReviewOutcome reviewPyeongchangReceipt(
            Trip trip,
            ReceiptUsageScope usageScope,
            PaymentType paymentType,
            Integer amount,
            String source
    ) {
        if (containsAnyKeyword(source, "주유소", "금은방", "카센터", "카센타", "학원", "유흥", "골프장")) {
            return reject("평창은 주유소, 금은방, 카센터, 학원, 유흥업소, 골프장 결제를 인정하지 않습니다.");
        }
        if (paymentType == PaymentType.CREDIT_CARD) {
            return approve(amount, "평창은 개인 신용카드 영수증만 인정합니다.");
        }
        return reject("평창은 개인 신용카드 영수증만 인정하며 현금영수증, Pay 결제, 간이영수증, 계좌이체는 불인정입니다.");
    }

    private ReceiptReviewOutcome approve(int amount, String reason) {
        return new ReceiptReviewOutcome(
                ReceiptReviewStatus.APPROVED,
                Math.max(amount, 0),
                reason
        );
    }

    private ReceiptReviewOutcome approve(Integer amount, String reason) {
        return approve(amount == null ? 0 : amount, reason);
    }

    private ReceiptReviewOutcome approveWithPhoneCheck(Integer amount, boolean hasPhone, String successReason) {
        if (!hasPhone) {
            return reject("신청 대표자 휴대전화 번호가 영수증에 확인되지 않아 자동 심사를 통과하지 못했습니다.");
        }
        return approve(amount, successReason);
    }

    private ReceiptReviewOutcome reject(String reason) {
        return new ReceiptReviewOutcome(ReceiptReviewStatus.REJECTED, 0, reason);
    }

    private String normalizeReceiptSource(String rawText, String originalFileName) {
        return (nullSafe(rawText) + " " + nullSafe(originalFileName))
                .toLowerCase(Locale.ROOT)
                .replaceAll("\\s+", "");
    }

    private boolean isCardPayment(PaymentType paymentType) {
        return paymentType == PaymentType.CREDIT_CARD || paymentType == PaymentType.CHECK_CARD;
    }

    private boolean hasApplicantPhone(String source, Trip trip) {
        String phone = trip == null ? "" : digitsOnly(trip.getPhoneNumber());
        return !phone.isBlank() && digitsOnly(source).contains(phone);
    }

    private String digitsOnly(String value) {
        return value == null ? "" : value.replaceAll("\\D+", "");
    }

    private boolean containsAnyKeyword(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(keyword.toLowerCase(Locale.ROOT).replaceAll("\\s+", ""))) {
                return true;
            }
        }
        return false;
    }

    private boolean hasLodgingPlatformKeyword(String source) {
        return containsAnyKeyword(source,
                "야놀자",
                "여기어때",
                "네이버예약",
                "네이버숙소",
                "네이버",
                "agoda",
                "booking",
                "trip.com",
                "호텔스닷컴",
                "expedia",
                "airbnb",
                "에어비앤비");
    }

    private boolean isChakReceipt(String source) {
        return containsAnyKeyword(source, "chak", "지역사랑상품권", "chak거래내역");
    }

    private boolean isZeroPayReceipt(String source) {
        return containsAnyKeyword(source, "제로페이", "zeropay", "비플페이", "비플", "bple", "bpay");
    }

    private boolean isBepayOrZeroPayReceipt(String source) {
        return isZeroPayReceipt(source) || containsAnyKeyword(source, "비플pay", "bepay", "bepay");
    }

    private boolean isGoheungLocalCurrencyReceipt(String source) {
        return isChakReceipt(source) && containsAnyKeyword(source, "고흥", "고흥사랑상품권");
    }

    private boolean isGoheungPaperVoucher(String source) {
        return containsAnyKeyword(source, "지류", "종이상품권");
    }

    private record ReceiptReviewOutcome(
            ReceiptReviewStatus reviewStatus,
            Integer eligibleAmount,
            String reviewReason
    ) {
    }

    private LodgingFormTemplate findActiveTemplate(Long regionId) {
        return lodgingFormTemplateRepository.findByRegionIdAndIsActiveTrue(regionId)
                .orElseThrow(() -> new NotFoundException("Lodging form template not found"));
    }

    private List<TripDtos.LodgingFormFieldItem> buildFieldItems(LodgingFormTemplate template) {
        List<Map<String, Object>> schema = parseFieldSchema(resolveTemplateSchemaJson(template));
        List<TripDtos.LodgingFormFieldItem> fields = new ArrayList<>();
        for (Map<String, Object> item : schema) {
            String key = String.valueOf(item.getOrDefault("key", ""));
            String label = stringOrFallback(item.get("label"), labelForKey(key));
            String helperText = stringOrFallback(item.get("helperText"), helperTextForKey(key));
            fields.add(new TripDtos.LodgingFormFieldItem(
                    key,
                    label,
                    String.valueOf(item.getOrDefault("type", "text")),
                    toDouble(item.get("x")),
                    toDouble(item.get("y")),
                    toDouble(item.get("width")),
                    toDouble(item.get("height")),
                    toBoolean(item.get("editable")),
                    toBoolean(item.get("multiline")),
                    helperText));
        }
        return fields;
    }

    private List<String> buildTemplateNotes(LodgingFormTemplate template) {
        List<String> notes = new ArrayList<>();
        notes.add("현재 템플릿 형식: " + template.getSourceFormat());
        if (template.getSourceFilePath() != null && !template.getSourceFilePath().isBlank()) {
            notes.add("연결된 원본 파일: " + template.getSourceFilePath());
        } else {
            notes.add("연결된 원본 파일이 없어 현재는 공통 MVP 템플릿으로 표시됩니다.");
        }
        if (hasTemplateSchemaResource(template)) {
            notes.add("Coordinate schema file: " + templateSchemaResourceName(template));
        }
        if (template.getPreviewSubtitle() != null && !template.getPreviewSubtitle().isBlank()) {
            notes.add(template.getPreviewSubtitle());
        }
        return notes;
    }

    private Map<String, Object> buildBasePayload(Trip trip, LodgingInfo lodgingInfo) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("traveler_name", trip.getApplicantName());
        payload.put("traveler_phone_number", trip.getPhoneNumber());
        payload.put("region_name", trip.getRegion().getName());
        payload.put("residence", trip.getResidence());
        payload.put("trip_date_range", trip.getStartDate() + " ~ " + trip.getEndDate());
        payload.put("lodging_name", lodgingInfo == null ? "" : nullSafe(lodgingInfo.getLodgingName()));
        payload.put("business_number", "");
        payload.put("representative_name", lodgingInfo == null ? "" : nullSafe(lodgingInfo.getRepresentativeName()));
        payload.put("phone_number", lodgingInfo == null ? "" : nullSafe(lodgingInfo.getPhoneNumber()));
        payload.put("address", lodgingInfo == null ? "" : nullSafe(lodgingInfo.getAddress()));
        payload.put("occupancy_count", "");
        payload.put("payment_amount", "");
        payload.put("payment_date", "");
        payload.put("agreed_personal_info", lodgingInfo != null && Boolean.TRUE.equals(lodgingInfo.getAgreedPersonalInfo()));
        payload.put("agreed_stay_proof", lodgingInfo != null && Boolean.TRUE.equals(lodgingInfo.getAgreedStayProof()));
        payload.put("signature", lodgingInfo == null ? "" : nullSafe(lodgingInfo.getSignatureSvgPath()));
        return payload;
    }

    private Map<String, Object> mergePayloads(Map<String, Object> basePayload, Map<String, Object> overridePayload) {
        Map<String, Object> merged = new LinkedHashMap<>(basePayload);
        if (overridePayload == null) {
            return merged;
        }
        merged.putAll(overridePayload);
        return merged;
    }

    private Map<String, Object> normalizeLodgingFormPayload(
            List<TripDtos.LodgingFormFieldItem> fields,
            Map<String, Object> sourcePayload,
            Trip trip,
            LodgingInfo lodgingInfo
    ) {
        Map<String, Object> normalized = new LinkedHashMap<>(sourcePayload);
        Set<String> fieldKeys = new HashSet<>();
        for (TripDtos.LodgingFormFieldItem field : fields) {
            fieldKeys.add(field.key());
        }

        if (fieldKeys.contains("phone_number_mid") || fieldKeys.contains("phone_number_last")) {
            String composedPhoneNumber = composePhoneNumber(
                    stringPayload(normalized, "phone_number"),
                    stringPayload(normalized, "phone_number_mid"),
                    stringPayload(normalized, "phone_number_last"));
            if (!composedPhoneNumber.isBlank()) {
                normalized.put("phone_number", composedPhoneNumber);
            }
        }
        if (fieldKeys.contains("traveler_phone_mid") || fieldKeys.contains("traveler_phone_last")) {
            String composedTravelerPhone = composePhoneNumber(
                    stringPayload(normalized, "traveler_phone_number"),
                    stringPayload(normalized, "traveler_phone_mid"),
                    stringPayload(normalized, "traveler_phone_last"));
            if (!composedTravelerPhone.isBlank()) {
                normalized.put("traveler_phone_number", composedTravelerPhone);
            }
        }
        if (fieldKeys.contains("payment_date_year")
                || fieldKeys.contains("payment_date_month")
                || fieldKeys.contains("payment_date_day")) {
            String composedPaymentDate = composeDate(
                    stringPayload(normalized, "payment_date"),
                    stringPayload(normalized, "payment_date_year"),
                    stringPayload(normalized, "payment_date_month"),
                    stringPayload(normalized, "payment_date_day"));
            if (!composedPaymentDate.isBlank()) {
                normalized.put("payment_date", composedPaymentDate);
            }
        }
        if (fieldKeys.contains("confirmation_date_year")
                || fieldKeys.contains("confirmation_date_month")
                || fieldKeys.contains("confirmation_date_day")) {
            String composedConfirmationDate = composeDate(
                    stringPayload(normalized, "confirmation_date"),
                    stringPayload(normalized, "confirmation_date_year"),
                    stringPayload(normalized, "confirmation_date_month"),
                    stringPayload(normalized, "confirmation_date_day"));
            if (!composedConfirmationDate.isBlank()) {
                normalized.put("confirmation_date", composedConfirmationDate);
            }
        }

        // Keep generic trip values in sync for duplicated placements such as
        // guest/applicant name and phone sections in the Wando fixed PDF.
        if (fieldKeys.contains("traveler_name")) {
            normalized.put("traveler_name", firstNonBlank(
                    stringPayload(normalized, "traveler_name"),
                    stringPayload(normalized, "applicant_name_bottom"),
                    trip.getApplicantName()));
        }
        if (fieldKeys.contains("applicant_name_bottom")) {
            normalized.put("applicant_name_bottom", firstNonBlank(
                    stringPayload(normalized, "applicant_name_bottom"),
                    stringPayload(normalized, "traveler_name"),
                    trip.getApplicantName()));
        }
        if (fieldKeys.contains("traveler_phone_number")) {
            normalized.put("traveler_phone_number", firstNonBlank(
                    stringPayload(normalized, "traveler_phone_number"),
                    trip.getPhoneNumber()));
        }
        if (fieldKeys.contains("residence")) {
            normalized.put("residence", firstNonBlank(
                    stringPayload(normalized, "residence"),
                    trip.getResidence()));
        }
        if (fieldKeys.contains("lodging_name")) {
            normalized.put("lodging_name", firstNonBlank(
                    stringPayload(normalized, "lodging_name"),
                    lodgingInfo == null ? "" : lodgingInfo.getLodgingName()));
        }
        if (fieldKeys.contains("representative_name")) {
            normalized.put("representative_name", firstNonBlank(
                    stringPayload(normalized, "representative_name"),
                    lodgingInfo == null ? "" : lodgingInfo.getRepresentativeName()));
        }
        if (fieldKeys.contains("phone_number")) {
            normalized.put("phone_number", firstNonBlank(
                    stringPayload(normalized, "phone_number"),
                    lodgingInfo == null ? "" : lodgingInfo.getPhoneNumber()));
        }
        if (fieldKeys.contains("phone_number_mid")) {
            normalized.put("phone_number_mid", extractPhoneMiddleDigits(firstNonBlank(
                    stringPayload(normalized, "phone_number"),
                    lodgingInfo == null ? "" : lodgingInfo.getPhoneNumber())));
        }
        if (fieldKeys.contains("phone_number_last")) {
            normalized.put("phone_number_last", extractPhoneLastDigits(firstNonBlank(
                    stringPayload(normalized, "phone_number"),
                    lodgingInfo == null ? "" : lodgingInfo.getPhoneNumber())));
        }
        if (fieldKeys.contains("address")) {
            normalized.put("address", firstNonBlank(
                    stringPayload(normalized, "address"),
                    lodgingInfo == null ? "" : lodgingInfo.getAddress()));
        }
        if (fieldKeys.contains("confirmation_date")) {
            normalized.put("confirmation_date", firstNonBlank(
                    stringPayload(normalized, "confirmation_date"),
                    stringPayload(normalized, "payment_date")));
        }
        if (fieldKeys.contains("traveler_phone_mid")) {
            normalized.put("traveler_phone_mid", extractPhoneMiddleDigits(firstNonBlank(
                    stringPayload(normalized, "traveler_phone_number"),
                    composePhoneNumber(
                            "",
                            stringPayload(normalized, "applicant_phone_mid_bottom"),
                            stringPayload(normalized, "applicant_phone_last_bottom")),
                    trip.getPhoneNumber())));
        }
        if (fieldKeys.contains("traveler_phone_last")) {
            normalized.put("traveler_phone_last", extractPhoneLastDigits(firstNonBlank(
                    stringPayload(normalized, "traveler_phone_number"),
                    composePhoneNumber(
                            "",
                            stringPayload(normalized, "applicant_phone_mid_bottom"),
                            stringPayload(normalized, "applicant_phone_last_bottom")),
                    trip.getPhoneNumber())));
        }
        if (fieldKeys.contains("applicant_phone_mid_bottom")) {
            normalized.put("applicant_phone_mid_bottom", extractPhoneMiddleDigits(firstNonBlank(
                    stringPayload(normalized, "traveler_phone_number"),
                    trip.getPhoneNumber())));
        }
        if (fieldKeys.contains("applicant_phone_last_bottom")) {
            normalized.put("applicant_phone_last_bottom", extractPhoneLastDigits(firstNonBlank(
                    stringPayload(normalized, "traveler_phone_number"),
                    trip.getPhoneNumber())));
        }
        if (fieldKeys.contains("payment_date_year")
                || fieldKeys.contains("payment_date_month")
                || fieldKeys.contains("payment_date_day")) {
            DateParts parts = extractDateParts(stringPayload(normalized, "payment_date"));
            if (fieldKeys.contains("payment_date_year")) {
                normalized.put("payment_date_year", parts.year());
            }
            if (fieldKeys.contains("payment_date_month")) {
                normalized.put("payment_date_month", parts.month());
            }
            if (fieldKeys.contains("payment_date_day")) {
                normalized.put("payment_date_day", parts.day());
            }
        }
        if (fieldKeys.contains("confirmation_date_year")
                || fieldKeys.contains("confirmation_date_month")
                || fieldKeys.contains("confirmation_date_day")) {
            DateParts parts = extractDateParts(firstNonBlank(
                    stringPayload(normalized, "confirmation_date"),
                    stringPayload(normalized, "payment_date")));
            if (fieldKeys.contains("confirmation_date_year")) {
                normalized.put("confirmation_date_year", parts.year());
            }
            if (fieldKeys.contains("confirmation_date_month")) {
                normalized.put("confirmation_date_month", parts.month());
            }
            if (fieldKeys.contains("confirmation_date_day")) {
                normalized.put("confirmation_date_day", parts.day());
            }
        }

        boolean agreedPersonalInfo = resolveBoolean(
                normalized,
                "agreed_personal_info_yes",
                "agreed_personal_info");
        boolean agreedStayProof = resolveBoolean(
                normalized,
                "agreed_stay_proof_yes",
                "agreed_stay_proof");
        normalized.put("agreed_personal_info", agreedPersonalInfo);
        normalized.put("agreed_stay_proof", agreedStayProof);
        if (fieldKeys.contains("agreed_personal_info_yes")) {
            normalized.put("agreed_personal_info_yes", agreedPersonalInfo);
        }
        if (fieldKeys.contains("agreed_personal_info_no")) {
            normalized.put("agreed_personal_info_no", !agreedPersonalInfo);
        }
        if (fieldKeys.contains("agreed_stay_proof_yes")) {
            normalized.put("agreed_stay_proof_yes", agreedStayProof);
        }
        if (fieldKeys.contains("agreed_stay_proof_no")) {
            normalized.put("agreed_stay_proof_no", !agreedStayProof);
        }

        if (fieldKeys.contains("payment_method_lodging_app")) {
            normalized.put("payment_method_lodging_app",
                    booleanPayload(normalized, "payment_method_lodging_app"));
        }
        if (fieldKeys.contains("payment_method_card")) {
            normalized.put("payment_method_card",
                    booleanPayload(normalized, "payment_method_card"));
        }
        if (fieldKeys.contains("payment_method_other")) {
            normalized.put("payment_method_other",
                    booleanPayload(normalized, "payment_method_other"));
        }
        if (fieldKeys.contains("payment_method_other_text")) {
            normalized.put("payment_method_other_text",
                    stringPayload(normalized, "payment_method_other_text"));
        }

        String hostSignature = firstNonBlank(
                stringPayload(normalized, "host_signature"),
                stringPayload(normalized, "signature"),
                lodgingInfo == null ? "" : lodgingInfo.getSignatureSvgPath());
        if (fieldKeys.contains("host_signature")) {
            normalized.put("host_signature", hostSignature);
        }
        normalized.put("signature", hostSignature);

        if (fieldKeys.contains("applicant_signature")) {
            normalized.put("applicant_signature", firstNonBlank(
                    stringPayload(normalized, "applicant_signature"),
                    hostSignature));
        }

        return normalized;
    }

    private String extractPhoneMiddleDigits(String phoneNumber) {
        String digits = onlyDigits(phoneNumber);
        if (digits.length() < 8) {
            return "";
        }
        return digits.substring(3, digits.length() - 4);
    }

    private String extractPhoneLastDigits(String phoneNumber) {
        String digits = onlyDigits(phoneNumber);
        if (digits.length() < 4) {
            return "";
        }
        return digits.substring(digits.length() - 4);
    }

    private String onlyDigits(String value) {
        return nullSafe(value).replaceAll("\\D", "");
    }

    private DateParts extractDateParts(String raw) {
        String value = nullSafe(raw).trim();
        if (value.isBlank()) {
            return new DateParts("", "", "");
        }

        String normalized = value.replace('.', '-').replace('/', '-');
        try {
            LocalDate parsed = LocalDate.parse(normalized);
            return new DateParts(
                    Integer.toString(parsed.getYear()),
                    Integer.toString(parsed.getMonthValue()),
                    Integer.toString(parsed.getDayOfMonth()));
        } catch (Exception ignored) {
            // Fall back to digit chunk parsing for loosely formatted input.
        }

        Matcher matcher = Pattern.compile("(\\d{4})\\D*(\\d{1,2})\\D*(\\d{1,2})").matcher(value);
        if (matcher.find()) {
            return new DateParts(matcher.group(1), matcher.group(2), matcher.group(3));
        }
        return new DateParts(value, "", "");
    }

    private record DateParts(String year, String month, String day) {
    }

    private List<Map<String, Object>> parseFieldSchema(String schemaJson) {
        try {
            return objectMapper.readValue(schemaJson, FIELD_SCHEMA_TYPE);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to parse lodging form template schema", exception);
        }
    }

    private String resolveTemplateSchemaJson(LodgingFormTemplate template) {
        String dbSchemaJson = template.getTemplateSchemaJson();
        boolean preferDatabaseLayout = "DB_LAYOUT".equalsIgnoreCase(nullSafe(template.getDataSourceNote()));
        if (preferDatabaseLayout && dbSchemaJson != null && !dbSchemaJson.isBlank()) {
            return dbSchemaJson;
        }
        Resource resource = resourceLoader.getResource(
                TEMPLATE_SCHEMA_RESOURCE_PREFIX + templateSchemaResourceName(template));
        if (!resource.exists()) {
            return dbSchemaJson;
        }
        try {
            return resource.getContentAsString(StandardCharsets.UTF_8);
        } catch (IOException exception) {
            throw new IllegalStateException("Failed to read lodging form coordinate schema file", exception);
        }
    }

    private boolean hasTemplateSchemaResource(LodgingFormTemplate template) {
        return resourceLoader.getResource(
                TEMPLATE_SCHEMA_RESOURCE_PREFIX + templateSchemaResourceName(template)).exists();
    }

    private String templateSchemaResourceName(LodgingFormTemplate template) {
        String templateName = template.getTemplateName();
        int extensionIndex = templateName.lastIndexOf('.');
        if (extensionIndex < 0) {
            return templateName + ".json";
        }
        return templateName.substring(0, extensionIndex) + ".json";
    }

    private Map<String, Object> parsePayload(String payloadJson) {
        try {
            return objectMapper.readValue(payloadJson, PAYLOAD_TYPE);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to parse lodging form payload", exception);
        }
    }

    private String writeJson(Object payload) {
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException exception) {
            throw new IllegalStateException("Failed to write lodging form payload", exception);
        }
    }

    private void syncLodgingInfoFromPayload(Trip trip, Map<String, Object> payload) {
        LodgingInfo lodgingInfo = lodgingInfoRepository.findByTripId(trip.getId()).orElseGet(LodgingInfo::new);
        lodgingInfo.setTrip(trip);
        lodgingInfo.setLodgingName(stringPayload(payload, "lodging_name"));
        lodgingInfo.setRepresentativeName(stringPayload(payload, "representative_name"));
        lodgingInfo.setPhoneNumber(composePhoneNumber(
                stringPayload(payload, "phone_number"),
                stringPayload(payload, "phone_number_mid"),
                stringPayload(payload, "phone_number_last")));
        lodgingInfo.setAddress(stringPayload(payload, "address"));
        String signature = stringPayload(payload, "host_signature");
        if (signature.isBlank()) {
            signature = stringPayload(payload, "signature");
        }
        lodgingInfo.setSignatureSvgPath(signature);
        lodgingInfo.setAgreedPersonalInfo(resolveBoolean(payload, "agreed_personal_info_yes", "agreed_personal_info"));
        lodgingInfo.setAgreedStayProof(resolveBoolean(payload, "agreed_stay_proof_yes", "agreed_stay_proof"));
        lodgingInfoRepository.save(lodgingInfo);
    }

    private byte[] maybeRenderLodgingFormPdfBytes(Long tripId) throws IOException {
        boolean hasContent = lodgingInfoRepository.findByTripId(tripId).isPresent()
                || lodgingFormInstanceRepository.findByTripId(tripId).isPresent();
        return hasContent ? renderLodgingFormPdfBytes(tripId) : null;
    }

    private String composePhoneNumber(String fullValue, String middleValue, String lastValue) {
        String direct = onlyDigits(fullValue);
        if (direct.length() >= 10) {
            return direct;
        }

        String middle = onlyDigits(middleValue);
        String last = onlyDigits(lastValue);
        if (middle.isBlank() && last.isBlank()) {
            return "";
        }

        String prefix = "010";
        if (!middle.isBlank() && !last.isBlank()) {
            return prefix + middle + last;
        }
        return "";
    }

    private String composeDate(String directValue, String yearValue, String monthValue, String dayValue) {
        String direct = directValue == null ? "" : directValue.trim();
        if (!direct.isBlank()) {
            return direct;
        }

        String year = onlyDigits(yearValue);
        String month = onlyDigits(monthValue);
        String day = onlyDigits(dayValue);
        if (year.isBlank() && month.isBlank() && day.isBlank()) {
            return "";
        }

        if (year.isBlank()) {
            year = String.valueOf(LocalDate.now().getYear());
        }
        if (month.isBlank()) {
            month = "1";
        }
        if (day.isBlank()) {
            day = "1";
        }
        return year + "-" + month + "-" + day;
    }

    private byte[] renderLodgingFormPdfBytes(Long tripId) throws IOException {
        TripDtos.LodgingFormData formData = getLodgingFormData(tripId);
        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("template_name", formData.template().templateName());
        requestBody.put("template_key", formData.template().templateKey());
        requestBody.put("region_name", formData.regionName());
        requestBody.put("preview_title", formData.template().previewTitle());
        requestBody.put("preview_subtitle", formData.template().previewSubtitle());
        requestBody.put("render_asset_path", findActiveTemplate(findTrip(tripId).getRegion().getId()).getRenderAssetPath());
        requestBody.put("payload", formData.instance().payload());
        requestBody.put("fields", formData.template().fields());
        requestBody.put("todos", formData.todos());
        return fastApiClient.renderLodgingFormPdf(requestBody);
    }

    private Path resolveTemplatePdfPath(LodgingFormTemplate template) {
        String candidatePath = template.getSourceFilePath();
        if (candidatePath == null || candidatePath.isBlank()) {
            candidatePath = template.getRenderAssetPath();
        }
        if (candidatePath == null || candidatePath.isBlank()) {
            throw new NotFoundException("Template PDF asset not found");
        }

        Path resolved = Path.of(candidatePath);
        if (!resolved.isAbsolute()) {
            Path currentDir = Path.of("").toAbsolutePath();
            Path currentRelative = currentDir.resolve(candidatePath);
            if (Files.exists(currentRelative)) {
                resolved = currentRelative;
            } else {
                resolved = currentDir.resolveSibling("backend-fastapi").resolve(candidatePath);
            }
        }
        if (!Files.exists(resolved)) {
            throw new NotFoundException("Template PDF file does not exist");
        }
        return resolved;
    }

    private ResponseEntity<ByteArrayResource> toPdfResponse(byte[] pdfBytes, String fileName) {
        return toPdfResponse(pdfBytes, fileName, false);
    }

    private ResponseEntity<ByteArrayResource> toPdfResponse(byte[] pdfBytes, String fileName, boolean inline) {
        return toFileResponse(pdfBytes, fileName, MediaType.APPLICATION_PDF_VALUE, inline);
    }

    private ResponseEntity<ByteArrayResource> toFileResponse(
            byte[] fileBytes,
            String fileName,
            String mimeType,
            boolean inline
    ) {
        ByteArrayResource resource = new ByteArrayResource(fileBytes);
        return ResponseEntity.ok()
                .header(HttpHeaders.CONTENT_DISPOSITION,
                        (inline ? "inline" : "attachment") + "; filename=\"" + sanitizeFileName(fileName) + "\"")
                .contentType(resolveMediaType(mimeType))
                .contentLength(fileBytes.length)
                .body(resource);
    }

    private MediaType resolveMediaType(String mimeType) {
        String resolved = mimeType == null || mimeType.isBlank()
                ? MediaType.APPLICATION_OCTET_STREAM_VALUE
                : mimeType;
        try {
            return MediaType.parseMediaType(resolved);
        } catch (IllegalArgumentException ignored) {
            return MediaType.APPLICATION_OCTET_STREAM;
        }
    }

    private String sanitizeFileName(String fileName) {
        if (fileName == null || fileName.isBlank()) {
            return "download.bin";
        }
        return fileName.replace("\"", "");
    }

    private String labelForKey(String key) {
        return switch (key) {
            case "traveler_name" -> "신청자명";
            case "traveler_phone_number" -> "신청자 연락처";
            case "region_name" -> "여행 지역";
            case "trip_date_range" -> "여행 기간";
            case "residence" -> "거주지";
            case "lodging_name" -> "숙박업소명";
            case "business_number" -> "사업자등록번호";
            case "representative_name" -> "대표자명";
            case "phone_number" -> "전화번호";
            case "address" -> "주소";
            case "occupancy_count" -> "숙박 인원";
            case "payment_amount" -> "결제 금액";
            case "payment_date" -> "결제일자";
            case "agreed_personal_info" -> "개인정보 제공 동의";
            case "agreed_stay_proof" -> "실제 숙박 사실 확인";
            case "signature" -> "숙박업주 서명";
            default -> key;
        };
    }

    private String helperTextForKey(String key) {
        return switch (key) {
            case "signature" -> "서명란을 눌러 전자서명을 입력하세요.";
            case "agreed_personal_info", "agreed_stay_proof" -> "숙박업주의 동의를 받은 후 체크하세요.";
            case "lodging_name", "business_number", "representative_name", "phone_number", "address",
                    "occupancy_count", "payment_amount", "payment_date" ->
                    "실제 숙박확인서 원본과 동일하게 입력하세요.";
            default -> "";
        };
    }

    private String stringPayload(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        return value == null ? "" : String.valueOf(value);
    }

    private boolean booleanPayload(Map<String, Object> payload, String key) {
        Object value = payload.get(key);
        if (value instanceof Boolean bool) {
            return bool;
        }
        return value != null && Boolean.parseBoolean(String.valueOf(value));
    }

    private boolean resolveBoolean(Map<String, Object> payload, String specificKey, String fallbackKey) {
        if (payload.containsKey(specificKey)) {
            return booleanPayload(payload, specificKey);
        }
        return booleanPayload(payload, fallbackKey);
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return "";
    }

    private Double toDouble(Object value) {
        if (value instanceof Number number) {
            return number.doubleValue();
        }
        return 0.0;
    }

    private Boolean toBoolean(Object value) {
        if (value instanceof Boolean bool) {
            return bool;
        }
        return value != null && Boolean.parseBoolean(String.valueOf(value));
    }

    private String stringOrFallback(Object value, String fallback) {
        if (value == null) {
            return fallback;
        }
        String stringValue = String.valueOf(value).trim();
        return stringValue.isEmpty() ? fallback : stringValue;
    }

    private String nullSafe(String value) {
        return value == null ? "" : value;
    }
}
