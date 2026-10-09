package com.example.bububackend.controller;

import com.example.bububackend.model.Account;
import com.example.bububackend.model.LoginRequest;
import com.example.bububackend.model.LoginResponse;
import com.example.bububackend.model.RegisterRequest;
import com.example.bububackend.service.AccountService;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AccountService accountService;

    public AuthController(AccountService accountService) {
        this.accountService = accountService;
    }

    // Đăng ký: luôn tạo tài khoản khách (CUSTOMER)
    @PostMapping("/register")
    @ResponseStatus(HttpStatus.CREATED)
    public LoginResponse register(@RequestBody RegisterRequest request) {
        return toResponse(accountService.register(request));
    }

    @PostMapping("/login")
    public LoginResponse login(@RequestBody LoginRequest request) {
        return toResponse(accountService.login(
                request.getUsername(),
                request.getPassword()
        ));
    }

    private LoginResponse toResponse(Account account) {
        return new LoginResponse(
                account.getId(),
                account.getUserName(),
                account.getFullName(),
                account.isActive(),
                account.getRole(),
                account.getEmail(),
                account.getPhone()
        );
    }
}