package com.example.bububackend.controller;

import com.example.bububackend.DTO.OrderDetailDTO;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.OrderDetailService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/order-details")
public class OrderDetailController {

    private final OrderDetailService orderDetailService;

    public OrderDetailController(OrderDetailService orderDetailService) {
        this.orderDetailService = orderDetailService;
    }

    @GetMapping("/order/{orderId}")
    public ResponseEntity<ApiResponse<List<OrderDetailDTO>>> getOrderDetailsByOrderId(
            @PathVariable int orderId) {

        try {
            List<OrderDetailDTO> orderDetails =
                    orderDetailService.getOrderDetailsByOrderId(orderId);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            orderDetails,
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

