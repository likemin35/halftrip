package com.tourism.travelmvp.service;

import com.tourism.travelmvp.config.AppProperties;
import com.tourism.travelmvp.entity.Trip;
import com.tourism.travelmvp.entity.UploadedFile;
import com.tourism.travelmvp.enums.FileCategory;
import com.tourism.travelmvp.repository.UploadedFileRepository;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

@Service
@RequiredArgsConstructor
public class StorageService {

    private final Path storageRootPath;
    private final UploadedFileRepository uploadedFileRepository;
    private final AppProperties appProperties;

    public UploadedFile storeTripFile(Trip trip, FileCategory category, MultipartFile file) throws IOException {
        String extension = extractExtension(file.getOriginalFilename());
        String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMddHHmmss"));
        String fileName = "%s_%s_%s%s".formatted(
                category.name().toLowerCase(),
                timestamp,
                UUID.randomUUID().toString().substring(0, 8),
                extension);

        Path tripDirectory = storageRootPath.resolve("trip-" + trip.getId());
        Files.createDirectories(tripDirectory);
        Path target = tripDirectory.resolve(fileName);
        file.transferTo(target);

        UploadedFile uploadedFile = new UploadedFile();
        uploadedFile.setTrip(trip);
        uploadedFile.setFileCategory(category);
        uploadedFile.setOriginalFileName(file.getOriginalFilename() == null ? fileName : file.getOriginalFilename());
        uploadedFile.setStoragePath(target.toString());
        uploadedFile.setFileSize(file.getSize());
        uploadedFile.setMimeType(file.getContentType() == null ? "application/octet-stream" : file.getContentType());
        return uploadedFileRepository.save(uploadedFile);
    }

    public Path resolvePath(UploadedFile file) {
        return Path.of(file.getStoragePath()).toAbsolutePath().normalize();
    }

    public byte[] readBytes(UploadedFile file) throws IOException {
        return Files.readAllBytes(resolvePath(file));
    }

    public void deleteStoredFile(UploadedFile file) throws IOException {
        Files.deleteIfExists(resolvePath(file));
    }

    public String storageRoot() {
        return appProperties.getStorageRoot();
    }

    private String extractExtension(String originalFileName) {
        if (originalFileName == null || !originalFileName.contains(".")) {
            return "";
        }
        return originalFileName.substring(originalFileName.lastIndexOf('.'));
    }
}
