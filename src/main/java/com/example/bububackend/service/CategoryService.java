package com.example.bububackend.service;

import com.example.bububackend.dao.CategoryDAO;
import com.example.bububackend.model.Category;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CategoryService {
    private final CategoryDAO categoryDAO;

    public CategoryService(CategoryDAO categoryDAO) {
        this.categoryDAO = categoryDAO;
    }
    public List<Category> getAllCategories(){
        return categoryDAO.findAll();
    }
}
