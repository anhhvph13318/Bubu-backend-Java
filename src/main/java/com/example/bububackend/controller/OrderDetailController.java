package com.example.bububackend.controller;

import com.example.bububackend.DTO.OrderDetailDTO;
import com.example.bububackend.service.OrderDetailService;
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
    public List<OrderDetailDTO> getOrderDetailsByOrderId(
            @PathVariable int orderId) {

        return orderDetailService.getOrderDetailsByOrderId(orderId);
    }
}

