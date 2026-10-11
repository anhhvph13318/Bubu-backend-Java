package com.example.bububackend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

// Mỗi phút tự hủy các đơn VNPay quá hạn thanh toán (cộng lại kho).
@Component
public class OnlinePaymentJob {

    private static final Logger log = LoggerFactory.getLogger(OnlinePaymentJob.class);

    private final OrderService orderService;

    public OnlinePaymentJob(OrderService orderService) {
        this.orderService = orderService;
    }

    @Scheduled(fixedDelay = 60_000, initialDelay = 30_000)
    public void cancelExpiredOrders() {
        try {
            int n = orderService.cancelExpiredOnlineOrders();
            if (n > 0) {
                log.info("Đã tự hủy {} đơn VNPay quá hạn thanh toán", n);
            }
        } catch (Exception e) {
            log.warn("Không hủy được đơn quá hạn: {}", e.getMessage());
        }
    }
}