package com.example.bububackend.controller;

import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.service.ProductDetailService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/product-details")
public class ProductDetailController {

    private final ProductDetailService service;

    public ProductDetailController(ProductDetailService service) {
        this.service = service;
    }

    // GET /api/product-details            - tất cả biến thể
    // GET /api/product-details?productId=5 - biến thể của sản phẩm 5
    @GetMapping
    public List<ProductDetail> getDetails(@RequestParam(required = false) Integer productId) {
        return service.getDetails(productId);
    }

    // POST /api/product-details - thêm biến thể (trả về 201)
    @PostMapping
    public ResponseEntity<ProductDetail> createDetail(@RequestBody ProductDetail detail) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createDetail(detail));
    }

    // PUT /api/product-details/{id} - cập nhật biến thể
    @PutMapping("/{id}")
    public ProductDetail updateDetail(@PathVariable int id, @RequestBody ProductDetail detail) {
        return service.updateDetail(id, detail);
    }

    // DELETE /api/product-details/{id} - xóa biến thể (trả về 204)
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDetail(@PathVariable int id) {
        service.deleteDetail(id);
        return ResponseEntity.noContent().build();
    }
}