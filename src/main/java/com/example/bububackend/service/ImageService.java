package com.example.bububackend.service;

import com.example.bububackend.model.Image;
import com.example.bububackend.model.ImageInfo;
import com.example.bububackend.repository.ImageRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.List;
import java.util.Set;

@Service
public class ImageService {

    // Mỗi sản phẩm tối đa 5 ảnh
    public static final int MAX_IMAGES = 5;
    // Chỉ nhận các định dạng ảnh thông dụng (không nhận SVG vì có thể chứa mã script)
    private static final Set<String> TYPES = Set.of("image/jpeg", "image/png", "image/gif", "image/webp");

    private final ImageRepository repository;

    public ImageService(ImageRepository repository) {
        this.repository = repository;
    }

    // Danh sách ảnh (thông tin), của một sản phẩm nếu truyền productId, không thì của tất cả
    public List<ImageInfo> getImages(Integer productId) {
        return productId == null ? repository.findAllInfo() : repository.findInfoByProductId(productId);
    }

    // Lấy nội dung ảnh theo id
    public Image getFile(int id) {
        return repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy ảnh " + id));
    }

    // Lấy ảnh đại diện của sản phẩm (không có đại diện thì lấy ảnh đầu tiên)
    public Image getMainFile(int productId) {
        return repository.findFirstByProductIdAndMainTrue(productId)
                .or(() -> repository.findFirstByProductIdOrderBySortOrderAscIdAsc(productId))
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sản phẩm chưa có ảnh"));
    }

    // Thêm một hoặc nhiều ảnh cho sản phẩm. Ảnh đầu tiên của sản phẩm tự thành ảnh đại diện.
    @Transactional
    public List<ImageInfo> upload(int productId, List<MultipartFile> files) {
        List<MultipartFile> list = files == null ? List.of() : files.stream().filter(f -> !f.isEmpty()).toList();
        if (list.isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng chọn ít nhất 1 ảnh");
        }
        long current = repository.countByProductId(productId);
        if (current + list.size() > MAX_IMAGES) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Mỗi sản phẩm tối đa " + MAX_IMAGES + " ảnh (hiện có " + current + ")");
        }
        boolean hasMain = repository.existsByProductIdAndMainTrue(productId);
        int order = (int) current;
        for (MultipartFile f : list) {
            Image img = new Image();
            img.setProductId(productId);
            fill(img, f);
            img.setSortOrder(order++);
            img.setMain(!hasMain); // ảnh đầu tiên khi chưa có đại diện
            hasMain = true;
            repository.save(img);
        }
        return repository.findInfoByProductId(productId);
    }

    // Thay nội dung một ảnh bằng ảnh khác (giữ nguyên vị trí, trạng thái đại diện)
    @Transactional
    public ImageInfo replace(int id, MultipartFile file) {
        Image img = getFile(id);
        fill(img, file);
        img.setVersion(img.getVersion() + 1);
        repository.save(img);
        return toInfo(img);
    }

    // Đặt một ảnh làm ảnh đại diện (ảnh đại diện cũ tự bỏ)
    @Transactional
    public List<ImageInfo> setMain(int id) {
        Image img = getFile(id);
        repository.clearMain(img.getProductId());
        repository.markMain(id);
        return repository.findInfoByProductId(img.getProductId());
    }

    // Xóa một ảnh; sản phẩm phải còn ít nhất 1 ảnh. Xóa ảnh đại diện thì ảnh đầu tiên còn lại lên thay.
    @Transactional
    public void delete(int id) {
        Image img = getFile(id);
        int productId = img.getProductId();
        if (repository.countByProductId(productId) <= 1) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Sản phẩm phải có ít nhất 1 ảnh. Hãy dùng \"Thay ảnh\" nếu muốn đổi ảnh.");
        }
        boolean wasMain = img.isMain();
        repository.deleteById(id);
        repository.flush();
        if (wasMain) {
            List<ImageInfo> rest = repository.findInfoByProductId(productId);
            if (!rest.isEmpty()) {
                repository.markMain(rest.get(0).id());
            }
        }
    }

    // Xóa mọi ảnh của sản phẩm (xóa sản phẩm trong DB đã tự xóa ảnh nhờ ON DELETE CASCADE)
    public void deleteByProductId(int productId) {
        repository.deleteByProductId(productId);
    }

    // Kiểm tra định dạng rồi chép nội dung file vào ảnh
    private void fill(Image img, MultipartFile f) {
        String type = f.getContentType() == null ? "" : f.getContentType().toLowerCase();
        if (!TYPES.contains(type)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Chỉ nhận ảnh JPG, PNG, GIF hoặc WebP");
        }
        try {
            img.setData(f.getBytes());
        } catch (IOException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Không đọc được file ảnh");
        }
        img.setContentType(type);
        String name = f.getOriginalFilename();
        img.setFileName(name == null ? null : name.substring(0, Math.min(name.length(), 255)));
    }

    private ImageInfo toInfo(Image i) {
        return new ImageInfo(i.getId(), i.getProductId(), i.getFileName() ,"/api/images/" + i.getId() + "/file" ,  i.isMain(), i.getSortOrder(), i.getVersion());
    }
}