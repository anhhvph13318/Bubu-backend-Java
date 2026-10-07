package com.example.bububackend.repository;

import com.example.bububackend.model.Account;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface AccountRepository extends JpaRepository<Account, Integer> {
    boolean existsByUserNameIgnoreCase(String userName);
    // Số tài khoản đang hoạt động - dùng để không cho khóa / xóa tài khoản hoạt động cuối cùng
    long countByActiveTrue();

    Optional<Account> findByUserName(String userName);
}