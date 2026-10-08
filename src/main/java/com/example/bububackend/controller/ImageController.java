package com.example.bububackend.controller;

import com.example.bububackend.model.Image;
import com.example.bububackend.model.ImageInfo;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.ImageService;
import org.springframework.http.CacheControl;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.Duration;
import java.util.List;

@RestController
@RequestMapping("/api/images")
public class ImageController {

    private final ImageService service;

    public ImageController(ImageService service) {
        this.service = service;
    }

    // GET /api/images              - thông tin ảnh của tất cả sản phẩm
    // GET /api/images?productId=5  - ảnh của sản phẩm 5
    @GetMapping
    public ResponseEntity<ApiResponse<List<ImageInfo>>> getImages(
            @RequestParam(required = false) Integer productId) {

        try {
            List<ImageInfo> images = service.getImages(productId);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            images,
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

    // GET /api/images/{id}/file - nội dung ảnh (dùng làm src của thẻ img).
    // Giao diện thêm ?v=version vào đường dẫn nên có thể cho trình duyệt nhớ ảnh lâu.
    @GetMapping("/{id}/file")
    public ResponseEntity<byte[]> getFile(@PathVariable int id) {

        try {
            Image img = service.getFile(id);

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(img.getContentType()))
                    .cacheControl(
                            CacheControl
                                    .maxAge(Duration.ofDays(30))
                                    .cachePublic()
                    )
                    .body(img.getData());

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .build();
        }
    }

    // GET /api/images/main?productId=5 - nội dung ảnh đại diện của sản phẩm (tiện cho trang bán hàng)
    @GetMapping("/main")
    public ResponseEntity<byte[]> getMain(@RequestParam int productId) {

        try {
            Image img = service.getMainFile(productId);

            return ResponseEntity.ok()
                    .contentType(MediaType.parseMediaType(img.getContentType()))
                    .cacheControl(CacheControl.noCache())
                    .body(img.getData());

        } catch (Exception e) {
            return ResponseEntity
                    .status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .build();
        }
    }

    // POST /api/images - thêm ảnh (multipart/form-data: productId + files, có thể nhiều file). Trả 201.
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<List<ImageInfo>>> upload(
            @RequestParam int productId,
            @RequestParam("files") List<MultipartFile> files) {

        try {
            List<ImageInfo> images = service.upload(productId, files);

            return ResponseEntity
                    .status(HttpStatus.CREATED)
                    .body(
                            new ApiResponse<>(
                                    images,
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

    // PUT /api/images/{id}/file - thay nội dung ảnh (multipart/form-data: file)
    @PutMapping(
            value = "/{id}/file",
            consumes = MediaType.MULTIPART_FORM_DATA_VALUE
    )
    public ResponseEntity<ApiResponse<ImageInfo>> replace(
            @PathVariable int id,
            @RequestParam("file") MultipartFile file) {

        try {
            ImageInfo image = service.replace(id, file);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            image,
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

    // PUT /api/images/{id}/main - đặt làm ảnh đại diện
    @PutMapping("/{id}/main")
    public ResponseEntity<ApiResponse<List<ImageInfo>>> setMain(
            @PathVariable int id) {

        try {
            List<ImageInfo> images = service.setMain(id);

            return ResponseEntity.ok(
                    new ApiResponse<>(
                            images,
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

    // DELETE /api/images/{id} - xóa ảnh (204)
    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse<Void>> delete(@PathVariable int id) {

        try {
            service.delete(id);

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