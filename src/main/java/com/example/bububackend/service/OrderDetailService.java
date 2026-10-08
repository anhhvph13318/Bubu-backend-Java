package com.example.bububackend.service;

import com.example.bububackend.DTO.OrderDetailDTO;
import com.example.bububackend.model.*;
import com.example.bububackend.repository.*;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class OrderDetailService {

    private final OrderDetailRepository orderDetailRepository;
    private final ProductDetailRepository productDetailRepository;
    private final ProductRepository productRepository;
    private final SizeRepository sizeRepository;
    private final ColorRepository colorRepository;

    public OrderDetailService(
            OrderDetailRepository orderDetailRepository,
            ProductDetailRepository productDetailRepository,
            ProductRepository productRepository,
            SizeRepository sizeRepository,
            ColorRepository colorRepository) {

        this.orderDetailRepository = orderDetailRepository;
        this.productDetailRepository = productDetailRepository;
        this.productRepository = productRepository;
        this.sizeRepository = sizeRepository;
        this.colorRepository = colorRepository;
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
            Size size = sizeRepository.findById(productDetail.getSizeId()).orElse(null);
            Color color = colorRepository.findById(productDetail.getColorId()).orElse(null);

            dto.setSizeId(productDetail.getSizeId());
            dto.setSize(size != null ? size.getName() : "");

            dto.setColorId(productDetail.getColorId());
            dto.setColor(color != null ? color.getName() : "");
            dto.setQuantity(orderDetail.getQuantity());
            dto.setPrice(orderDetail.getPrice());
            dto.setImageUrl(product.getImageUrl());

            result.add(dto);
        }

        return result;
    }
}
