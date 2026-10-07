package com.example.bububackend.service;

import com.example.bububackend.model.Category;
import com.example.bububackend.model.Product;
import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.repository.ProductDetailRepository;
import com.example.bububackend.repository.ProductRepository;
import com.example.bububackend.repository.CategoryRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductDetailRepository productDetailRepository;


    public ProductService(ProductRepository productRepository,CategoryRepository categoryRepository,ProductDetailRepository productDetailRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.productDetailRepository = productDetailRepository;
    }

    public List<Product> getAllProducts() {
        List<Product> products = productRepository.findAll();
        List<Category> categories = categoryRepository.findAll();

        for (Product product : products) {
            for (Category category : categories) {

                if (product.getCategoryId() == category.getId()) {
                    product.setCategoryName(category.getName());
                }
            }
        }
        for (Product product : products) {

            List<ProductDetail> details =
                    productDetailRepository.findByProductId(product.getId());

            int total = 0;

            for (ProductDetail detail : details) {
                total += detail.getQuantity();
            }

            product.setTotalQuantity(total);
        }

        return products;
    }

    public Product getProductById(int id) {
        return productRepository.findById(id).get();
    }

    public Product createProduct(Product product) {

        Category category = categoryRepository
                .findByName(product.getCategoryName())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy danh mục"));

        product.setCategoryId(category.getId());

        // Tự động sinh mã sản phẩm
        product.setCode(generateProductCode());

        return productRepository.save(product);
    }

    public Product updateProduct(int id, Product product) {
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sản phẩm " + id);
        }
        product.setId(id); // bảo đảm cập nhật đúng bản ghi, không tạo bản ghi mới
        return productRepository.save(product);
    }

    public void deleteProduct(int id) {
        if (!productRepository.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy sản phẩm " + id);
        }
        productRepository.deleteById(id);
    }

    //tự sinh mã sản phẩm
    private String generateProductCode() {

        List<Product> products = productRepository.findAll();

        int maxNumber = 0;

        for (Product product : products) {

            String code = product.getCode();

            if (code == null || !code.startsWith("SP")) {
                continue;
            }

            try {
                int number = Integer.parseInt(code.substring(2));

                if (number > maxNumber) {
                    maxNumber = number;
                }

            } catch (NumberFormatException e) {
                // Bỏ qua mã không đúng định dạng
            }
        }

        return String.format("SP%05d", maxNumber + 1);
    }
}