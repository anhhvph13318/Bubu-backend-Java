package com.example.bububackend.controller;

import com.example.bububackend.DTO.CreateOrderRequest;
import com.example.bububackend.DTO.UpdateOrderStatusDTO;
import com.example.bububackend.model.Order;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.OrderService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpSession;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @GetMapping
    public ResponseEntity<ApiResponse<List<Order>>> getAlOrders() {

        try {
            List<Order> orders = orderService.getAllOrders();

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            orders,
                            true,
                            null,
                            null
                    )
            );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // POST /api/orders - tạo đơn hàng (trả 201 cùng đơn vừa tạo, có orderCode).
    // Đã đăng nhập thì đơn gắn với tài khoản (lấy từ session); chưa đăng nhập thì là khách vãng lai (accountId = null).
    // KHÔNG gửi accountId trong body: server tự lấy.
    // body: {"customerName":"...", "phone":"...", "address":"...", "note":"...", "paymentMethod":0,
    //        "items":[{"productDetailId":5,"quantity":2}]}

    @PostMapping
    public ResponseEntity<ApiResponse<Order>> createOrder(
            @RequestBody CreateOrderRequest request,
            HttpServletRequest http) {
        try {
            Order order = orderService.createOrder(
                    request,
                    currentAccountId(http)
            );

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                            new ApiResponse<>(
                                    order,
                                    true,
                                    null,
                                    null
                            )
                    );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // PUT /api/orders/{id} - đổi trạng thái đơn. body: {"status": 1}
    // 0 chờ xác nhận, 1 đã xác nhận, 2 đang giao, 3 hoàn thành, 4 đã hủy (hủy sẽ cộng kho lại)
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Order>> updateStatus(@PathVariable int id,
                                                           @RequestBody UpdateOrderStatusDTO request) {

        try {
            Order order = orderService.updateStatus(id, request.getStatus());

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            order,
                            true,
                            null,
                            null
                    )
            );

        } catch (ResponseStatusException e) {
            // Giữ đúng mã lỗi (400, 404...) và thông báo tiếng Việt
            return ResponseEntity
                    .status(e.getStatusCode())
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getReason(),
                                    e.getClass().getSimpleName()
                            )
                    );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // accountId của phiên đăng nhập (khóa "accountId" do AuthController lưu khi đăng nhập), null nếu chưa đăng nhập
    private Integer currentAccountId(HttpServletRequest http) {
        HttpSession session = http.getSession(false);
        return session == null ? null : (Integer) session.getAttribute("accountId");
    }
}