package com.tourism.travelmvp.dto;

public final class AuthDtos {

    private AuthDtos() {
    }

    public record MockLoginRequest(String provider, String email, String name) {
    }

    public record LocalSignUpRequest(
            String name,
            String loginId,
            String password,
            String phoneNumber,
            String residence
    ) {
    }

    public record LocalLoginRequest(String loginId, String password) {
    }

    public record AuthResponse(Long userId, String name, String email, String provider, String mockToken) {
    }
}
