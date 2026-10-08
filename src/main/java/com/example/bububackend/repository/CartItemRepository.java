package com.example.bububackend.repository;

import com.example.bububackend.model.CartItem;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface CartItemRepository extends JpaRepository<CartItem, Integer> {

    List<CartItem> findByCartIdOrderByIdAsc(int cartId);

    Optional<CartItem> findByCartIdAndProductDetailId(int cartId, int productDetailId);

    // Xóa sạch các dòng trong giỏ (giữ lại Cart rỗng để dùng lại)
    @Modifying
    @Query("delete from CartItem i where i.cartId = :cartId")
    void deleteAllByCartId(@Param("cartId") int cartId);
}