package com.example.bububackend.service;

import com.example.bububackend.DTO.CartItemsRequest;
import com.example.bububackend.DTO.CartLineView;
import com.example.bububackend.DTO.CartProductRow;
import com.example.bububackend.DTO.CartView;
import com.example.bububackend.DTO.ItemRequest;
import com.example.bububackend.model.Cart;
import com.example.bububackend.model.CartItem;
import com.example.bububackend.model.ImageInfo;
import com.example.bububackend.model.ProductDetail;
import com.example.bububackend.repository.CartItemRepository;
import com.example.bububackend.repository.CartRepository;
import com.example.bububackend.repository.ImageRepository;
import com.example.bububackend.repository.ProductDetailRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Giỏ hàng của khách ĐÃ ĐĂNG NHẬP, lưu trong database theo accountId (mỗi tài khoản đúng 1 giỏ).
 * Khách chưa đăng nhập giữ giỏ ở localStorage; dùng preview() để lấy giá / tồn kho và merge() khi đăng nhập.
 * Thêm vào giỏ KHÔNG trừ tồn kho, chỉ kiểm tra còn đủ hàng.
 */
@Service
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository itemRepository;
    private final ProductDetailRepository detailRepository;
    private final ImageRepository imageRepository;

    public CartService(CartRepository cartRepository, CartItemRepository itemRepository,
                       ProductDetailRepository detailRepository, ImageRepository imageRepository) {
        this.cartRepository = cartRepository;
        this.itemRepository = itemRepository;
        this.detailRepository = detailRepository;
        this.imageRepository = imageRepository;
    }

    // ---------- Xem giỏ ----------

    // Giỏ của tài khoản; chưa có giỏ thì trả giỏ rỗng (giỏ chỉ được tạo khi thêm sản phẩm đầu tiên)
    public CartView getCart(int accountId) {
        Cart cart = cartRepository.findByAccountId(accountId).orElse(null);
        if (cart == null) {
            return buildView(List.of());
        }
        List<ItemRequest> lines = itemRepository.findByCartIdOrderByIdAsc(cart.getId()).stream()
                .map(i -> new ItemRequest(i.getProductDetailId(), i.getQuantity()))
                .toList();
        return buildView(lines);
    }

    // Giỏ của khách chưa đăng nhập (localStorage gửi lên): trả tên, ảnh, giá, tồn kho hiện tại. Không ghi gì vào database.
    public CartView preview(CartItemsRequest request) {
        return buildView(toLines(aggregate(request)));
    }

    // ---------- Sửa giỏ ----------

    // Thêm một biến thể vào giỏ; đã có thì cộng dồn số lượng
    @Transactional
    public CartView addItem(int accountId, ItemRequest request) {
        requirePositive(request.quantity());
        ProductDetail detail = findDetail(request.productDetailId());
        Cart cart = cartRepository.findByAccountId(accountId).orElseGet(() -> createCart(accountId));

        CartItem item = itemRepository.findByCartIdAndProductDetailId(cart.getId(), detail.getId()).orElse(null);
        int newQuantity = (item == null ? 0 : item.getQuantity()) + request.quantity();
        checkStock(detail, newQuantity);

        if (item == null) {
            item = new CartItem();
            item.setCartId(cart.getId());
            item.setProductDetailId(detail.getId());
            item.setCreatedAt(LocalDateTime.now());
        }
        item.setQuantity(newQuantity);
        itemRepository.save(item);
        touch(cart);
        return getCart(accountId);
    }

    // Đặt lại số lượng của một dòng trong giỏ
    @Transactional
    public CartView updateQuantity(int accountId, int productDetailId, int quantity) {
        requirePositive(quantity);
        Cart cart = findCart(accountId);
        CartItem item = itemRepository.findByCartIdAndProductDetailId(cart.getId(), productDetailId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sản phẩm này không có trong giỏ"));
        checkStock(findDetail(productDetailId), quantity);
        item.setQuantity(quantity);
        itemRepository.save(item);
        touch(cart);
        return getCart(accountId);
    }

    // Xóa một dòng khỏi giỏ (không có dòng đó thì coi như đã xóa)
    @Transactional
    public CartView removeItem(int accountId, int productDetailId) {
        Cart cart = cartRepository.findByAccountId(accountId).orElse(null);
        if (cart != null) {
            itemRepository.findByCartIdAndProductDetailId(cart.getId(), productDetailId).ifPresent(itemRepository::delete);
            touch(cart);
        }
        return getCart(accountId);
    }

    // Xóa sạch giỏ; giữ lại Cart rỗng để lần sau dùng lại
    @Transactional
    public CartView clear(int accountId) {
        Cart cart = cartRepository.findByAccountId(accountId).orElse(null);
        if (cart != null) {
            itemRepository.deleteAllByCartId(cart.getId());
            touch(cart);
        }
        return getCart(accountId);
    }

    // Gộp giỏ localStorage của khách vào giỏ trong database khi khách đăng nhập.
    // Số lượng cộng dồn nhưng không vượt tồn kho; biến thể không còn hoặc hết hàng thì bỏ qua.
    @Transactional
    public CartView merge(int accountId, CartItemsRequest request) {
        Map<Integer, Integer> wanted = aggregate(request);
        if (!wanted.isEmpty()) {
            Cart cart = cartRepository.findByAccountId(accountId).orElseGet(() -> createCart(accountId));
            for (Map.Entry<Integer, Integer> e : wanted.entrySet()) {
                ProductDetail detail = detailRepository.findById(e.getKey()).orElse(null);
                if (detail == null || detail.getQuantity() <= 0) {
                    continue;
                }
                CartItem item = itemRepository.findByCartIdAndProductDetailId(cart.getId(), detail.getId()).orElse(null);
                int newQuantity = Math.min((item == null ? 0 : item.getQuantity()) + e.getValue(), detail.getQuantity());
                if (item == null) {
                    item = new CartItem();
                    item.setCartId(cart.getId());
                    item.setProductDetailId(detail.getId());
                    item.setCreatedAt(LocalDateTime.now());
                }
                item.setQuantity(newQuantity);
                itemRepository.save(item);
            }
            touch(cart);
        }
        return getCart(accountId);
    }

    // ---------- Hàm hỗ trợ ----------

    private Cart createCart(int accountId) {
        Cart cart = new Cart();
        cart.setAccountId(accountId);
        cart.setCreatedAt(LocalDateTime.now());
        cart.setUpdatedAt(LocalDateTime.now());
        return cartRepository.save(cart);
    }

    private Cart findCart(int accountId) {
        return cartRepository.findByAccountId(accountId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Giỏ hàng đang trống"));
    }

    private void touch(Cart cart) {
        cart.setUpdatedAt(LocalDateTime.now());
        cartRepository.save(cart);
    }

    private ProductDetail findDetail(int productDetailId) {
        return detailRepository.findById(productDetailId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND,
                        "Không tìm thấy sản phẩm (biến thể " + productDetailId + ")"));
    }

    private void requirePositive(int quantity) {
        if (quantity <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Số lượng phải lớn hơn 0");
        }
    }

    // Chỉ kiểm tra còn đủ hàng, không trừ tồn kho
    private void checkStock(ProductDetail detail, int quantity) {
        if (detail.getQuantity() <= 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Sản phẩm này đã hết hàng");
        }
        if (quantity > detail.getQuantity()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Chỉ còn " + detail.getQuantity() + " sản phẩm trong kho");
        }
    }

    // Gộp các dòng trùng biến thể (cộng số lượng), bỏ dòng số lượng không hợp lệ
    private Map<Integer, Integer> aggregate(CartItemsRequest request) {
        Map<Integer, Integer> result = new LinkedHashMap<>();
        if (request != null && request.items() != null) {
            for (ItemRequest r : request.items()) {
                if (r != null && r.quantity() > 0) {
                    result.merge(r.productDetailId(), r.quantity(), Integer::sum);
                }
            }
        }
        return result;
    }

    private List<ItemRequest> toLines(Map<Integer, Integer> map) {
        return map.entrySet().stream().map(e -> new ItemRequest(e.getKey(), e.getValue())).toList();
    }

    // Dựng giỏ để hiển thị: giá, tên, ảnh, tồn kho luôn lấy mới nhất từ database
    private CartView buildView(List<ItemRequest> lines) {
        if (lines.isEmpty()) {
            return new CartView(List.of(), 0, BigDecimal.ZERO, false);
        }
        Set<Integer> ids = lines.stream().map(ItemRequest::productDetailId).collect(Collectors.toCollection(LinkedHashSet::new));
        Map<Integer, CartProductRow> rows = detailRepository.findCartRows(ids).stream()
                .collect(Collectors.toMap(CartProductRow::detailId, r -> r, (a, b) -> a));
        Set<Integer> productIds = rows.values().stream().map(CartProductRow::productId).collect(Collectors.toSet());
        Map<Integer, ImageInfo> mainImages = productIds.isEmpty() ? Map.of()
                : imageRepository.findMainInfoByProductIds(productIds).stream()
                .collect(Collectors.toMap(ImageInfo::productId, i -> i, (a, b) -> a));

        List<CartLineView> views = new ArrayList<>();
        int totalQuantity = 0;
        BigDecimal totalAmount = BigDecimal.ZERO;
        boolean hasIssues = false;

        for (ItemRequest line : lines) {
            CartProductRow row = rows.get(line.productDetailId());
            if (row == null) { // biến thể đã bị xóa (chỉ xảy ra với giỏ localStorage)
                views.add(new CartLineView(line.productDetailId(), 0, "(Sản phẩm không còn tồn tại)", null,
                        null, null, null, BigDecimal.ZERO, line.quantity(), 0, BigDecimal.ZERO,
                        false, "Sản phẩm không còn tồn tại"));
                hasIssues = true;
                continue;
            }
            BigDecimal price = toMoney(row.price());
            BigDecimal lineTotal = price.multiply(BigDecimal.valueOf(line.quantity()));
            boolean ok = row.stock() > 0 && line.quantity() <= row.stock();
            String message = row.stock() <= 0 ? "Hết hàng"
                    : line.quantity() > row.stock() ? "Chỉ còn " + row.stock() + " sản phẩm" : null;
            ImageInfo image = mainImages.get(row.productId());
            String imageUrl = image == null ? null : "/api/images/" + image.id() + "/file?v=" + image.version();

            views.add(new CartLineView(row.detailId(), row.productId(), row.productName(), imageUrl,
                    row.sizeName(), row.colorName(), row.colorHex(), price, line.quantity(), row.stock(),
                    lineTotal, ok, message));
            totalQuantity += line.quantity();
            totalAmount = totalAmount.add(lineTotal);
            hasIssues |= !ok;
        }
        return new CartView(views, totalQuantity, totalAmount, hasIssues);
    }

    static BigDecimal toMoney(Object value) {
        if (value == null) {
            return BigDecimal.ZERO;
        }
        if (value instanceof BigDecimal b) {
            return b;
        }
        return new BigDecimal(value.toString());
    }
}