package com.example.bububackend.controller;

import com.example.bububackend.model.Size;
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
    public List<Size> getSizes() {
        return service.getSizes();
    }

    // POST /api/sizes - thêm size (201)
    @PostMapping
    public ResponseEntity<Size> createSize(@RequestBody Size size) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.createSize(size));
    }

    // PUT /api/sizes/{id} - sửa size
    @PutMapping("/{id}")
    public Size updateSize(@PathVariable int id, @RequestBody Size size) {
        return service.updateSize(id, size);
    }

    // DELETE /api/sizes/{id} - xóa size (204); 409 nếu đang được dùng
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteSize(@PathVariable int id) {
        service.deleteSize(id);
        return ResponseEntity.noContent().build();
    }
}