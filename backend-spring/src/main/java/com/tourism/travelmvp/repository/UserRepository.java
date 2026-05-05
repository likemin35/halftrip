package com.tourism.travelmvp.repository;

import com.tourism.travelmvp.entity.User;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserRepository extends JpaRepository<User, Long> {

    Optional<User> findByEmail(String email);

    Optional<User> findByLoginId(String loginId);

    boolean existsByLoginId(String loginId);
}
