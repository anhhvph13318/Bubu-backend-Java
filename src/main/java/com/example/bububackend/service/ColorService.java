package com.example.bububackend.service;

import com.example.bububackend.model.Color;
import com.example.bububackend.repository.ColorRepository;
import com.example.bububackend.repository.ProductDetailRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ColorService {

    private final ColorRepository repository;
    private final ProductDetailRepository detailRepository;

    public ColorService(ColorRepository repository, ProductDetailRepository detailRepository) {
        this.repository = repository;
        this.detailRepository = detailRepository;
    }

    public List<Color> getColors() {
        return repository.findAll();
    }

    public Color createColor(Color color) {
        color.setId(0); // luôn là bản ghi mới
        validate(color);
        return repository.save(color);
    }

    public Color updateColor(int id, Color color) {
        if (!repository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy màu " + id);
        }
        color.setId(id);
        validate(color);
        return repository.save(color);
    }

    public void deleteColor(int id) {
        Color c = repository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy màu " + id));
        if (detailRepository.existsByColorId(id)) {
            throw new ResponseStatusException(HttpStatus.CONFLICT,
                    "Màu " + c.getName() + " đang được dùng trong biến thể sản phẩm, không thể xóa");
        }
        repository.deleteById(id);
    }

    // Tên không được trống / trùng; mã màu (nếu có) phải dạng #RRGGBB
    private void validate(Color c) {
        if (c.getName() == null || c.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Vui lòng nhập tên màu");
        }
        c.setName(c.getName().trim());
        String hex = c.getHexCode() == null ? "" : c.getHexCode().trim();
        if (!hex.isEmpty() && !hex.matches("^#[0-9A-Fa-f]{6}$")) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Mã màu phải có dạng #RRGGBB, ví dụ #FF99CC");
        }
        c.setHexCode(hex.isEmpty() ? null : hex.toUpperCase());
        boolean duplicated = repository.findByNameIgnoreCase(c.getName()).stream()
                .anyMatch(x -> x.getId() != c.getId());
        if (duplicated) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Màu " + c.getName() + " đã tồn tại");
        }
    }
}