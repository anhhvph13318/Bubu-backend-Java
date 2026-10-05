package com.example.bububackend.service;

import com.example.bububackend.dao.OrderDAO;
import com.example.bububackend.model.Order;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class OrderService {
    private final OrderDAO orderDAO;

    public OrderService(OrderDAO orderDAO) {
        this.orderDAO = orderDAO;
    }

    public List<Order> getAllOrders() {
        return orderDAO.findAll();
    }
}
