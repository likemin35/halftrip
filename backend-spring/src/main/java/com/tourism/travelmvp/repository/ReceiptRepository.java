package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.Receipt;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface ReceiptRepository extends JpaRepository<Receipt, Long> {

    List<Receipt> findByUploadedFileTripIdOrderByCreatedAtAsc(Long tripId);

    Optional<Receipt> findByUploadedFileId(Long uploadedFileId);
}

