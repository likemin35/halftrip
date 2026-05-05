package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.LodgingFormTemplate;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface LodgingFormTemplateRepository extends JpaRepository<LodgingFormTemplate, Long> {

    Optional<LodgingFormTemplate> findByRegionIdAndIsActiveTrue(Long regionId);
}
