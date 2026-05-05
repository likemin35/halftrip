package com.tourism.travelmvp.dto;

import java.util.List;

public final class UserDtos {

    private UserDtos() {
    }

    public record NotificationSettingsRequest(Boolean favoriteRegionPreopenAlert,
                                              Boolean tripEndSettlementAlert) {
    }

    public record NotificationSettingsResponse(Boolean favoriteRegionPreopenAlert,
                                               Boolean tripEndSettlementAlert) {
    }

    public record FavoriteRegionRequest(Long regionId) {
    }

    public record UserProfileResponse(Long id,
                                      String name,
                                      String email,
                                      String phoneNumber,
                                      String residence,
                                      String authProvider,
                                      NotificationSettingsResponse notificationSettings,
                                      List<RegionDtos.RegionSummary> favoriteRegions) {
    }
}

