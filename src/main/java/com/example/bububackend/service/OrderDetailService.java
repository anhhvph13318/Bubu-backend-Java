package com.example.bububackend.service;

import com.example.bububackend.DTO.OrderDetailDTO;
import com.example.bububackend.model.OrderDetail;
import com.example.bububackend.model.Product;
import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.repository.OrderDetailRepository;
import com.example.bububackend.repository.ProductDetailRepository;
import com.example.bububackend.repository.ProductRepository;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class OrderDetailService {

    private final OrderDetailRepository orderDetailRepository;
    private final ProductDetailRepository productDetailRepository;
    private final ProductRepository productRepository;

    public OrderDetailService(
            OrderDetailRepository orderDetailRepository,
            ProductDetailRepository productDetailRepository,
            ProductRepository productRepository) {

        this.orderDetailRepository = orderDetailRepository;
        this.productDetailRepository = productDetailRepository;
        this.productRepository = productRepository;
    }

    public List<OrderDetailDTO> getOrderDetailsByOrderId(int orderId) {

        List<OrderDetail> orderDetails =
                orderDetailRepository.findByOrderId(orderId);

        List<OrderDetailDTO> result = new ArrayList<>();

        for (OrderDetail orderDetail : orderDetails) {

            ProductDetail productDetail =
                    productDetailRepository
                            .findById(orderDetail.getProductDetailId())
                            .orElse(null);

            if (productDetail == null) {
                continue;
            }

            Product product =
                    productRepository
                            .findById(productDetail.getProductId())
                            .orElse(null);

            if (product == null) {
                continue;
            }

            OrderDetailDTO dto = new OrderDetailDTO();

            dto.setProductDetailId(productDetail.getId());
            dto.setProductId(product.getId());
            dto.setProductName(product.getName());
            dto.setSize(productDetail.getSize());
            dto.setColor(productDetail.getColor());
            dto.setQuantity(orderDetail.getQuantity());
            dto.setPrice(orderDetail.getPrice());
            dto.setImageUrl(product.getImageUrl());

            result.add(dto);
        }

        return result;
    }
}
