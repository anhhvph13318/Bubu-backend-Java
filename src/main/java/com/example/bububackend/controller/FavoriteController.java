package com.example.bububackend.controller;

import com.example.bububackend.DTO.FavoriteIdsRequest;
import com.example.bububackend.DTO.FavoriteView;
import com.example.bububackend.config.AuthInterceptor;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.FavoriteService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

// Sản phẩm yêu thích. Trừ /preview (công khai), các API còn lại cần đăng nhập và dùng accountId của session.
// Lỗi (400, 401, 404) để Spring tự trả JSON có "message".
@RestController
@RequestMapping("/api/favorites")
public class FavoriteController {

    private final FavoriteService service;

    public FavoriteController(FavoriteService service) {
        this.service = service;
    }

    // GET /api/favorites - danh sách yêu thích của tôi (tên, giá, ảnh, tồn kho), mới thêm lên đầu
    @GetMapping
    public ResponseEntity<ApiResponse<List<FavoriteView>>> list(HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        return ResponseEntity.ok(new ApiResponse<>(service.list(accountId), true, null, null));
    }

    // GET /api/favorites/ids - chỉ id sản phẩm yêu thích, để tô màu trái tim ở danh sách sản phẩm
    @GetMapping("/ids")
    public ResponseEntity<ApiResponse<List<Integer>>> ids(HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        return ResponseEntity.ok(new ApiResponse<>(service.ids(accountId), true, null, null));
    }

    // POST /api/favorites/{productId} - thêm yêu thích (đã có rồi vẫn trả 200)
    @PostMapping("/{productId}")
    public ResponseEntity<ApiResponse<Void>> add(@PathVariable int productId, HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        service.add(accountId, productId);
        return ResponseEntity.ok(new ApiResponse<>(null, true, null, null));
    }

    // DELETE /api/favorites/{productId} - bỏ yêu thích (chưa có vẫn trả 200)
    @DeleteMapping("/{productId}")
    public ResponseEntity<ApiResponse<Void>> remove(@PathVariable int productId, HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        service.remove(accountId, productId);
        return ResponseEntity.ok(new ApiResponse<>(null, true, null, null));
    }

    // POST /api/favorites/merge - khi khách đăng nhập, gộp danh sách localStorage vào database.
    // body: {"productIds": [15, 20]}. Trả danh sách yêu thích sau khi gộp.
    @PostMapping("/merge")
    public ResponseEntity<ApiResponse<List<FavoriteView>>> merge(@RequestBody FavoriteIdsRequest request,
                                                                 HttpServletRequest http) {
        int accountId = AuthInterceptor.requireAccountId(http);
        return ResponseEntity.ok(new ApiResponse<>(service.merge(accountId, request), true, null, null));
    }

    // POST /api/favorites/preview - khách chưa đăng nhập: gửi danh sách localStorage để nhận tên, giá, ảnh hiện tại.
    // body: {"productIds": [15, 20]}. Không ghi gì vào database.
    @PostMapping("/preview")
    public ResponseEntity<ApiResponse<List<FavoriteView>>> preview(@RequestBody FavoriteIdsRequest request) {
        return ResponseEntity.ok(new ApiResponse<>(service.preview(request), true, null, null));
    }
}