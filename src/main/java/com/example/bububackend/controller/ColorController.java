package com.example.bububackend.controller;

import com.example.bububackend.model.Color;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.ColorService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/colors")
public class ColorController {

    private final ColorService service;

    public ColorController(ColorService service) {
        this.service = service;
    }

    // GET /api/colors - danh sách màu
    @GetMapping
    public ResponseEntity<ApiResponse<List<Color>>> getColors() {

        try {
            List<Color> colors = service.getColors();

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            colors,
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

    // POST /api/colors - thêm màu (201)
    @PostMapping
    public ResponseEntity<ApiResponse<Color>> createColor(
            @RequestBody Color color) {

        try {
            Color created = service.createColor(color);

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

    // PUT /api/colors/{id} - sửa màu
    @PutMapping("/{id}")
    public ResponseEntity<ApiResponse<Color>> updateColor(
            @PathVariable int id,
            @RequestBody Color color) {

        try {
            Color updated = service.updateColor(id, color);

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
    // DELETE /api/colors/{id} - xóa màu (204); 409 nếu đang được dùng
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> deleteColor(
            @PathVariable int id) {

        try {
            service.deleteColor(id);

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