package com.example.bububackend.service;

import com.example.bububackend.DTO.CartProductRow;
import com.example.bububackend.DTO.CreateOrderRequest;
import com.example.bububackend.DTO.ItemRequest;
import com.example.bububackend.model.Order;
import com.example.bububackend.model.OrderDetail;
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
import java.util.List;
import java.util.Map;
import java.util.TreeMap;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
public class OrderService {

    // Trạng thái đơn (khớp với trang admin)
    public static final int STATUS_PENDING = 0;
    public static final int STATUS_CONFIRMED = 1;
    public static final int STATUS_SHIPPING = 2;
    public static final int STATUS_DONE = 3;
    public static final int STATUS_CANCELLED = 4;
    private static final String[] STATUS_LABELS =
            {"Chờ xác nhận", "Đã xác nhận", "Đang giao", "Hoàn thành", "Đã hủy"};

    private final OrderRepository orderRepository;
    private final ProductDetailRepository productDetailRepository;

    // Dùng EntityManager để ghi / đọc OrderDetail, không phụ thuộc vào repository của OrderDetail
    @PersistenceContext
    private EntityManager entityManager;

    public OrderService(OrderRepository orderRepository, ProductDetailRepository productDetailRepository) {
        this.orderRepository = orderRepository;
        this.productDetailRepository = productDetailRepository;
    }

    public List<Order> getAllOrders() {
        return orderRepository.findAll();
    }

    /**
     * Đổi trạng thái đơn.
     * - Hủy (→ 4): chỉ khi đơn đang "Chờ xác nhận" (0) hoặc "Đã xác nhận" (1); hủy thì cộng tồn kho lại.
     * - Tiến lên: sang trạng thái sau (có thể nhảy cóc, tối đa tới "Hoàn thành").
     * - Không quay lại trạng thái trước; đơn đã "Hoàn thành" hoặc "Đã hủy" thì không đổi được nữa.
     */
    @Transactional
    public Order updateStatus(int id, int newStatus) {
        Order order = orderRepository.findByIdForUpdate(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy đơn hàng " + id));

        int current = order.getStatus();
        if (newStatus == current) {
            return order;
        }
        if (newStatus < STATUS_PENDING || newStatus > STATUS_CANCELLED) {
            throw bad("Trạng thái không hợp lệ");
        }

        if (newStatus == STATUS_CANCELLED) {
            if (current != STATUS_PENDING && current != STATUS_CONFIRMED) {
                throw bad("Chỉ hủy được đơn ở trạng thái \"Chờ xác nhận\" hoặc \"Đã xác nhận\" (đơn này đang \""
                        + label(current) + "\")");
            }
            restoreStock(id);
        } else {
            if (current == STATUS_DONE || current == STATUS_CANCELLED) {
                throw bad("Đơn đã \"" + label(current) + "\", không thể đổi trạng thái nữa");
            }
            if (newStatus < current) {
                throw bad("Không thể chuyển từ \"" + label(current) + "\" về \"" + label(newStatus) + "\"");
            }
        }

        order.setStatus(newStatus);
        return orderRepository.save(order);
    }

    /**
     * Tạo đơn hàng. accountId = tài khoản đang đăng nhập, null = khách vãng lai (vẫn lưu đủ thông tin người nhận).
     * - Giá lấy từ sản phẩm tại thời điểm đặt (không tin giá do client gửi) và chốt vào OrderDetail.Price.
     * - Trừ tồn kho NGUYÊN TỬ ngay khi tạo đơn; không đủ hàng thì cả đơn bị hủy bỏ (rollback).
     * - Đơn mới: Status = 0 (chờ xác nhận), PaymentStatus = 0 (chưa thanh toán).
     */
    @Transactional
    public Order createOrder(CreateOrderRequest request, Integer accountId) {
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

        // 2. Gộp các dòng trùng biến thể, kiểm tra số lượng.
        // TreeMap: luôn xử lý theo id tăng dần để hai đơn đặt cùng lúc không khóa chéo nhau (deadlock).
        if (request.items() == null || request.items().isEmpty()) {
            throw bad("Đơn hàng chưa có sản phẩm nào");
        }
        Map<Integer, Integer> wanted = new TreeMap<>();
        for (ItemRequest item : request.items()) {
            if (item == null || item.quantity() <= 0) {
                throw bad("Số lượng sản phẩm phải lớn hơn 0");
            }
            wanted.merge(item.productDetailId(), item.quantity(), Integer::sum);
        }

        // 3. Lấy giá + tồn kho hiện tại từ database, kiểm tra sớm để báo lỗi rõ ràng
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

        // 4. Trừ kho nguyên tử. Đây mới là chốt chặn thật sự: nếu người khác vừa mua mất thì
        //    câu lệnh không cập nhật được dòng nào và toàn bộ đơn bị rollback (kho đã trừ ở dòng trước được hoàn lại).
        for (Map.Entry<Integer, Integer> e : wanted.entrySet()) {
            if (productDetailRepository.decreaseStock(e.getKey(), e.getValue()) == 0) {
                throw bad(describe(rows.get(e.getKey())) + " vừa hết hàng hoặc không còn đủ số lượng, vui lòng kiểm tra lại giỏ hàng");
            }
        }

        // 5. Ghi Orders. Mã đơn dạng DH0001 lấy theo id nên lưu mã tạm trước rồi đổi sang mã chính thức.
        Order order = new Order();
        order.setOrderCode("T" + UUID.randomUUID().toString().substring(0, 7));
        order.setAccountId(accountId);
        order.setCustomerName(name);
        order.setPhone(phone);
        order.setAddress(address);
        order.setNote(clean(request.note()).isEmpty() ? null : clean(request.note()));
        order.setTotalAmount(total);
        order.setPaymentMethod(request.paymentMethod());
        order.setPaymentStatus(0);
        order.setStatus(STATUS_PENDING);
        order.setCreatedAt(LocalDateTime.now());
        order = orderRepository.save(order);
        order.setOrderCode(String.format("DH%04d", order.getId()));
        order = orderRepository.save(order);

        // 6. Ghi OrderDetail, giá chốt tại thời điểm đặt
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

    // Cộng tồn kho lại theo các dòng của đơn (khi hủy đơn). Xử lý theo id tăng dần như lúc trừ.
    private void restoreStock(int orderId) {
        List<OrderDetail> details = entityManager
                .createQuery("select d from OrderDetail d where d.orderId = :orderId order by d.productDetailId",
                        OrderDetail.class)
                .setParameter("orderId", orderId)
                .getResultList();
        for (OrderDetail d : details) {
            productDetailRepository.increaseStock(d.getProductDetailId(), d.getQuantity());
        }
    }

    private static String label(int status) {
        return status >= 0 && status < STATUS_LABELS.length ? STATUS_LABELS[status] : "Trạng thái " + status;
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