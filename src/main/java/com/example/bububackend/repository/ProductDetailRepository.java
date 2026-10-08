package com.example.bububackend.repository;

import com.example.bububackend.model.ProductDetail;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ProductDetailRepository extends JpaRepository<ProductDetail, Integer> {
    List<ProductDetail> findByProductId(int productId);

    // Dùng để chặn xóa size / màu đang có biến thể sử dụng
    boolean existsBySizeId(int sizeId);

    boolean existsByColorId(int colorId);

    // Xóa toàn bộ biến thể của một sản phẩm (gọi trước khi xóa sản phẩm)
    @Transactional
    void deleteByProductId(int productId);
}