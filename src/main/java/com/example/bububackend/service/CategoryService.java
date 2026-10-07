package com.example.bububackend.service;

import com.example.bububackend.model.Category;
import com.example.bububackend.repository.CategoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class CategoryService {
    private final CategoryRepository categoryRepository;

    public CategoryService(CategoryRepository categoryRepository) {this.categoryRepository = categoryRepository;}

    public List<Category> getAllCategories(){
        return categoryRepository.findAll();
    }

    public Category createCategory(Category category) {
        return categoryRepository.save(category);
    }

    public Category updateCategory(int id, Category category) {
        if (!categoryRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy danh mục " + id);
        }
        category.setId(id); // bảo đảm cập nhật đúng bản ghi, không tạo bản ghi mới
        return categoryRepository.save(category);
    }

    public void deleteCategory(int id) {
        if (!categoryRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy danh mục " + id);
        }
        categoryRepository.deleteById(id);
    }
}
