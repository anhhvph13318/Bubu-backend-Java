package com.example.bububackend.DTO;

import com.example.bububackend.model.Image;
import com.example.bububackend.model.ImageInfo;
import com.example.bububackend.model.Product;

import java.util.List;

public class ProductDetailResponseDTO {
    private Product product;
    private List<ProductDetailDTO> productDetails;
    private List<ImageInfo> images;
    public Product getProduct() {
        return product;
    }

    public void setProduct(Product product) {
        this.product = product;
    }
    public List<ImageInfo> getImages() {
        return images;
    }
    public void setImages(List<ImageInfo> images) {
        this.images = images;
    }

    public List<ProductDetailDTO> getProductDetails() {
        return productDetails;
    }

    public void setProductDetails(List<ProductDetailDTO> productDetails) {
        this.productDetails = productDetails;
    }
}
