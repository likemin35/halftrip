package com.tourism.travelmvp.controller;

import com.tourism.travelmvp.dto.ApiResponse;
import com.tourism.travelmvp.dto.RegionDtos;
import com.tourism.travelmvp.service.RegionService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/regions")
@RequiredArgsConstructor
public class RegionController {

    private final RegionService regionService;

    @GetMapping
    public ApiResponse<List<RegionDtos.RegionSummary>> getRegions(@RequestParam(required = false) String residence) {
        return ApiResponse.ok(regionService.getRegions(residence));
    }

    @GetMapping("/{regionId}")
    public ApiResponse<RegionDtos.RegionDetail> getRegionDetail(
            @PathVariable Long regionId,
            @RequestParam(required = false) String residence
    ) {
        return ApiResponse.ok(regionService.getRegionDetail(regionId, residence));
    }
}

