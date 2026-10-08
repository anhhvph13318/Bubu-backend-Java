package com.example.bububackend.service;

import com.example.bububackend.DTO.ImageDTO;
import com.example.bububackend.DTO.ProductDetailDTO;
import com.example.bububackend.DTO.ProductDetailResponseDTO;
import com.example.bububackend.model.*;
import com.example.bububackend.repository.*;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;

@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryRepository categoryRepository;
    private final ProductDetailRepository productDetailRepository;
    private final SizeRepository sizeRepository;
    private final ColorRepository colorRepository;
    private final ImageRepository imageRepository;

    public ProductService(ProductRepository productRepository,CategoryRepository categoryRepository,ProductDetailRepository productDetailRepository,SizeRepository sizeRepository,
                          ColorRepository colorRepository,ImageRepository imageRepository) {
        this.productRepository = productRepository;
        this.categoryRepository = categoryRepository;
        this.productDetailRepository = productDetailRepository;
        this.sizeRepository = sizeRepository;
        this.colorRepository = colorRepository;
        this.imageRepository = imageRepository;
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

    public ProductDetailResponseDTO getProductById(int id) {

        // =========================
        // 1. Lấy sản phẩm
        // =========================

        Product product = productRepository.findById(id).orElse(null);

        if (product == null) {
            return null;
        }


        // =========================
        // 2. Lấy category
        // =========================

        Category category =
                categoryRepository.findById(product.getCategoryId()).orElse(null);

        product.setCategoryName(
                category != null ? category.getName() : ""
        );


        // =========================
        // 3. Lấy danh sách chi tiết sản phẩm
        // =========================

        List<ProductDetail> details =
                productDetailRepository.findByProductId(id);

        List<ProductDetailDTO> productDetails = new ArrayList<>();

        int totalQuantity = 0;

        for (ProductDetail detail : details) {

            Size size = sizeRepository
                    .findById(detail.getSizeId())
                    .orElse(null);

            Color color = colorRepository
                    .findById(detail.getColorId())
                    .orElse(null);

            ProductDetailDTO productDetail = new ProductDetailDTO();

            productDetail.setId(detail.getId());

            productDetail.setSizeId(detail.getSizeId());
            productDetail.setSize(
                    size != null ? size.getName() : ""
            );

            productDetail.setColorId(detail.getColorId());
            productDetail.setColor(
                    color != null ? color.getName() : ""
            );

            productDetail.setQuantity(detail.getQuantity());

            productDetails.add(productDetail);

            totalQuantity += detail.getQuantity();
        }

        product.setTotalQuantity(totalQuantity);


        // =========================
        // 4. Lấy danh sách ảnh
        // =========================

        List<Image> images =
                imageRepository.findByProductIdOrderBySortOrderAscIdAsc(id);
        List<ImageInfo> imageInfos = images.stream()
                .map(image -> new ImageInfo(
                        image.getId(),
                        image.getProductId(),
                        image.getFileName(),
                        "/api/images/" + image.getId() + "/file",
                        image.isMain(),
                        image.getSortOrder(),
                        image.getVersion()
                ))
                .toList();

        // =========================
        // 5. Tạo response
        // =========================

        ProductDetailResponseDTO response =
                new ProductDetailResponseDTO();

        response.setProduct(product);
        response.setProductDetails(productDetails);
        response.setImages(imageInfos);
        return response;
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