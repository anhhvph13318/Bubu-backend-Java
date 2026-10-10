package com.example.bububackend.DTO;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

// Một đơn hàng hiển thị cho khách (lịch sử đơn và tra cứu bằng mã).
// items = null ở danh sách (GET /api/orders/my), có đủ sản phẩm ở chi tiết.
// canCancel = true khi khách được phép hủy (đơn "Chờ xác nhận", chưa thanh toán, và khách đã đăng nhập).
// paymentMethod: 0 = COD, 1 = VNPay. paymentStatus: 0 = chưa thanh toán, 1 = đã thanh toán.
// status: 0 chờ xác nhận, 1 đã xác nhận, 2 đang giao, 3 hoàn thành, 4 đã hủy (statusText là chữ tiếng Việt tương ứng).
public record MyOrderView(int id, String orderCode, int status, String statusText,
                          int paymentMethod, int paymentStatus, BigDecimal totalAmount,
                          LocalDateTime createdAt, String customerName, String phone,
                          String address, String note, boolean canCancel, List<OrderDetailDTO> items) {
}