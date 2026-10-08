package com.example.bububackend.controller;

import com.example.bububackend.DTO.ProductDetailResponseDTO;
import com.example.bububackend.model.Product;
import com.example.bububackend.response.ApiResponse;
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
    public ResponseEntity<ApiResponse<List<Product>>> getAllProducts() {
        try {
            List<Product> products = productService.getAllProducts();

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            products,
                            true,
                            null,
                            null
                    )
            );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // GET /api/products/{id} - lấy một sản phẩm
    @GetMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductDetailResponseDTO>> getProductById(
            @PathVariable int id) {

        try {
            ProductDetailResponseDTO product =
                    productService.getProductById(id);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            product,
                            true,
                            null,
                            null
                    )
            );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // POST /api/products - thêm sản phẩm mới (trả về 201 + sản phẩm vừa tạo)
    @PostMapping
    public ResponseEntity<ApiResponse<Product>> createProduct(
            @RequestBody Product product) {

        try {
            Product created = productService.createProduct(product);

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                            new ApiResponse<>(
                                    created,
                                    true,
                                    null,
                                    null
                            )
                    );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // PUT /api/products/{id} - cập nhật sản phẩm
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Product>> updateProduct(
            @PathVariable int id,
            @RequestBody Product product) {

        try {
            Product updated = productService.updateProduct(id, product);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            updated,
                            true,
                            null,
                            null
                    )
            );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }

    // DELETE /api/products/{id} - xóa sản phẩm (trả về 204, không có nội dung)
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteProduct(
            @PathVariable int id) {

        try {
            productService.deleteProduct(id);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            null,
                            true,
                            null,
                            null
                    )
            );

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(
                            new ApiResponse<>(
                                    null,
                                    false,
                                    e.getMessage(),
                                    e.getClass().getSimpleName()
                            )
                    );
        }
    }
}