package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.Trip;
import java.time.LocalDate;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TripRepository extends JpaRepository<Trip, Long> {

    List<Trip> findByUserIdOrderByStartDateDesc(Long userId);

    List<Trip> findByEndDateLessThanEqualAndSettlementAppliedFalse(LocalDate date);
}

