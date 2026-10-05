package com.example.bububackend.controller;

import com.example.bububackend.dao.CategoryDAO;
import com.example.bububackend.model.Category;
import com.example.bububackend.service.CategoryService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/categories")
public class CateogoryController {
    private final CategoryService categoryService;

    public CateogoryController(CategoryService categoryService) {
        this.categoryService = categoryService;
    }

    @GetMapping
    public List<Category> getAllCategories() {
        return categoryService.getAllCategories();
    }
}
