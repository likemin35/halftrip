package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.Region;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface RegionRepository extends JpaRepository<Region, Long> {

    List<Region> findByProvinceContainingIgnoreCase(String province);
}

