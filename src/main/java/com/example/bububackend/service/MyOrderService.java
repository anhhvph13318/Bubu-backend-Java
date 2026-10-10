package com.example.bububackend.service;

import com.example.bububackend.DTO.MyOrderView;
import com.example.bububackend.DTO.OrderDetailDTO;
import com.example.bububackend.model.Order;
import com.example.bububackend.repository.OrderRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Objects;

// Xem đơn hàng dành cho khách: lịch sử của khách đã đăng nhập và tra cứu bằng mã của khách vãng lai.
@Service
public class MyOrderService {

    private final OrderRepository orderRepository;
    private final OrderDetailService orderDetailService;

    public MyOrderService(OrderRepository orderRepository, OrderDetailService orderDetailService) {
        this.orderRepository = orderRepository;
        this.orderDetailService = orderDetailService;
    }

    // Danh sách đơn của tài khoản (chưa kèm sản phẩm)
    public List<MyOrderView> list(int accountId) {
        return orderRepository.findByAccountIdOrderByCreatedAtDescIdDesc(accountId).stream()
                .map(o -> toView(o, null, true))
                .toList();
    }

    // Chi tiết một đơn. Đơn không phải của tài khoản này thì coi như không tồn tại (404).
    public MyOrderView get(int accountId, int orderId) {
        Order order = orderRepository.findById(orderId)
                .filter(o -> Objects.equals(o.getAccountId(), accountId))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng"));
        return toView(order, orderDetailService.getOrderDetailsByOrderId(order.getId()), true);
    }

    // Khách (kể cả chưa đăng nhập) tra cứu đơn bằng mã tra cứu. Không cho hủy qua đường này.
    public MyOrderView track(String trackingCode) {
        String code = trackingCode == null ? "" : trackingCode.trim().toUpperCase().replaceAll("[\\s-]", "");
        if (code.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng với mã này");
        }
        Order order = orderRepository.findByTrackingCode(code)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng với mã này"));
        return toView(order, orderDetailService.getOrderDetailsByOrderId(order.getId()), false);
    }

    private MyOrderView toView(Order o, List<OrderDetailDTO> items, boolean allowCancel) {
        boolean canCancel = allowCancel
                && o.getStatus() == OrderService.STATUS_PENDING
                && o.getPaymentStatus() == 0;
        return new MyOrderView(
                o.getId(), o.getOrderCode(), o.getStatus(), OrderService.label(o.getStatus()),
                o.getPaymentMethod(), o.getPaymentStatus(), o.getTotalAmount(), o.getCreatedAt(),
                o.getCustomerName(), o.getPhone(), o.getAddress(), o.getNote(), canCancel, items);
    }
}