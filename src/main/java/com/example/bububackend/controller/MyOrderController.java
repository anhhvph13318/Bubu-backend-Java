package com.example.bububackend.controller;

import com.example.bububackend.DTO.MyOrderView;
import com.example.bububackend.config.AuthInterceptor;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.MyOrderService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// Lịch sử đơn hàng của chính khách đang đăng nhập (accountId lấy từ session, không nhận từ client).
// Lỗi (401, 404...) để Spring tự trả JSON có "message".
@RestController
@RequestMapping("/api/orders/my")
public class MyOrderController {

    private final MyOrderService service;

    public MyOrderController(MyOrderService service) {
        this.service = service;
    }

    // GET /api/orders/my - danh sách đơn của tôi, mới nhất trước
    @GetMapping
    public ResponseEntity<ApiResponse<List<MyOrderView>>> list(HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        return ResponseEntity.ok(new ApiResponse<>(service.list(accountId), true, null, null));
    }

    // GET /api/orders/my/{id} - chi tiết một đơn kèm sản phẩm
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<MyOrderView>> detail(@PathVariable int id, HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        return ResponseEntity.ok(new ApiResponse<>(service.get(accountId, id), true, null, null));
    }
}