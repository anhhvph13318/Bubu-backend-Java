package com.example.bububackend.service;

import com.example.bububackend.DTO.FavoriteIdsRequest;
import com.example.bububackend.DTO.FavoriteView;
import com.example.bububackend.model.Favorite;
import com.example.bububackend.model.ImageInfo;
import com.example.bububackend.model.Product;
import com.example.bububackend.repository.FavoriteRepository;
import com.example.bububackend.repository.ImageRepository;
import com.example.bububackend.repository.ProductDetailRepository;
import com.example.bububackend.repository.ProductRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Sản phẩm yêu thích. Khách đã đăng nhập lưu trong database (bảng Favorite) theo accountId;
 * khách chưa đăng nhập giữ danh sách id ở localStorage, dùng preview() để lấy thông tin và merge() khi đăng nhập.
 * Chỉ sản phẩm đang bán (Status = 1) mới được thêm và mới hiện trong danh sách.
 */
@Service
public class FavoriteService {

    public static final int MAX_FAVORITES = 200;
    private static final int PRODUCT_ACTIVE = 1; // Product.Status: 1 = đang bán, 0 = ẩn

    private final FavoriteRepository favoriteRepository;
    private final ProductRepository productRepository;
    private final ProductDetailRepository productDetailRepository;
    private final ImageRepository imageRepository;

    public FavoriteService(FavoriteRepository favoriteRepository, ProductRepository productRepository,
                           ProductDetailRepository productDetailRepository, ImageRepository imageRepository) {
        this.favoriteRepository = favoriteRepository;
        this.productRepository = productRepository;
        this.productDetailRepository = productDetailRepository;
        this.imageRepository = imageRepository;
    }

    // ---------- Khách đã đăng nhập ----------

    // Danh sách yêu thích (mới thêm lên đầu), bỏ qua sản phẩm đã ẩn
    public List<FavoriteView> list(int accountId) {
        Map<Integer, LocalDateTime> addedAt = new LinkedHashMap<>();
        for (Favorite f : favoriteRepository.findByAccountIdOrderByCreatedAtDescIdDesc(accountId)) {
            addedAt.put(f.getProductId(), f.getCreatedAt());
        }
        return buildViews(addedAt);
    }

    // Chỉ id sản phẩm, để app tô màu trái tim ở danh sách sản phẩm
    public List<Integer> ids(int accountId) {
        return favoriteRepository.findProductIdsByAccountId(accountId);
    }

