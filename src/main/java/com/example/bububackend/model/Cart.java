package com.example.bububackend.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

// Giỏ hàng của một tài khoản khách đã đăng nhập (mỗi tài khoản đúng 1 giỏ)
@Entity
@Table(name = "`Cart`")
public class Cart {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`AccountId`")
    private int accountId;

    @Column(name = "`CreatedAt`")
    private LocalDateTime createdAt;

    @Column(name = "`UpdatedAt`")
    private LocalDateTime updatedAt;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getAccountId() { return accountId; }
    public void setAccountId(int accountId) { this.accountId = accountId; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}