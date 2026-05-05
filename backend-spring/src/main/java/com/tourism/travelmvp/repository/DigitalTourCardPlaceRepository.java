package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.DigitalTourCardPlace;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DigitalTourCardPlaceRepository extends JpaRepository<DigitalTourCardPlace, Long> {

    List<DigitalTourCardPlace> findByRegionIdOrderById(Long regionId);
}

