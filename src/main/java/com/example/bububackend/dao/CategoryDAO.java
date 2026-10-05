package com.example.bububackend.dao;

import com.example.bububackend.model.Category;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public class CategoryDAO {
    private JdbcTemplate jdbcTemplate;
    public CategoryDAO(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public List<Category> findAll(){
        String sql = """
                SELECT p.Id,
                       p.Name,
                       p.Description,
                       p.IsDeleted
                FROM Category p
                ORDER BY p.id DESC;
        """;

        return jdbcTemplate.query(sql, (rs, rowNum) -> {
            Category p = new Category();

            p.setId(rs.getInt("Id"));
            p.setName(rs.getString("Name"));
            p.setDescription(rs.getString("description"));
            p.setDeleted(rs.getBoolean("IsDeleted"));
            return p;
        });
    }
}
