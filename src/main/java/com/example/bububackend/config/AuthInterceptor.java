package com.example.bububackend.config;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

// Chặn mọi API /api/** theo session: kiểm tra đã đăng nhập chưa và có đủ quyền không.
@Component
public class AuthInterceptor implements HandlerInterceptor {

    public static final String SESSION_ACCOUNT_ID = "accountId";
    public static final String SESSION_ROLE = "role";

    // POST không cần đăng nhập
    private static final Set<String> PUBLIC_POST = Set.of(
            "/api/auth/login",
            "/api/auth/register",
            "/api/auth/logout",
            "/api/carts/preview",
            "/api/favorites/preview",
            "/api/orders");

    // GET không cần đăng nhập (khách xem hàng)
    private static final List<String> PUBLIC_GET = List.of(
            "/api/products",
            "/api/categories",
            "/api/sizes",
            "/api/colors",
            "/api/product-details",
            "/api/images",
            "/api/orders/track");

    // /api/carts/{accountId} hoặc /api/carts/{accountId}/...
    private static final Pattern CART_PATH = Pattern.compile("^/api/carts/(\\d{1,9})(/.*)?$");

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws IOException {

        String method = request.getMethod();
        if ("OPTIONS".equals(method)) {
            return true; // yêu cầu thăm dò CORS
        }

        // getServletPath đã được chuẩn hóa (bỏ ".." và giải mã), an toàn hơn getRequestURI
        String path = request.getServletPath();
        if (path.contains("..")) {
            return deny(response, 400, "Bad Request", "Đường dẫn không hợp lệ");
        }
        while (path.length() > 1 && path.endsWith("/")) {
            path = path.substring(0, path.length() - 1);
        }

        // 1. Công khai
        if (isPublic(method, path)) {
            return true;
        }

        // 2. Từ đây trở đi bắt buộc đã đăng nhập
        HttpSession session = request.getSession(false);
        Integer accountId = session == null ? null : (Integer) session.getAttribute(SESSION_ACCOUNT_ID);
        String role = session == null ? null : (String) session.getAttribute(SESSION_ROLE);
        if (accountId == null) {
            return deny(response, 401, "Unauthorized", "Vui lòng đăng nhập");
        }

        // 3. Giỏ hàng: chỉ chủ giỏ được dùng
        Matcher cart = CART_PATH.matcher(path);
        if (cart.matches()) {
            if (accountId == Integer.parseInt(cart.group(1))) {
                return true;
            }
            return deny(response, 403, "Forbidden", "Bạn không có quyền truy cập giỏ hàng này");
        }

        // 4. Việc của chính tài khoản đang đăng nhập: ai đăng nhập cũng được
        //    - xem / sửa thông tin cá nhân, đổi mật khẩu
        //    - xem lịch sử đơn của mình (service tự kiểm tra đơn có thuộc tài khoản này không)
        if (path.equals("/api/auth/me") && ("GET".equals(method) || "PUT".equals(method))) {
            return true;
        }
        if (path.equals("/api/auth/password") && "PUT".equals(method)) {
            return true;
        }
        if ("GET".equals(method) && (path.equals("/api/orders/my") || path.startsWith("/api/orders/my/"))) {
            return true;
        }

        // 4b. Yêu thích: ai đăng nhập cũng được (service chỉ dùng accountId của chính session)
        if (path.equals("/api/favorites") || path.startsWith("/api/favorites/")) {
            return true;
        }

        // 4c. Khách đã đăng nhập tự hủy đơn của mình (service kiểm tra đơn có đúng của họ không)
        if ("POST".equals(method) && path.matches("^/api/orders/my/\\d{1,9}/cancel$")) {
            return true;
        }

        // 5. Còn lại chỉ ADMIN
        if ("ADMIN".equals(role)) {
            return true;
        }
        return deny(response, 403, "Forbidden", "Bạn không có quyền thực hiện thao tác này");
    }

    private boolean isPublic(String method, String path) {
        if ("POST".equals(method)) {
            return PUBLIC_POST.contains(path);
        }
        if ("GET".equals(method)) {
            for (String prefix : PUBLIC_GET) {
                if (path.equals(prefix) || path.startsWith(prefix + "/")) {
                    return true;
                }
            }
        }
        return false;
    }

    private boolean deny(HttpServletResponse response, int status, String error, String message)
            throws IOException {
        response.setStatus(status);
        response.setContentType("application/json;charset=UTF-8");
        response.getWriter().write(
                "{\"status\":" + status + ",\"error\":\"" + error + "\",\"message\":\"" + message + "\"}");
        return false;
    }

    // accountId của phiên đăng nhập; chưa đăng nhập thì ném 401
    public static int requireAccountId(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        Integer id = session == null ? null : (Integer) session.getAttribute(SESSION_ACCOUNT_ID);
        if (id == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Vui lòng đăng nhập");
        }
        return id;
    }
}