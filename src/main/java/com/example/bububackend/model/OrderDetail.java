package com.example.bububackend.model;

import jakarta.persistence.*;

import java.math.BigDecimal;

@Entity
@Table(name = "`OrderDetail`")
public class OrderDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`OrderId`")
    private int orderId;

    @Column(name = "`ProductDetailId`")
    private int productDetailId;

    @Column(name = "`Quantity`")
    private int quantity;

    @Column(name = "`Price`")
    private BigDecimal price;


    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getOrderId() {
        return orderId;
    }

    public void setOrderId(int orderId) {
        this.orderId = orderId;
    }

    public int getProductDetailId() {
        return productDetailId;
    }

    public void setProductDetailId(int productDetailId) {
        this.productDetailId = productDetailId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }

    public BigDecimal getPrice() {
        return price;
    }

    public void setPrice(BigDecimal price) {
        this.price = price;
    }
}