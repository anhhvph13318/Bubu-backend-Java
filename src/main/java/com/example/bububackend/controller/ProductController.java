package com.example.bububackend.controller;

import com.example.bububackend.DTO.ProductDetailResponseDTO;
import com.example.bububackend.model.Product;
import com.example.bububackend.service.ProductService;
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

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    // GET /api/products - lấy tất cả sản phẩm
    @GetMapping
    public List<Product> getAllProducts() {

        return productService.getAllProducts();
    }

    // GET /api/products/{id} - lấy một sản phẩm
    @GetMapping("/{id}")
    public ProductDetailResponseDTO getProductById(@PathVariable int id) {
        return productService.getProductById(id);
    }

    // POST /api/products - thêm sản phẩm mới (trả về 201 + sản phẩm vừa tạo)
    @PostMapping
    public ResponseEntity<Product> createProduct(@RequestBody Product product) {
        Product created = productService.createProduct(product);
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    // PUT /api/products/{id} - cập nhật sản phẩm
    @PutMapping("/{id}")
    public Product updateProduct(@PathVariable int id, @RequestBody Product product) {
        return productService.updateProduct(id, product);
    }

    // DELETE /api/products/{id} - xóa sản phẩm (trả về 204, không có nội dung)
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteProduct(@PathVariable int id) {
        productService.deleteProduct(id);
        return ResponseEntity.noContent().build();
    }
}