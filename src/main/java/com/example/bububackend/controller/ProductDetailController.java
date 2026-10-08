package com.example.bububackend.controller;

import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.response.ApiResponse;
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
    public ResponseEntity<ApiResponse<List<ProductDetail>>> getDetails(
            @RequestParam(required = false) Integer productId) {

        try {
            List<ProductDetail> details = service.getDetails(productId);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            details,
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

    // POST /api/product-details - thêm biến thể (trả về 201)
    @PostMapping
    public ResponseEntity<ApiResponse<ProductDetail>> createDetail(
            @RequestBody ProductDetail detail) {

        try {
            ProductDetail created = service.createDetail(detail);

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

    // PUT /api/product-details/{id} - cập nhật biến thể
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<ProductDetail>> updateDetail(
            @PathVariable int id,
            @RequestBody ProductDetail detail) {

        try {
            ProductDetail updated = service.updateDetail(id, detail);

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

    // DELETE /api/product-details/{id} - xóa biến thể (trả về 204)
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteDetail(
            @PathVariable int id) {

        try {
            service.deleteDetail(id);

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