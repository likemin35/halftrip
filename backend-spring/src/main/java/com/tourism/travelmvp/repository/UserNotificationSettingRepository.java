package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.User;
import com.tourism.travelmvp.entity.UserNotificationSetting;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserNotificationSettingRepository extends JpaRepository<UserNotificationSetting, Long> {

    Optional<UserNotificationSetting> findByUser(User user);
}

