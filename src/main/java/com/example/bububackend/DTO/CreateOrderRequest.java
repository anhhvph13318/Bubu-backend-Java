package com.example.bububackend.DTO;

import java.util.List;

// Dữ liệu tạo đơn hàng gửi lên từ trang bán hàng.
// paymentMethod: 0 = COD, 1 = VNPay. Giá KHÔNG gửi lên: server tự lấy giá hiện tại của sản phẩm.
public record CreateOrderRequest(String customerName, String phone, String address, String note,
                                 int paymentMethod, List<ItemRequest> items) {
}