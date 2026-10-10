package com.example.bububackend.DTO;

import java.math.BigDecimal;
import java.time.LocalDateTime;

// Một sản phẩm yêu thích để hiển thị. Tên, giá, ảnh, tồn kho luôn lấy mới nhất từ database.
// totalQuantity = 0 nghĩa là hết hàng (app nên hiện "Hết hàng"). addedAt = null với khách chưa đăng nhập.
public record FavoriteView(int productId, String name, BigDecimal price, String imageUrl,
                           int totalQuantity, LocalDateTime addedAt) {
}