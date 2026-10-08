package com.example.bububackend.repository;

import com.example.bububackend.model.Image;
import com.example.bububackend.model.ImageInfo;
import jakarta.transaction.Transactional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ImageRepository extends JpaRepository<Image, Integer> {

    // Danh sách ảnh chỉ lấy thông tin, KHÔNG tải nội dung ảnh (nhẹ)
    @Query("select new com.example.bububackend.model.ImageInfo(i.id, i.productId, i.fileName, '' , i.main, i.sortOrder, i.version) "
            + "from Image i order by i.productId, i.sortOrder, i.id")
    List<ImageInfo> findAllInfo();

    @Query("select new com.example.bububackend.model.ImageInfo(i.id, i.productId, i.fileName, '' , i.main, i.sortOrder, i.version) "
            + "from Image i where i.productId = :productId order by i.sortOrder, i.id")
    List<ImageInfo> findInfoByProductId(@Param("productId") int productId);

    List<Image> findByProductIdOrderBySortOrderAscIdAsc(int productId);

    long countByProductId(int productId);

    boolean existsByProductIdAndMainTrue(int productId);

    // Ảnh đại diện (nếu chưa có thì lấy ảnh đầu tiên)
    Optional<Image> findFirstByProductIdAndMainTrue(int productId);

    Optional<Image> findFirstByProductIdOrderBySortOrderAscIdAsc(int productId);

    @Modifying
    @Query("update Image i set i.main = false where i.productId = :productId")
    void clearMain(@Param("productId") int productId);

    @Modifying
    @Query("update Image i set i.main = true where i.id = :id")
    void markMain(@Param("id") int id);

    // Xóa toàn bộ ảnh của một sản phẩm
    @Transactional
    void deleteByProductId(int productId);
}