package com.example.bububackend.DTO;

// Một dòng sản phẩm gửi lên: biến thể sản phẩm (size + màu) và số lượng.
// Dùng chung cho giỏ hàng (thêm / gộp / xem giá) và tạo đơn hàng.
public record ItemRequest(int productDetailId, int quantity) {
}