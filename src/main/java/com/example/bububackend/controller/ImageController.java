package com.example.bububackend.controller;

import com.example.bububackend.model.Image;
import com.example.bububackend.model.ImageInfo;
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
    public List<ImageInfo> getImages(@RequestParam(required = false) Integer productId) {
        return service.getImages(productId);
    }

    // GET /api/images/{id}/file - nội dung ảnh (dùng làm src của thẻ img).
    // Giao diện thêm ?v=version vào đường dẫn nên có thể cho trình duyệt nhớ ảnh lâu.
    @GetMapping("/{id}/file")
    public ResponseEntity<byte[]> getFile(@PathVariable int id) {
        Image img = service.getFile(id);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(img.getContentType()))
                .cacheControl(CacheControl.maxAge(Duration.ofDays(30)).cachePublic())
                .body(img.getData());
    }

    // GET /api/images/main?productId=5 - nội dung ảnh đại diện của sản phẩm (tiện cho trang bán hàng)
    @GetMapping("/main")
    public ResponseEntity<byte[]> getMain(@RequestParam int productId) {
        Image img = service.getMainFile(productId);
        return ResponseEntity.ok()
                .contentType(MediaType.parseMediaType(img.getContentType()))
                .cacheControl(CacheControl.noCache())
                .body(img.getData());
    }

    // POST /api/images - thêm ảnh (multipart/form-data: productId + files, có thể nhiều file). Trả 201.
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<List<ImageInfo>> upload(@RequestParam int productId,
                                                  @RequestParam("files") List<MultipartFile> files) {
        return ResponseEntity.status(HttpStatus.CREATED).body(service.upload(productId, files));
    }

    // PUT /api/images/{id}/file - thay nội dung ảnh (multipart/form-data: file)
    @PutMapping(value = "/{id}/file", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ImageInfo replace(@PathVariable int id, @RequestParam("file") MultipartFile file) {
        return service.replace(id, file);
    }

    // PUT /api/images/{id}/main - đặt làm ảnh đại diện
    @PutMapping("/{id}/main")
    public List<ImageInfo> setMain(@PathVariable int id) {
        return service.setMain(id);
    }

    // DELETE /api/images/{id} - xóa ảnh (204)
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable int id) {
        service.delete(id);
        return ResponseEntity.noContent().build();
    }
}