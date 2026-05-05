package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.LodgingFormInstance;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LodgingFormInstanceRepository extends JpaRepository<LodgingFormInstance, Long> {

    Optional<LodgingFormInstance> findByTripId(Long tripId);
}
