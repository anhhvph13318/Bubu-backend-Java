package com.example.bububackend.controller;

import com.example.bububackend.model.Size;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.SizeService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/sizes")
public class SizeController {

    private final SizeService service;

    public SizeController(SizeService service) {
        this.service = service;
    }

    // GET /api/sizes - danh sách size
    @GetMapping
    public ResponseEntity<ApiResponse<List<Size>>> getSizes() {

        try {
            List<Size> sizes = service.getSizes();

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            sizes,
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

    // POST /api/sizes - thêm size (201)
    @PostMapping
    public ResponseEntity<ApiResponse<Size>> createSize(
            @RequestBody Size size) {

        try {
            Size created = service.createSize(size);

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

    // PUT /api/sizes/{id} - sửa size
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Size>> updateSize(
            @PathVariable int id,
            @RequestBody Size size) {

        try {
            Size updated = service.updateSize(id, size);

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

    // DELETE /api/sizes/{id} - xóa size (204); 409 nếu đang được dùng
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteSize(
            @PathVariable int id) {

        try {
            service.deleteSize(id);

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