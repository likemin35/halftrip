package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.UserFavoriteRegion;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserFavoriteRegionRepository extends JpaRepository<UserFavoriteRegion, Long> {

    List<UserFavoriteRegion> findByUserIdOrderByCreatedAtAsc(Long userId);

    Optional<UserFavoriteRegion> findByUserIdAndRegionId(Long userId, Long regionId);

    void deleteByUserIdAndRegionId(Long userId, Long regionId);
}
