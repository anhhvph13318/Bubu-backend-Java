package com.example.bububackend.service;

import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.repository.ColorRepository;
import com.example.bububackend.repository.ProductDetailRepository;
import com.example.bububackend.repository.SizeRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ProductDetailService {

    private final ProductDetailRepository repository;
    private final SizeRepository sizeRepository;
    private final ColorRepository colorRepository;

    public ProductDetailService(ProductDetailRepository repository,
                                SizeRepository sizeRepository,
                                ColorRepository colorRepository) {
        this.repository = repository;
        this.sizeRepository = sizeRepository;
        this.colorRepository = colorRepository;
    }

    // Lấy tất cả biến thể, hoặc chỉ của một sản phẩm nếu truyền productId
    public List<ProductDetail> getDetails(Integer productId) {
        return productId == null ? repository.findAll() : repository.findByProductId(productId);
    }

    public ProductDetail createDetail(ProductDetail detail) {
        detail.setId(0); // bảo đảm luôn là bản ghi mới
        validate(detail);
        return repository.save(detail);
    }

    public ProductDetail updateDetail(int id, ProductDetail detail) {
        if (!repository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy biến thể " + id);
        }
        detail.setId(id); // bảo đảm cập nhật đúng bản ghi
        validate(detail);
        return repository.save(detail);
    }

    public void deleteDetail(int id) {
        if (!repository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy biến thể " + id);
        }
        repository.deleteById(id);
    }

    // Xóa mọi biến thể của sản phẩm - ProductService.deleteProduct nên gọi hàm này trước khi xóa sản phẩm
    public void deleteByProductId(int productId) {
        repository.deleteByProductId(productId);
    }

    // Kiểm tra dữ liệu và chặn trùng (cùng sản phẩm + cùng size + cùng màu)
    private void validate(ProductDetail d) {
        if (!sizeRepository.existsById(d.getSizeId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Size không tồn tại, vui lòng chọn size");
        }
        if (!colorRepository.existsById(d.getColorId())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Màu không tồn tại, vui lòng chọn màu");
        }
        if (d.getQuantity() < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số lượng không được âm");
        }
        boolean duplicated = repository.findByProductId(d.getProductId()).stream()
                .anyMatch(x -> x.getId() != d.getId()
                        && x.getSizeId() == d.getSizeId()
                        && x.getColorId() == d.getColorId());
        if (duplicated) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Biến thể với size và màu này đã tồn tại");
        }
    }
}