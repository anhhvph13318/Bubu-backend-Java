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

    // Khóa ngoại tới bảng Size / Color (tên size, màu lấy từ /api/sizes và /api/colors)
    @Column(name = "`SizeId`")
    private int sizeId;

    @Column(name = "`ColorId`")
    private int colorId;

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

    public int getSizeId() {
        return sizeId;
    }

    public void setSizeId(int sizeId) {
        this.sizeId = sizeId;
    }

    public int getColorId() {
        return colorId;
    }

    public void setColorId(int colorId) {
        this.colorId = colorId;
    }

    public int getQuantity() {
        return quantity;
    }

    public void setQuantity(int quantity) {
        this.quantity = quantity;
    }
}