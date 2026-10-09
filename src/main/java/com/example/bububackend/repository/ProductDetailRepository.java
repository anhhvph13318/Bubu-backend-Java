package com.example.bububackend.repository;

import com.example.bububackend.DTO.CartProductRow;
import com.example.bububackend.model.ProductDetail;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Collection;
import java.util.List;

public interface ProductDetailRepository extends JpaRepository<ProductDetail, Integer> {
    List<ProductDetail> findByProductId(int productId);

    // Dùng để chặn xóa size / màu đang có biến thể sử dụng
    boolean existsBySizeId(int sizeId);

    boolean existsByColorId(int colorId);

    // Thông tin đầy đủ (tên sản phẩm, giá, size, màu, tồn kho) của các biến thể theo id - dùng cho giỏ hàng và đặt hàng.
    // Yêu cầu entity Product có field name và price.
    @Query("select new com.example.bububackend.DTO.CartProductRow(d.id, d.productId, p.name, p.price, s.name, c.name, c.hexCode, d.quantity) "
            + "from ProductDetail d join Product p on p.id = d.productId "
            + "join Size s on s.id = d.sizeId join Color c on c.id = d.colorId "
            + "where d.id in :ids")
    List<CartProductRow> findCartRows(@Param("ids") Collection<Integer> ids);

    // Trừ kho NGUYÊN TỬ: chỉ trừ khi còn đủ hàng. Trả về số dòng đã cập nhật (0 = không đủ hàng).
    @Modifying
    @Query("update ProductDetail d set d.quantity = d.quantity - :qty where d.id = :id and d.quantity >= :qty")
    int decreaseStock(@Param("id") int id, @Param("qty") int qty);

    // Cộng kho lại (khi hủy đơn)
    @Modifying
    @Query("update ProductDetail d set d.quantity = d.quantity + :qty where d.id = :id")
    int increaseStock(@Param("id") int id, @Param("qty") int qty);

    // Xóa toàn bộ biến thể của một sản phẩm (gọi trước khi xóa sản phẩm)
    @Transactional
    void deleteByProductId(int productId);
}