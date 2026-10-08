package com.example.bububackend.DTO;

// Thông tin một biến thể sản phẩm gom từ nhiều bảng (ProductDetail + Product + Size + Color).
// price để kiểu Object vì chưa biết Product.price là BigDecimal hay double; CartService đổi sang BigDecimal.
public record CartProductRow(int detailId, int productId, String productName, Object price,
                             String sizeName, String colorName, String colorHex, int stock) {
}