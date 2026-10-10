package com.example.bububackend.repository;

import com.example.bububackend.model.Order;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface OrderRepository extends JpaRepository<Order, Integer> {

    // Khóa dòng đơn hàng khi đổi trạng thái: hai người cùng bấm hủy một đơn thì chỉ một người được cộng kho lại
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select o from Order o where o.id = :id")
    Optional<Order> findByIdForUpdate(@Param("id") int id);

    // Lịch sử đơn của một tài khoản, mới nhất trước
    List<Order> findByAccountIdOrderByCreatedAtDescIdDesc(Integer accountId);

    // Mã tra cứu của khách
    boolean existsByTrackingCode(String trackingCode);

    Optional<Order> findByTrackingCode(String trackingCode);
}