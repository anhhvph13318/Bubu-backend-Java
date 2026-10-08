package com.example.bububackend.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

// Một dòng trong giỏ: một biến thể sản phẩm (size + màu) và số lượng
@Entity
@Table(name = "`CartItem`")
public class CartItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`CartId`")
    private int cartId;

    @Column(name = "`ProductDetailId`")
    private int productDetailId;

    @Column(name = "`Quantity`")
    private int quantity;

    @Column(name = "`CreatedAt`")
    private LocalDateTime createdAt;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getCartId() { return cartId; }
    public void setCartId(int cartId) { this.cartId = cartId; }

    public int getProductDetailId() { return productDetailId; }
    public void setProductDetailId(int productDetailId) { this.productDetailId = productDetailId; }

    public int getQuantity() { return quantity; }
    public void setQuantity(int quantity) { this.quantity = quantity; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}