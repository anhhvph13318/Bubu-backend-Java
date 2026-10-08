package com.example.bububackend.service;

import com.example.bububackend.model.Size;
import com.example.bububackend.repository.ProductDetailRepository;
import com.example.bububackend.repository.SizeRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class SizeService {

    private final SizeRepository repository;
    private final ProductDetailRepository detailRepository;

    public SizeService(SizeRepository repository, ProductDetailRepository detailRepository) {
        this.repository = repository;
        this.detailRepository = detailRepository;
    }

    public List<Size> getSizes() {
        return repository.findAll();
    }

    public Size createSize(Size size) {
        size.setId(0); // luôn là bản ghi mới
        validate(size);
        return repository.save(size);
    }

    public Size updateSize(int id, Size size) {
        if (!repository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy size " + id);
        }
        size.setId(id);
        validate(size);
        return repository.save(size);
    }

    public void deleteSize(int id) {
        Size s = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy size " + id));
        if (detailRepository.existsBySizeId(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Size " + s.getName() + " đang được dùng trong biến thể sản phẩm, không thể xóa");
        }
        repository.deleteById(id);
    }

    // Tên không được trống và không được trùng (không phân biệt hoa thường)
    private void validate(Size s) {
        if (s.getName() == null || s.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập tên size");
        }
        s.setName(s.getName().trim());
        boolean duplicated = repository.findByNameIgnoreCase(s.getName()).stream()
                .anyMatch(x -> x.getId() != s.getId());
        if (duplicated) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Size " + s.getName() + " đã tồn tại");
        }
    }
}