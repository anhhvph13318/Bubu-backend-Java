package com.example.bububackend.controller;

import com.example.bububackend.DTO.UpdateOrderStatusDTO;
import com.example.bububackend.model.Order;
import com.example.bububackend.service.OrderService;
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
    public List<Order> getAlOrders() {
        return orderService.getAllOrders();
    }

    @PutMapping("/{id}")
    public Order updateStatus(@PathVariable int id) {
        return orderService.updateStatus(id);
    }
}