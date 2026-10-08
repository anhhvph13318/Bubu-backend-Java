package com.example.bububackend.controller;

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

    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Order>> updateStatus(
            @PathVariable int id) {

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