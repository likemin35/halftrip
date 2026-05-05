package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.LodgingInfo;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LodgingInfoRepository extends JpaRepository<LodgingInfo, Long> {

    Optional<LodgingInfo> findByTripId(Long tripId);
}

