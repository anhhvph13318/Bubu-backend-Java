package com.example.bububackend.DTO;

import java.util.List;

// Danh sách id sản phẩm yêu thích: localStorage của khách (gộp khi đăng nhập, hoặc xem thông tin khi chưa đăng nhập)
public record FavoriteIdsRequest(List<Integer> productIds) {
}