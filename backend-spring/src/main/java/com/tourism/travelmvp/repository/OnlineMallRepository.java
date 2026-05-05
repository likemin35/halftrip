package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.OnlineMall;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface OnlineMallRepository extends JpaRepository<OnlineMall, Long> {

    List<OnlineMall> findByRegionIdOrderById(Long regionId);
}

