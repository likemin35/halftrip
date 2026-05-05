package com.tourism.travelmvp.controller;

import com.tourism.travelmvp.dto.ApiResponse;
import com.tourism.travelmvp.dto.RegionDtos;
import com.tourism.travelmvp.dto.UserDtos;
import com.tourism.travelmvp.service.UserService;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @GetMapping("/{userId}")
    public ApiResponse<UserDtos.UserProfileResponse> getUser(@PathVariable Long userId) {
        return ApiResponse.ok(userService.getUser(userId));
    }

    @PutMapping("/{userId}/notification-settings")
    public ApiResponse<UserDtos.NotificationSettingsResponse> updateNotificationSettings(
            @PathVariable Long userId,
            @RequestBody UserDtos.NotificationSettingsRequest request
    ) {
        return ApiResponse.ok(userService.updateNotificationSettings(userId, request));
    }

    @PostMapping("/{userId}/favorite-regions")
    public ApiResponse<List<RegionDtos.RegionSummary>> addFavoriteRegion(
            @PathVariable Long userId,
            @RequestBody UserDtos.FavoriteRegionRequest request
    ) {
        return ApiResponse.ok(userService.addFavoriteRegion(userId, request));
    }

    @DeleteMapping("/{userId}/favorite-regions/{regionId}")
    public ApiResponse<List<RegionDtos.RegionSummary>> removeFavoriteRegion(
            @PathVariable Long userId,
            @PathVariable Long regionId
    ) {
        return ApiResponse.ok(userService.removeFavoriteRegion(userId, regionId));
    }

    @GetMapping("/{userId}/favorite-regions")
    public ApiResponse<List<RegionDtos.RegionSummary>> getFavoriteRegions(@PathVariable Long userId) {
        return ApiResponse.ok(userService.getFavoriteRegions(userId));
    }
}
