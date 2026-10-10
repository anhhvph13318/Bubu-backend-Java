package com.example.bububackend.controller;

import com.example.bububackend.DTO.MyOrderView;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.MyOrderService;
import com.example.bububackend.service.OrderService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

// Việc khách tự làm với đơn hàng: hủy đơn của mình, tra cứu đơn bằng mã.
// Lỗi (401, 404, 400) để Spring tự trả JSON có "message".
@RestController
@RequestMapping("/api/orders")
public class CustomerOrderController {

    private final OrderService orderService;
    private final MyOrderService myOrderService;

    public CustomerOrderController(OrderService orderService, MyOrderService myOrderService) {
        this.orderService = orderService;
        this.myOrderService = myOrderService;
    }

    // POST /api/orders/my/{id}/cancel - khách đã đăng nhập tự hủy đơn của mình (chỉ khi "Chờ xác nhận").
    // Trả lại đơn sau khi hủy.
    @PostMapping("/my/{id}/cancel")
    public ResponseEntity<ApiResponse<MyOrderView>> cancel(@PathVariable int id, HttpServletRequest http) {
        int accountId = currentAccountId(http);
        orderService.cancelByCustomer(accountId, id);
        return ResponseEntity.ok(new ApiResponse<>(myOrderService.get(accountId, id), true, null, null));
    }

    // GET /api/orders/track/{trackingCode} - công khai: khách nhập mã tra cứu (nhận khi đặt hàng) để xem đơn
    @GetMapping("/track/{trackingCode}")
    public ResponseEntity<ApiResponse<MyOrderView>> track(@PathVariable String trackingCode) {
        return ResponseEntity.ok(new ApiResponse<>(myOrderService.track(trackingCode), true, null, null));
    }

    // accountId của phiên đăng nhập (khóa "accountId" do AuthController lưu khi đăng nhập)
    private int currentAccountId(HttpServletRequest http) {
        HttpSession session = http.getSession(false);
        Integer id = session == null ? null : (Integer) session.getAttribute("accountId");
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Vui lòng đăng nhập");
        }
        return id;
    }
}