    // Thêm yêu thích. Đã thích rồi thì không báo lỗi (an toàn khi app gửi lại hoặc bấm đúp).
    public void add(int accountId, int productId) {
        Product product = productRepository.findById(productId).orElse(null);
        if (product == null || product.getStatus() != PRODUCT_ACTIVE) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Sản phẩm không tồn tại hoặc đã ngừng bán");
        }
        if (favoriteRepository.existsByAccountIdAndProductId(accountId, productId)) {
            return;
        }
        if (favoriteRepository.countByAccountId(accountId) >= MAX_FAVORITES) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST,
                    "Danh sách yêu thích đã đầy (tối đa " + MAX_FAVORITES + " sản phẩm)");
        }
        try {
            favoriteRepository.saveAndFlush(newFavorite(accountId, productId));
        } catch (DataIntegrityViolationException e) {
            // Hai yêu cầu cùng thêm một sản phẩm: ràng buộc UNIQUE chặn dòng thứ hai, coi như đã thêm.
            // Nếu vẫn chưa có thì nguyên nhân là sản phẩm vừa bị xóa.
            if (!favoriteRepository.existsByAccountIdAndProductId(accountId, productId)) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Sản phẩm không tồn tại hoặc đã ngừng bán");
            }
        }
    }

    // Bỏ yêu thích. Chưa thích thì coi như đã bỏ.
    @Transactional
    public void remove(int accountId, int productId) {
        favoriteRepository.removeFavorite(accountId, productId);
    }

    // Gộp danh sách localStorage vào tài khoản khi khách đăng nhập.
    // Bỏ id trùng / không hợp lệ / sản phẩm không còn bán; vượt giới hạn thì bỏ phần dư.
    // Trả danh sách yêu thích sau khi gộp.
    public List<FavoriteView> merge(int accountId, FavoriteIdsRequest request) {
        Set<Integer> wanted = normalize(request);
        if (!wanted.isEmpty()) {
            Set<Integer> existing = new HashSet<>(favoriteRepository.findProductIdsByAccountId(accountId));
            Map<Integer, Product> products = productRepository.findAllById(wanted).stream()
                    .collect(Collectors.toMap(Product::getId, p -> p, (a, b) -> a));
            int count = existing.size();
            for (Integer productId : wanted) {
                if (existing.contains(productId)) {
                    continue;
                }
                Product product = products.get(productId);
                if (product == null || product.getStatus() != PRODUCT_ACTIVE) {
                    continue;
                }
                if (count >= MAX_FAVORITES) {
                    break;
                }
                try {
                    favoriteRepository.saveAndFlush(newFavorite(accountId, productId));
                    count++;
                } catch (DataIntegrityViolationException e) {
                    // vừa được thêm ở nơi khác: bỏ qua
                }
            }
        }
        return list(accountId);
    }

    // ---------- Khách chưa đăng nhập ----------

    // Nhận danh sách id từ localStorage, trả tên, giá, ảnh, tồn kho hiện tại. Không ghi gì vào database.
    public List<FavoriteView> preview(FavoriteIdsRequest request) {
        Map<Integer, LocalDateTime> ids = new LinkedHashMap<>();
        for (Integer id : normalize(request)) {
            ids.put(id, null);
        }
        return buildViews(ids);
    }

    // ---------- Hàm hỗ trợ ----------

    private Favorite newFavorite(int accountId, int productId) {
        Favorite f = new Favorite();
        f.setAccountId(accountId);
        f.setProductId(productId);
        f.setCreatedAt(LocalDateTime.now());
        return f;
    }

    // Bỏ null / id không dương / trùng, giữ thứ tự, tối đa MAX_FAVORITES id
    private static Set<Integer> normalize(FavoriteIdsRequest request) {
        Set<Integer> result = new LinkedHashSet<>();
        if (request != null && request.productIds() != null) {
            for (Integer id : request.productIds()) {
                if (id != null && id > 0) {
                    result.add(id);
                }
                if (result.size() >= MAX_FAVORITES) {
                    break;
                }
            }
        }
        return result;
    }

    // Dựng danh sách hiển thị theo đúng thứ tự của map; sản phẩm đã xóa hoặc ẩn thì bỏ qua
    private List<FavoriteView> buildViews(Map<Integer, LocalDateTime> addedAt) {
        if (addedAt.isEmpty()) {
            return List.of();
        }
        Set<Integer> ids = addedAt.keySet();

        Map<Integer, Product> products = productRepository.findAllById(ids).stream()
                .collect(Collectors.toMap(Product::getId, p -> p, (a, b) -> a));
        Map<Integer, ImageInfo> mainImages = imageRepository.findMainInfoByProductIds(ids).stream()
                .collect(Collectors.toMap(ImageInfo::productId, i -> i, (a, b) -> a));
        Map<Integer, Integer> stock = new HashMap<>();
        for (Object[] row : productDetailRepository.sumQuantityByProductIds(ids)) {
            stock.put(((Number) row[0]).intValue(), ((Number) row[1]).intValue());
        }

        List<FavoriteView> views = new ArrayList<>();
        for (Map.Entry<Integer, LocalDateTime> e : addedAt.entrySet()) {
            Product p = products.get(e.getKey());
            if (p == null || p.getStatus() != PRODUCT_ACTIVE) {
                continue;
            }
            ImageInfo image = mainImages.get(p.getId());
            String imageUrl = image == null ? p.getImageUrl()
                    : "/api/images/" + image.id() + "/file?v=" + image.version();
            views.add(new FavoriteView(p.getId(), p.getName(), p.getPrice(), imageUrl,
                    stock.getOrDefault(p.getId(), 0), e.getValue()));
        }
        return views;
    }
}