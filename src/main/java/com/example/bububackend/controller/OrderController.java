package com.example.bububackend.controller;

import com.example.bububackend.model.Order;
import com.example.bububackend.model.Product;
import com.example.bububackend.service.OrderService;
import com.example.bububackend.service.ProductService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
}