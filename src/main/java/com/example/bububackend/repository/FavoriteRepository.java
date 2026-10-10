package com.example.bububackend.repository;

import com.example.bububackend.model.Favorite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface FavoriteRepository extends JpaRepository<Favorite, Integer> {

    // Yêu thích của một tài khoản, mới thêm lên đầu
    List<Favorite> findByAccountIdOrderByCreatedAtDescIdDesc(int accountId);

    boolean existsByAccountIdAndProductId(int accountId, int productId);

    long countByAccountId(int accountId);

    // Chỉ lấy id sản phẩm (để app tô màu trái tim), mới thêm lên đầu
    @Query("select f.productId from Favorite f where f.accountId = :accountId order by f.createdAt desc, f.id desc")
    List<Integer> findProductIdsByAccountId(@Param("accountId") int accountId);

    // Bỏ thích: trả về số dòng đã xóa (0 = vốn chưa thích, không phải lỗi)
    @Modifying
    @Query("delete from Favorite f where f.accountId = :accountId and f.productId = :productId")
    int removeFavorite(@Param("accountId") int accountId, @Param("productId") int productId);
}