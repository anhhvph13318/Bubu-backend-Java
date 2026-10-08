package com.example.bububackend.controller;

import com.example.bububackend.model.Color;
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
    public List<Color> getColors() {
        return service.getColors();
    }

    // POST /api/colors - thêm màu (201)
    @PostMapping
    public ResponseEntity<Color> createColor(@RequestBody Color color) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createColor(color));
    }

    // PUT /api/colors/{id} - sửa màu
    @PutMapping("/{id}")
    public Color updateColor(@PathVariable int id, @RequestBody Color color) {
        return service.updateColor(id, color);
    }

    // DELETE /api/colors/{id} - xóa màu (204); 409 nếu đang được dùng
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteColor(@PathVariable int id) {
        service.deleteColor(id);
        return ResponseEntity.noContent().build();
    }
}