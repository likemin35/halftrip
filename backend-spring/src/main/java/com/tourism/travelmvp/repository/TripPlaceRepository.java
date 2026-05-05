package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.TripPlace;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface TripPlaceRepository extends JpaRepository<TripPlace, Long> {

    List<TripPlace> findByTripIdOrderByVisitOrderAsc(Long tripId);
}

