package com.example.bububackend.dao;

import com.example.bububackend.model.Product;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class ProductDAO {

    private final JdbcTemplate jdbcTemplate;

    public ProductDAO(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Product> findAll() {

        String sql = """
                SELECT p.Id,
                       p.Code,
                       p.Name,
                       p.Price,
                       p.Description,
                       p.ImageUrl,
                       p.CategoryId,
                       c.Name AS CategoryName,
                       p.Status,
                       ISNULL(
                           (SELECT SUM(d.Quantity)
                            FROM ProductDetail d
                            WHERE d.ProductId = p.Id),
                           0
                       ) AS TotalQty
                FROM Product p
                JOIN Category c ON c.Id = p.CategoryId
                WHERE p.IsDeleted = 0
                ORDER BY p.Id DESC
                """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {

            Product p = new Product();

            p.setId(rs.getInt("Id"));
            p.setCode(rs.getString("Code"));
            p.setName(rs.getString("Name"));
            p.setPrice(rs.getBigDecimal("Price"));
            p.setDescription(rs.getString("Description"));
            p.setImageUrl(rs.getString("ImageUrl"));
            p.setCategoryId(rs.getInt("CategoryId"));
            p.setCategoryName(rs.getString("CategoryName"));
            p.setStatus(rs.getInt("Status"));
            p.setTotalQuantity(rs.getInt("TotalQty"));

            return p;
        });
    }
}