package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.Merchant;
import java.util.List;
import org.springframework.data.jpa.repository.JpaRepository;

public interface MerchantRepository extends JpaRepository<Merchant, Long> {

    List<Merchant> findByRegionIdOrderById(Long regionId);
}

