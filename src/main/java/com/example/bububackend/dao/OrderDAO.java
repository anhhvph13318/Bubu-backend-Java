package com.example.bububackend.dao;

import com.example.bububackend.model.Order;
import com.example.bububackend.model.Product;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import org.springframework.jdbc.core.JdbcTemplate;

import java.util.List;

@Repository
public class OrderDAO {
    private final JdbcTemplate jdbcTemplate;

    public OrderDAO(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }
    public List<Order> findAll() {
        String  sql = """
                SELECT p.Id,
                       p.ordercode,
                       p.customerName,
                       p.phone,
                       p.address,
                       p.note,
                       p.totalAmount,
                       p.paymentMethod,
                       p.paymentStatus,
                       p.status,
                       p.createdAt
                From Orders p
                ORDER BY p.id DESC
        """;
        return jdbcTemplate.query(sql, (rs, rowNum) -> {

            Order p = new Order();

            p.setId(rs.getInt("Id"));
            p.setOrdercode(rs.getString("Ordercode"));
            p.setCustomerName(rs.getString("CustomerName"));
            p.setPhone(rs.getString("phone"));
            p.setAddress(rs.getString("address"));
            p.setNote(rs.getString("note"));
            p.setTotalAmount(rs.getBigDecimal("totalAmount"));
            p.setPaymentMethod(rs.getInt("paymentMethod"));
            p.setPaymentStatus(rs.getInt("paymentStatus"));
            p.setStatus(rs.getInt("status"));
            p.setCreatedAt(rs.getTimestamp("createdAt").toLocalDateTime());
            return p;
        });
    }
}
