package com.example.bububackend.DTO;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

// Trạng thái đích khi đổi trạng thái đơn: 0 chờ xác nhận, 1 đã xác nhận, 2 đang giao, 3 hoàn thành, 4 đã hủy
@JsonIgnoreProperties(ignoreUnknown = true)
public class UpdateOrderStatusDTO {

    private int status;

    public int getStatus() {
        return status;
    }

    public void setStatus(int status) {
        this.status = status;
    }
}