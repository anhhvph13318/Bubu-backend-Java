package com.example.bububackend.model;

// Thông tin một ảnh (không kèm nội dung ảnh) - dùng để trả danh sách ảnh cho giao diện.
// Nội dung ảnh lấy riêng qua GET /api/images/{id}/file
public record ImageInfo(int id, int productId, String fileName, String imageUrl ,boolean main, int sortOrder, int version ) {
}