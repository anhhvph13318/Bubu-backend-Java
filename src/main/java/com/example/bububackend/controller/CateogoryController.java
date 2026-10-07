package com.example.bububackend.controller;

import com.example.bububackend.model.Category;
import com.example.bububackend.service.CategoryService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

// Giữ nguyên tên class cũ (CateogoryController) để khỏi phải đổi tên file.
// Muốn sửa chính tả thành CategoryController thì đổi cả tên class lẫn tên file.
@RestController
@RequestMapping("/api/categories")
public class CateogoryController {
    private final CategoryService categoryService;

    public CateogoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    // GET /api/categories - lấy tất cả danh mục
    @GetMapping
    public List<Category> getAllCategories() {
        return categoryService.getAllCategories();
    }

    // POST /api/categories - thêm danh mục mới (trả về 201 + danh mục vừa tạo)
    @PostMapping
    public ResponseEntity<Category> createCategory(@RequestBody Category category) {
        Category created = categoryService.createCategory(category);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT /api/categories/{id} - cập nhật danh mục
    @PutMapping("/{id}")
    public Category updateCategory(@PathVariable int id, @RequestBody Category category) {
        return categoryService.updateCategory(id, category);
    }

    // DELETE /api/categories/{id} - xóa danh mục (trả về 204, không có nội dung)
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteCategory(@PathVariable int id) {
        categoryService.deleteCategory(id);
        return ResponseEntity.noContent().build();
    }
}