package com.tourism.travelmvp.service;

import com.tourism.travelmvp.dto.RegionDtos;
import com.tourism.travelmvp.entity.Region;
import com.tourism.travelmvp.exception.NotFoundException;
import com.tourism.travelmvp.repository.DigitalTourCardPlaceRepository;
import com.tourism.travelmvp.repository.MerchantRepository;
import com.tourism.travelmvp.repository.OnlineMallRepository;
import com.tourism.travelmvp.repository.PlaceRepository;
import com.tourism.travelmvp.repository.RegionRepository;
import java.util.Arrays;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class RegionService {

    private final RegionRepository regionRepository;
    private final PlaceRepository placeRepository;
    private final DigitalTourCardPlaceRepository digitalTourCardPlaceRepository;
    private final MerchantRepository merchantRepository;
    private final OnlineMallRepository onlineMallRepository;

    @Transactional(readOnly = true)
    public List<RegionDtos.RegionSummary> getRegions(String residence) {
        List<Region> regions = regionRepository.findAll(Sort.by(
                Sort.Order.asc("displayOrder"),
                Sort.Order.asc("id")));
        return regions.stream()
                .map(region -> TripMapper.toRegionSummary(region, isAvailableForResidence(region, residence)))
                .filter(region -> residence == null || residence.isBlank() || region.matchedByResidence())
                .toList();
    }

    @Transactional(readOnly = true)
    public RegionDtos.RegionDetail getRegionDetail(Long regionId, String residence) {
        Region region = regionRepository.findById(regionId)
                .orElseThrow(() -> new NotFoundException("Region not found"));
        return new RegionDtos.RegionDetail(
                TripMapper.toRegionSummary(region, isAvailableForResidence(region, residence)),
                placeRepository.findByRegionIdOrderById(regionId).stream().map(TripMapper::toPlaceItem).toList(),
                digitalTourCardPlaceRepository.findByRegionIdOrderById(regionId).stream().map(TripMapper::toDigitalPlaceItem).toList(),
                merchantRepository.findByRegionIdOrderById(regionId).stream().map(TripMapper::toMerchantItem).toList(),
                onlineMallRepository.findByRegionIdOrderById(regionId).stream().map(TripMapper::toOnlineMallItem).toList());
    }

    private boolean isAvailableForResidence(Region region, String residence) {
        if (!Boolean.TRUE.equals(region.getEligibleForResidenceMatch())) {
            return true;
        }
        if (residence == null || residence.isBlank()) {
            return true;
        }
        String normalizedResidence = normalize(residence);
        if (normalizedResidence.isBlank()) {
            return true;
        }
        return Arrays.stream(nullToEmpty(region.getRestrictedResidenceTokens()).split(","))
                .map(String::trim)
                .filter(token -> !token.isBlank())
                .map(this::normalize)
                .noneMatch(normalizedResidence::contains);
    }

    private String normalize(String source) {
        return nullToEmpty(source).replace(" ", "").toLowerCase();
    }

    private String nullToEmpty(String source) {
        return source == null ? "" : source;
    }
}
