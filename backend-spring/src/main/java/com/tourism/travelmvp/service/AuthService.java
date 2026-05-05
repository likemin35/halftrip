package com.tourism.travelmvp.service;

import com.tourism.travelmvp.dto.AuthDtos;
import com.tourism.travelmvp.entity.User;
import com.tourism.travelmvp.entity.UserNotificationSetting;
import com.tourism.travelmvp.enums.AuthProvider;
import com.tourism.travelmvp.exception.BadRequestException;
import com.tourism.travelmvp.repository.UserNotificationSettingRepository;
import com.tourism.travelmvp.repository.UserRepository;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.HexFormat;
import java.util.Locale;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@RequiredArgsConstructor
public class AuthService {

    private static final String DEFAULT_RESIDENCE = "대전광역시 중구";

    private final UserRepository userRepository;
    private final UserNotificationSettingRepository userNotificationSettingRepository;

    @Transactional
    public AuthDtos.AuthResponse mockLogin(AuthDtos.MockLoginRequest request) {
        AuthProvider provider = AuthProvider.valueOf(request.provider().toUpperCase(Locale.ROOT));
        User user = userRepository.findByEmail(request.email())
                .orElseGet(() -> {
                    User newUser = new User();
                    newUser.setEmail(request.email());
                    newUser.setName(request.name());
                    newUser.setAuthProvider(provider);
                    newUser.setOauthSubject("mock-" + provider.name().toLowerCase(Locale.ROOT));
                    newUser.setResidence(DEFAULT_RESIDENCE);
                    newUser.setPhoneNumber("010-0000-0000");
                    return userRepository.save(newUser);
                });

        user.setName(request.name());
        user.setAuthProvider(provider);
        user = userRepository.save(user);
        ensureNotificationSetting(user);

        return new AuthDtos.AuthResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getAuthProvider().name(),
                "mock-token-" + user.getId());
    }

    @Transactional
    public AuthDtos.AuthResponse signUp(AuthDtos.LocalSignUpRequest request) {
        String loginId = normalize(request.loginId());
        String password = request.password() == null ? "" : request.password().trim();
        String name = normalize(request.name());
        String phoneNumber = normalize(request.phoneNumber());
        String residence = normalize(request.residence());

        if (loginId.isEmpty()) {
            throw new BadRequestException("아이디를 입력해 주세요.");
        }
        if (password.length() < 4) {
            throw new BadRequestException("비밀번호는 4자 이상으로 입력해 주세요.");
        }
        if (name.isEmpty()) {
            throw new BadRequestException("이름을 입력해 주세요.");
        }
        if (residence.isEmpty()) {
            throw new BadRequestException("거주 지역을 선택해 주세요.");
        }
        if (userRepository.existsByLoginId(loginId)) {
            throw new BadRequestException("이미 사용 중인 아이디입니다.");
        }

        User user = new User();
        user.setName(name);
        user.setLoginId(loginId);
        user.setEmail(loginId + "@local.travel");
        user.setPasswordHash(hashPassword(password));
        user.setPhoneNumber(phoneNumber);
        user.setResidence(residence);
        user.setAuthProvider(AuthProvider.LOCAL);
        user.setOauthSubject(null);
        user = userRepository.save(user);
        ensureNotificationSetting(user);

        return new AuthDtos.AuthResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getAuthProvider().name(),
                "local-token-" + user.getId());
    }

    @Transactional(readOnly = true)
    public AuthDtos.AuthResponse login(AuthDtos.LocalLoginRequest request) {
        String loginId = normalize(request.loginId());
        String password = request.password() == null ? "" : request.password().trim();

        User user = userRepository.findByLoginId(loginId)
                .orElseThrow(() -> new BadRequestException("아이디 또는 비밀번호가 올바르지 않습니다."));

        if (user.getPasswordHash() == null || !user.getPasswordHash().equals(hashPassword(password))) {
            throw new BadRequestException("아이디 또는 비밀번호가 올바르지 않습니다.");
        }

        return new AuthDtos.AuthResponse(
                user.getId(),
                user.getName(),
                user.getEmail(),
                user.getAuthProvider().name(),
                "local-token-" + user.getId());
    }

    private void ensureNotificationSetting(User user) {
        if (userNotificationSettingRepository.findByUser(user).isPresent()) {
            return;
        }
        UserNotificationSetting setting = new UserNotificationSetting();
        setting.setUser(user);
        userNotificationSettingRepository.save(setting);
    }

    private String normalize(String value) {
        return value == null ? "" : value.trim();
    }

    private String hashPassword(String password) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(password.getBytes(StandardCharsets.UTF_8));
            return HexFormat.of().formatHex(hash);
        } catch (NoSuchAlgorithmException exception) {
            throw new IllegalStateException("SHA-256 algorithm not available", exception);
        }
    }
}
