package com.example.bububackend.controller;

import com.example.bububackend.model.Account;
import com.example.bububackend.model.AccountRequest;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.AccountService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/accounts")
public class AccountController {
    private final AccountService accountService;
    public AccountController(AccountService accountService) {
        this.accountService = accountService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Account>>> findAll() {
        try {
            List<Account> accounts = accountService.findAll();

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            accounts,
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
    @PostMapping
    public ResponseEntity<ApiResponse<Account>> createAccount(@RequestBody AccountRequest request) {

        try {
            Account account = accountService.createAccount(request);

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                            new ApiResponse<>(
                                    account,
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
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Account>> updateAccount(@PathVariable int id, @RequestBody AccountRequest request) {

        try {
            Account account = accountService.edit(id, request);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            account,
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
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteAccount(@PathVariable int id) {

        try {
            accountService.deleteAccount(id);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            null,
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
