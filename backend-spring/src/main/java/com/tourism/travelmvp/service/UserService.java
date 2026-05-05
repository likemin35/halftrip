package com.tourism.travelmvp.service;

import com.tourism.travelmvp.dto.RegionDtos;
import com.tourism.travelmvp.dto.UserDtos;
import com.tourism.travelmvp.entity.Region;
import com.tourism.travelmvp.entity.User;
import com.tourism.travelmvp.entity.UserFavoriteRegion;
import com.tourism.travelmvp.entity.UserNotificationSetting;
import com.tourism.travelmvp.exception.NotFoundException;
import com.tourism.travelmvp.repository.RegionRepository;
import com.tourism.travelmvp.repository.UserFavoriteRegionRepository;
import com.tourism.travelmvp.repository.UserNotificationSettingRepository;
import com.tourism.travelmvp.repository.UserRepository;
import java.util.List;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class UserService {

    private final UserRepository userRepository;
    private final UserNotificationSettingRepository settingRepository;
    private final UserFavoriteRegionRepository favoriteRegionRepository;
    private final RegionRepository regionRepository;

    @Transactional(readOnly = true)
    public UserDtos.UserProfileResponse getUser(Long userId) {
        User user = findUser(userId);
        UserNotificationSetting settings = settingRepository.findByUser(user)
                .orElseThrow(() -> new NotFoundException("Notification settings not found"));
        List<RegionDtos.RegionSummary> favoriteRegions = favoriteRegionRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(UserFavoriteRegion::getRegion)
                .map(region -> TripMapper.toRegionSummary(region, true))
                .toList();
        return new UserDtos.UserProfileResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getPhoneNumber(),
                user.getResidence(),
                user.getAuthProvider().name(),
                new UserDtos.NotificationSettingsResponse(
                        settings.getFavoriteRegionPreopenAlert(),
                        settings.getTripEndSettlementAlert()),
                favoriteRegions);
    }

    @Transactional
    public UserDtos.NotificationSettingsResponse updateNotificationSettings(
            Long userId,
            UserDtos.NotificationSettingsRequest request
    ) {
        User user = findUser(userId);
        UserNotificationSetting settings = settingRepository.findByUser(user)
                .orElseGet(() -> {
                    UserNotificationSetting newSetting = new UserNotificationSetting();
                    newSetting.setUser(user);
                    return newSetting;
                });
        settings.setFavoriteRegionPreopenAlert(Boolean.TRUE.equals(request.favoriteRegionPreopenAlert()));
        settings.setTripEndSettlementAlert(Boolean.TRUE.equals(request.tripEndSettlementAlert()));
        settings = settingRepository.save(settings);
        return new UserDtos.NotificationSettingsResponse(
                settings.getFavoriteRegionPreopenAlert(),
                settings.getTripEndSettlementAlert());
    }

    @Transactional
    public List<RegionDtos.RegionSummary> addFavoriteRegion(Long userId, UserDtos.FavoriteRegionRequest request) {
        User user = findUser(userId);
        Region region = regionRepository.findById(request.regionId())
                .orElseThrow(() -> new NotFoundException("Region not found"));
        favoriteRegionRepository.findByUserIdAndRegionId(userId, request.regionId())
                .orElseGet(() -> {
                    UserFavoriteRegion favorite = new UserFavoriteRegion();
                    favorite.setUser(user);
                    favorite.setRegion(region);
                    return favoriteRegionRepository.save(favorite);
                });
        return getFavoriteRegions(userId);
    }

    @Transactional
    public List<RegionDtos.RegionSummary> removeFavoriteRegion(Long userId, Long regionId) {
        findUser(userId);
        favoriteRegionRepository.deleteByUserIdAndRegionId(userId, regionId);
        return getFavoriteRegions(userId);
    }

    @Transactional(readOnly = true)
    public List<RegionDtos.RegionSummary> getFavoriteRegions(Long userId) {
        return favoriteRegionRepository.findByUserIdOrderByCreatedAtAsc(userId).stream()
                .map(UserFavoriteRegion::getRegion)
                .map(region -> TripMapper.toRegionSummary(region, true))
                .toList();
    }

    public User findUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new NotFoundException("User not found"));
    }
}
