package com.example.bububackend.DTO;

import java.math.BigDecimal;

// Một dòng trong giỏ để hiển thị cho khách.
// available = false nghĩa là dòng này hết hàng / vượt tồn kho (message nói rõ lý do).
public record CartLineView(int productDetailId, int productId, String productName, String imageUrl,
                           String sizeName, String colorName, String colorHex,
                           BigDecimal unitPrice, int quantity, int stock, BigDecimal lineTotal,
                           boolean available, String message) {
}