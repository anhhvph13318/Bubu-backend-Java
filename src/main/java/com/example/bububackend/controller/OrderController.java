package com.example.bububackend.controller;

import com.example.bububackend.DTO.CreateOrderRequest;
import com.example.bububackend.DTO.UpdateOrderStatusDTO;
import com.example.bububackend.model.Order;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.OrderService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

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
    // body: {"customerName":"...", "phone":"...", "address":"...", "note":"...", "paymentMethod":0,
    //        "items":[{"productDetailId":5,"quantity":2}]}
    @PostMapping
    public ResponseEntity<Order> createOrder(@RequestBody CreateOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(orderService.createOrder(request));
    }

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Order>> updateStatus(@PathVariable int id) {

        try {
            Order order = orderService.updateStatus(id);

            return ResponseEntity.ok(
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
}