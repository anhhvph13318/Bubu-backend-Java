package com.example.bububackend.controller;

import com.example.bububackend.config.AuthInterceptor;
import com.example.bububackend.model.Account;
import com.example.bububackend.model.LoginRequest;
import com.example.bububackend.model.LoginResponse;
import com.example.bububackend.model.RegisterRequest;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.AccountService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AccountService accountService;

    public AuthController(AccountService accountService) {
        this.accountService = accountService;
    }

    // Đăng ký: luôn tạo tài khoản khách (CUSTOMER), không tự đăng nhập
    @PostMapping("/register")
    public ResponseEntity<ApiResponse<LoginResponse>> register(
            @RequestBody RegisterRequest request) {
        try {
            LoginResponse response = toResponse(accountService.register(request));

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
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



    @PostMapping("/login")
    public ResponseEntity<ApiResponse<LoginResponse>> login(
            @RequestBody LoginRequest request,
            HttpServletRequest http) {
        try {
            Account account = accountService.login(
                    request.getUsername(),
                    request.getPassword()
            );

            startSession(http, account);

            LoginResponse response = toResponse(account);

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

    @PostMapping("/logout")
    public void logout(HttpServletRequest http) {
        HttpSession session = http.getSession(false);
        if (session != null) {
            session.invalidate();
        }
    }

    // Thông tin tài khoản đang đăng nhập (theo session)
    @GetMapping("/me")
    public LoginResponse me(HttpServletRequest http) {
        HttpSession session = http.getSession(false);
        Integer accountId = session == null ? null
                : (Integer) session.getAttribute(AuthInterceptor.SESSION_ACCOUNT_ID);
        if (accountId == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Vui lòng đăng nhập");
        }
        Account account = accountService.getById(accountId);
        if (!account.isActive()) {
            session.invalidate();
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa");
        }
        return toResponse(account);
    }

    // Hủy phiên cũ rồi tạo phiên mới (tránh dùng lại session id cũ), lưu accountId và role
    private void startSession(HttpServletRequest http, Account account) {
        HttpSession old = http.getSession(false);
        if (old != null) {
            old.invalidate();
        }
        HttpSession session = http.getSession(true);
        session.setAttribute(AuthInterceptor.SESSION_ACCOUNT_ID, account.getId());
        session.setAttribute(AuthInterceptor.SESSION_ROLE, account.getRole());
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