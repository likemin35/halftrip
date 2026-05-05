package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.UploadedFile;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UploadedFileRepository extends JpaRepository<UploadedFile, Long> {

    List<UploadedFile> findByTripIdOrderByCreatedAtAsc(Long tripId);
}

