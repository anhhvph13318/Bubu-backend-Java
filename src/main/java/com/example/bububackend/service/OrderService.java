package com.example.bububackend.service;

import com.example.bububackend.DTO.CartProductRow;
import com.example.bububackend.DTO.CreateOrderRequest;
import com.example.bububackend.DTO.ItemRequest;
import com.example.bububackend.model.Order;
import com.example.bububackend.model.OrderDetail;
import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.repository.OrderRepository;
import com.example.bububackend.repository.ProductDetailRepository;
import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class OrderService {
    private final OrderRepository orderRepository;
    private final ProductDetailRepository productDetailRepository;

    // Dùng EntityManager để ghi OrderDetail, không phụ thuộc vào repository của OrderDetail
    @PersistenceContext
    private EntityManager entityManager;

    public OrderService(OrderRepository orderRepository, ProductDetailRepository productDetailRepository) {
        this.orderRepository = orderRepository;
        this.productDetailRepository = productDetailRepository;
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    public Order updateStatus(int id) {
        Order order = orderRepository.findById(id).orElse(null);

        if (order == null) {
            return null;
        }

        order.setStatus(order.getStatus() + 1);
        return orderRepository.save(order);
    }

    /**
     * Tạo đơn hàng từ dữ liệu trang bán hàng gửi lên: ghi 1 bản ghi Orders và các bản ghi OrderDetail.
     * - Giá lấy từ sản phẩm tại thời điểm đặt (không tin giá do client gửi) và chốt vào OrderDetail.Price.
     * - Chỉ KIỂM TRA tồn kho, KHÔNG trừ tồn kho (xem deductStock).
     * - Đơn mới: Status = 0 (chờ xác nhận), PaymentStatus = 0 (chưa thanh toán).
     */
    @Transactional
    public Order createOrder(CreateOrderRequest request) {
        // 1. Kiểm tra thông tin khách
        String name = clean(request.customerName());
        String phone = clean(request.phone()).replaceAll("[\\s.-]", "");
        String address = clean(request.address());
        if (name.isEmpty()) {
            throw bad("Vui lòng nhập tên người nhận");
        }
        if (!phone.matches("^\\+?\\d{9,12}$")) {
            throw bad("Số điện thoại không hợp lệ");
        }
        if (address.isEmpty()) {
            throw bad("Vui lòng nhập địa chỉ giao hàng");
        }
        if (request.paymentMethod() != 0 && request.paymentMethod() != 1) {
            throw bad("Phương thức thanh toán không hợp lệ (0 = COD, 1 = VNPay)");
        }

        // 2. Gộp các dòng trùng biến thể, kiểm tra số lượng
        if (request.items() == null || request.items().isEmpty()) {
            throw bad("Đơn hàng chưa có sản phẩm nào");
        }
        Map<Integer, Integer> wanted = new LinkedHashMap<>();
        for (ItemRequest item : request.items()) {
            if (item == null || item.quantity() <= 0) {
                throw bad("Số lượng sản phẩm phải lớn hơn 0");
            }
            wanted.merge(item.productDetailId(), item.quantity(), Integer::sum);
        }

        // 3. Lấy giá + tồn kho hiện tại, kiểm tra từng dòng còn đủ hàng
        Map<Integer, CartProductRow> rows = productDetailRepository.findCartRows(wanted.keySet()).stream()
                .collect(Collectors.toMap(CartProductRow::detailId, r -> r, (a, b) -> a));
        BigDecimal total = BigDecimal.ZERO;
        for (Map.Entry<Integer, Integer> e : wanted.entrySet()) {
            CartProductRow row = rows.get(e.getKey());
            if (row == null) {
                throw bad("Sản phẩm (biến thể " + e.getKey() + ") không còn tồn tại");
            }
            if (e.getValue() > row.stock()) {
                throw bad(describe(row) + (row.stock() <= 0 ? " đã hết hàng" : " chỉ còn " + row.stock() + " sản phẩm"));
            }
            total = total.add(CartService.toMoney(row.price()).multiply(BigDecimal.valueOf(e.getValue())));
        }

        // 4. Ghi Orders. Mã đơn dạng DH0001 lấy theo id nên lưu mã tạm trước rồi đổi sang mã chính thức.
        Order order = new Order();
        order.setOrderCode("T" + UUID.randomUUID().toString().substring(0, 7));
        order.setCustomerName(name);
        order.setPhone(phone);
        order.setAddress(address);
        order.setNote(clean(request.note()).isEmpty() ? null : clean(request.note()));
        order.setTotalAmount(total);
        order.setPaymentMethod(request.paymentMethod());
        order.setPaymentStatus(0);
        order.setStatus(0);
        order.setCreatedAt(LocalDateTime.now());
        order = orderRepository.save(order);
        order.setOrderCode(String.format("DH%04d", order.getId()));
        order = orderRepository.save(order);

        // 5. Ghi OrderDetail, giá chốt tại thời điểm đặt
        for (Map.Entry<Integer, Integer> e : wanted.entrySet()) {
            OrderDetail detail = new OrderDetail();
            detail.setOrderId(order.getId());
            detail.setProductDetailId(e.getKey());
            detail.setQuantity(e.getValue());
            detail.setPrice(CartService.toMoney(rows.get(e.getKey()).price()));
            entityManager.persist(detail);
        }
        return order;
    }

    /**
     * Trừ tồn kho theo các dòng của đơn. Gọi ĐÚNG MỘT LẦN khi đơn được thanh toán / xác nhận thành công
     * (đơn thất bại hoặc bị hủy thì không gọi). Không đủ hàng thì ném lỗi 400 và không trừ gì cả.
     * createOrder không gọi hàm này.
     */
    @Transactional
    public void deductStock(int orderId) {
        if (!orderRepository.existsById(orderId)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng " + orderId);
        }
        List<OrderDetail> details = entityManager
                .createQuery("select d from OrderDetail d where d.orderId = :orderId", OrderDetail.class)
                .setParameter("orderId", orderId)
                .getResultList();
        for (OrderDetail d : details) {
            ProductDetail pd = productDetailRepository.findById(d.getProductDetailId())
                    .orElseThrow(() -> bad("Sản phẩm (biến thể " + d.getProductDetailId() + ") không còn tồn tại"));
            if (pd.getQuantity() < d.getQuantity()) {
                throw bad("Không đủ tồn kho cho biến thể " + pd.getId() + " (còn " + pd.getQuantity() + ", cần " + d.getQuantity() + ")");
            }
            pd.setQuantity(pd.getQuantity() - d.getQuantity());
            productDetailRepository.save(pd);
        }
    }

    private static String clean(String s) {
        return s == null ? "" : s.trim();
    }

    private static String describe(CartProductRow r) {
        return r.productName() + " (size " + r.sizeName() + ", màu " + r.colorName() + ")";
    }

    private static ResponseStatusException bad(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }
}