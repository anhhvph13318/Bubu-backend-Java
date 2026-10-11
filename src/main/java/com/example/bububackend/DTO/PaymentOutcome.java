package com.example.bububackend.DTO;

// Kết quả xử lý một thông báo thanh toán online.
public enum PaymentOutcome {
    PAID,                // thanh toán thành công, đã ghi nhận
    ALREADY_PAID,        // đã ghi nhận từ trước (thông báo lặp lại)
    PAID_BUT_CANCELLED,  // đã nhận tiền nhưng đơn đã bị hủy: cần hoàn tiền cho khách
    FAILED_CANCELLED,    // thanh toán thất bại, đơn bị hủy và kho được cộng lại
    FAILED_NO_CHANGE,    // thanh toán thất bại, đơn không còn ở trạng thái hủy được nên giữ nguyên
    INVALID_SIGNATURE,   // sai chữ ký
    NOT_FOUND,           // không tìm thấy đơn
    AMOUNT_MISMATCH      // số tiền không khớp
}