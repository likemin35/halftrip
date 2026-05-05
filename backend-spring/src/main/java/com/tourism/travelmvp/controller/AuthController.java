package com.tourism.travelmvp.controller;

import com.tourism.travelmvp.dto.ApiResponse;
import com.tourism.travelmvp.dto.AuthDtos;
import com.tourism.travelmvp.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/mock-login")
    public ApiResponse<AuthDtos.AuthResponse> mockLogin(@RequestBody AuthDtos.MockLoginRequest request) {
        return ApiResponse.ok(authService.mockLogin(request));
    }

    @PostMapping("/signup")
    public ApiResponse<AuthDtos.AuthResponse> signUp(@RequestBody AuthDtos.LocalSignUpRequest request) {
        return ApiResponse.ok(authService.signUp(request));
    }

    @PostMapping("/login")
    public ApiResponse<AuthDtos.AuthResponse> login(@RequestBody AuthDtos.LocalLoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }
}
