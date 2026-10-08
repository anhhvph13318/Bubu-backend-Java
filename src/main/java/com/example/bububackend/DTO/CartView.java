package com.example.bububackend.DTO;

import java.math.BigDecimal;
import java.util.List;

// Giỏ hàng trả cho trang bán hàng. hasIssues = true khi có dòng hết hàng / vượt tồn kho.
public record CartView(List<CartLineView> items, int totalQuantity, BigDecimal totalAmount, boolean hasIssues) {
}