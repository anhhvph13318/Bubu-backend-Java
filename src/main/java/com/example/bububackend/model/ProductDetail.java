package com.example.bububackend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "`ProductDetail`")
public class ProductDetail {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`ProductId`")
    private int productId;

    @Column(name = "`Size`")
    private int size;

    @Column(name = "`Color`")
    private String color;

    @Column(name = "`Quantity`")
    private int quantity;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public int getProductId() {
        return productId;
    }

    public void setProductId(int productId) {
        this.productId = productId;
    }

    public int getSize() {
        return size;
    }

    public void setSize(int size) {
        this.size = size;
    }

    public String getColor() {
        return color;
    }

    public void setColor(String color) {
        this.color = color;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }
}