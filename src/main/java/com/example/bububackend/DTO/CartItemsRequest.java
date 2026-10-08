package com.example.bububackend.DTO;

import java.util.List;

// Danh sách dòng sản phẩm: giỏ ở localStorage của khách (gộp khi đăng nhập, hoặc xem giá khi chưa đăng nhập)
public record CartItemsRequest(List<ItemRequest> items) {
}