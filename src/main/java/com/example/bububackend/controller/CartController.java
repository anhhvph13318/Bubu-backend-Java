package com.example.bububackend.controller;

import com.example.bububackend.DTO.CartItemsRequest;
import com.example.bububackend.DTO.CartView;
import com.example.bububackend.DTO.ItemRequest;
import com.example.bububackend.DTO.UpdateQuantityRequest;
import com.example.bububackend.response.ApiResponse;
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
    public ResponseEntity<ApiResponse<CartView>> getCart(
            @PathVariable int accountId) {
        try {
            CartView cart = service.getCart(accountId);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            cart,
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

    // POST /api/carts/{accountId}/items - thêm sản phẩm vào giỏ, body: {"productDetailId": 5, "quantity": 1}. Trả 201.

    @PostMapping("/{accountId}/items")
    public ResponseEntity<ApiResponse<CartView>> addItem(
            @PathVariable int accountId,
            @RequestBody ItemRequest request) {
        try {
            CartView cart = service.addItem(accountId, request);

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                            new ApiResponse<>(
                                    cart,
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

    // PUT /api/carts/{accountId}/items/{productDetailId} - đổi số lượng, body: {"quantity": 3}

    @PutMapping("/{accountId}/items/{productDetailId}")
    public ResponseEntity<ApiResponse<CartView>> updateQuantity(
            @PathVariable int accountId,
            @PathVariable int productDetailId,
            @RequestBody UpdateQuantityRequest request) {
        try {
            CartView cart = service.updateQuantity(
                    accountId,
                    productDetailId,
                    request.quantity()
            );

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            cart,
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

    // DELETE /api/carts/{accountId}/items/{productDetailId} - xóa một dòng khỏi giỏ

    @DeleteMapping("/{accountId}/items/{productDetailId}")
    public ResponseEntity<ApiResponse<CartView>> removeItem(
            @PathVariable int accountId,
            @PathVariable int productDetailId) {
        try {
            CartView cart = service.removeItem(accountId, productDetailId);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            cart,
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


    // DELETE /api/carts/{accountId}/items - xóa sạch giỏ
    @DeleteMapping("/{accountId}/items")
    public ResponseEntity<ApiResponse<CartView>> clear(
            @PathVariable int accountId) {
        try {
            CartView cart = service.clear(accountId);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            cart,
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