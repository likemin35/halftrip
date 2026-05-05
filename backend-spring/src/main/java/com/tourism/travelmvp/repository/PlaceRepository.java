package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.Place;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface PlaceRepository extends JpaRepository<Place, Long> {

    List<Place> findByRegionIdOrderById(Long regionId);
}

