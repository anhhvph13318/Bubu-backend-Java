package com.example.bububackend.repository;

import com.example.bububackend.model.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Integer> {
    boolean existsByUserNameIgnoreCase(String userName);
    boolean existsByEmailIgnoreCase(String email);

    // Số tài khoản đang hoạt động - dùng để không cho khóa / xóa tài khoản hoạt động cuối cùng
    long countByActiveTrueAndRole(String role);

    Optional<Account> findByUserName(String userName);
}