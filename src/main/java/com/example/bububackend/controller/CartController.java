package com.example.bububackend.controller;

import com.example.bububackend.DTO.CartItemsRequest;
import com.example.bububackend.DTO.CartView;
import com.example.bububackend.DTO.ItemRequest;
import com.example.bububackend.DTO.UpdateQuantityRequest;
import com.example.bububackend.service.CartService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/carts")
public class CartController {

    private final CartService service;

    public CartController(CartService service) {
        this.service = service;
    }

    // GET /api/carts/{accountId} - giỏ của khách đã đăng nhập (chưa có thì trả giỏ rỗng)
    @GetMapping("/{accountId}")
    public CartView getCart(@PathVariable int accountId) {
        return service.getCart(accountId);
    }

    // POST /api/carts/{accountId}/items - thêm sản phẩm vào giỏ, body: {"productDetailId": 5, "quantity": 1}. Trả 201.
    @PostMapping("/{accountId}/items")
    public ResponseEntity<CartView> addItem(@PathVariable int accountId, @RequestBody ItemRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.addItem(accountId, request));
    }

    // PUT /api/carts/{accountId}/items/{productDetailId} - đổi số lượng, body: {"quantity": 3}
    @PutMapping("/{accountId}/items/{productDetailId}")
    public CartView updateQuantity(@PathVariable int accountId, @PathVariable int productDetailId,
                                   @RequestBody UpdateQuantityRequest request) {
        return service.updateQuantity(accountId, productDetailId, request.quantity());
    }

    // DELETE /api/carts/{accountId}/items/{productDetailId} - xóa một dòng khỏi giỏ
    @DeleteMapping("/{accountId}/items/{productDetailId}")
    public CartView removeItem(@PathVariable int accountId, @PathVariable int productDetailId) {
        return service.removeItem(accountId, productDetailId);
    }

    // DELETE /api/carts/{accountId}/items - xóa sạch giỏ
    @DeleteMapping("/{accountId}/items")
    public CartView clear(@PathVariable int accountId) {
        return service.clear(accountId);
    }

    // POST /api/carts/{accountId}/merge - khi khách đăng nhập, gộp giỏ localStorage vào giỏ database.
    // body: {"items": [{"productDetailId": 5, "quantity": 2}, ...]}
    @PostMapping("/{accountId}/merge")
    public CartView merge(@PathVariable int accountId, @RequestBody CartItemsRequest request) {
        return service.merge(accountId, request);
    }

    // POST /api/carts/preview - khách chưa đăng nhập: gửi giỏ localStorage lên để nhận tên, ảnh, giá, tồn kho hiện tại.
    // body: {"items": [{"productDetailId": 5, "quantity": 2}, ...]}. Không ghi gì vào database.
    @PostMapping("/preview")
    public CartView preview(@RequestBody CartItemsRequest request) {
        return service.preview(request);
    }
}