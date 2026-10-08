package com.example.bububackend.controller;

import com.example.bububackend.model.Account;
import com.example.bububackend.model.LoginRequest;
import com.example.bububackend.model.LoginResponse;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.AccountService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AccountService accountService;

    public AuthController(AccountService accountService) {
        this.accountService = accountService;
    }

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @RequestBody LoginRequest request) {

        try {
            Account account = accountService.login(
                    request.getUsername(),
                    request.getPassword()
            );

            LoginResponse response = new LoginResponse(
                    account.getId(),
                    account.getUserName(),
                    account.getFullName(),
                    account.isActive()
            );

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            response,
                            true,
                            null,
                            null
                    )
            );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }
}