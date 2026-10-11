package com.example.bububackend.controller;

import com.example.bububackend.DTO.PaymentOutcome;
import com.example.bububackend.model.Order;
import com.example.bububackend.response.ApiResponse;
import com.example.bububackend.service.OrderService;
import com.example.bububackend.service.VnpayService;
import jakarta.servlet.http.HttpServletRequest;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * Thanh toán VNPay.
 * Luồng: POST /api/orders (paymentMethod = 1) -> POST /create lấy paymentUrl -> khách trả tiền trên VNPay
 *        -> VNPay chuyển trình duyệt về /return (và gọi /ipn nếu server có địa chỉ công khai).
 * Cả /return và /ipn đều kiểm tra chữ ký + số tiền rồi cập nhật đơn bằng cùng một hàm, chạy lặp lại vẫn an toàn.
 */
@RestController
@RequestMapping("/api/payment/vnpay")
public class PaymentController {

    private static final Logger log = LoggerFactory.getLogger(PaymentController.class);

    public record CreateRequest(String trackingCode) {
    }

    public record PaymentLink(String orderCode, String paymentUrl) {
    }

    private record Processed(PaymentOutcome outcome, String orderCode, String responseCode) {
    }

    private final OrderService orderService;
    private final VnpayService vnpay;

    public PaymentController(OrderService orderService, VnpayService vnpay) {
        this.orderService = orderService;
        this.vnpay = vnpay;
    }

    // POST /api/payment/vnpay/create - body: {"trackingCode": "..."} (mã tra cứu nhận khi đặt đơn VNPay).
    // Trả về paymentUrl: mở link này (trình duyệt / WebView) để khách thanh toán.
    @PostMapping("/create")
    public ResponseEntity<ApiResponse<PaymentLink>> create(@RequestBody CreateRequest request,
                                                           HttpServletRequest http) {
        Order order = orderService.getPayableOrder(request == null ? null : request.trackingCode());
        String url = vnpay.createPaymentUrl(order, clientIp(http));
        return ResponseEntity.ok(new ApiResponse<>(new PaymentLink(order.getOrderCode(), url), true, null, null));
    }

    // GET /api/payment/vnpay/return - VNPay chuyển trình duyệt của khách về đây. Hiện trang kết quả đơn giản.
    // Ứng dụng nên đọc lại kết quả thật bằng GET /api/orders/track/{trackingCode} (trường paymentStatus).
    @GetMapping(value = "/return", produces = MediaType.TEXT_HTML_VALUE + ";charset=UTF-8")
    public String returnPage(@RequestParam Map<String, String> params) {
        try {
            return resultPage(process(params));
        } catch (Exception e) {
            log.error("Lỗi xử lý kết quả VNPay (return)", e);
            return html(false, "Có lỗi khi xử lý",
                    "Vui lòng kiểm tra lại trạng thái đơn hàng hoặc liên hệ cửa hàng.");
        }
    }

    // GET /api/payment/vnpay/ipn - VNPay gọi từ máy chủ của họ (cần địa chỉ HTTPS công khai).
    // Trả JSON {RspCode, Message} theo quy định của VNPay.
    @GetMapping("/ipn")
    public Map<String, String> ipn(@RequestParam Map<String, String> params) {
        try {
            Processed p = process(params);
            return switch (p.outcome()) {
                case INVALID_SIGNATURE -> rsp("97", "Invalid signature");
                case NOT_FOUND -> rsp("01", "Order not found");
                case AMOUNT_MISMATCH -> rsp("04", "invalid amount");
                case ALREADY_PAID -> rsp("02", "Order already confirmed");
                case PAID, PAID_BUT_CANCELLED, FAILED_CANCELLED, FAILED_NO_CHANGE -> rsp("00", "Confirm Success");
            };
        } catch (Exception e) {
            log.error("Lỗi xử lý kết quả VNPay (ipn)", e);
            return rsp("99", "Unknown error");
        }
    }

    // Kiểm tra chữ ký rồi ghi nhận kết quả vào đơn
    private Processed process(Map<String, String> params) {
        if (!vnpay.verify(params)) {
            return new Processed(PaymentOutcome.INVALID_SIGNATURE, null, null);
        }
        String responseCode = params.get("vnp_ResponseCode");
        String orderCode = vnpay.orderCodeOf(params.get("vnp_TxnRef"));
        if (orderCode == null) {
            return new Processed(PaymentOutcome.NOT_FOUND, null, responseCode);
        }
        PaymentOutcome outcome = orderService.applyOnlinePayment(
                orderCode, vnpay.amountOf(params), vnpay.isSuccess(params));
        return new Processed(outcome, orderCode, responseCode);
    }

    private String resultPage(Processed p) {
        String code = p.orderCode() == null ? "" : " " + p.orderCode();
        return switch (p.outcome()) {
            case PAID, ALREADY_PAID -> html(true, "Thanh toán thành công",
                    "Đơn hàng" + code + " đã được ghi nhận thanh toán. Cửa hàng sẽ xác nhận đơn sớm nhất.");
            case PAID_BUT_CANCELLED -> html(false, "Đã nhận thanh toán nhưng đơn đã bị hủy",
                    "Đơn hàng" + code + " đã bị hủy do quá thời gian thanh toán. Cửa hàng sẽ liên hệ để hoàn tiền cho bạn.");
            case FAILED_CANCELLED -> html(false, "Thanh toán không thành công",
                    vnpay.describe(p.responseCode()) + ". Đơn hàng" + code + " đã được hủy.");
            case FAILED_NO_CHANGE -> html(false, "Thanh toán không thành công",
                    vnpay.describe(p.responseCode()) + ".");
            case INVALID_SIGNATURE -> html(false, "Dữ liệu không hợp lệ",
                    "Không xác minh được kết quả thanh toán.");
            case NOT_FOUND, AMOUNT_MISMATCH -> html(false, "Không xác nhận được giao dịch",
                    "Không tìm thấy đơn hàng hoặc số tiền không khớp. Vui lòng liên hệ cửa hàng.");
        };
    }

    private static String html(boolean ok, String title, String message) {
        String color = ok ? "#15803d" : "#dc2626";
        return "<!DOCTYPE html><html lang=\"vi\"><head><meta charset=\"UTF-8\">"
                + "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
                + "<title>Kết quả thanh toán - BuBu Sport</title>"
                + "<style>body{font-family:Arial,sans-serif;background:#f5f7fb;display:flex;align-items:center;"
                + "justify-content:center;min-height:100vh;margin:0}"
                + ".card{background:#fff;padding:36px;border-radius:16px;max-width:420px;margin:16px;"
                + "box-shadow:0 15px 40px rgba(0,0,0,.08);text-align:center}"
                + "h1{font-size:22px;margin:0 0 12px;color:" + color + "}"
                + "p{color:#4b5563;line-height:1.5;margin:0}</style></head>"
                + "<body><div class=\"card\"><h1>" + esc(title) + "</h1><p>" + esc(message) + "</p></div></body></html>";
    }

    private static String esc(String s) {
        return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;").replace("\"", "&quot;");
    }

    private static Map<String, String> rsp(String code, String message) {
        Map<String, String> m = new LinkedHashMap<>();
        m.put("RspCode", code);
        m.put("Message", message);
        return m;
    }

    // IP của khách; localhost dạng IPv6 (có dấu ':') thì dùng 127.0.0.1 vì VNPay không nhận
    private static String clientIp(HttpServletRequest http) {
        String ip = http.getRemoteAddr();
        return ip == null || ip.isBlank() || ip.contains(":") ? "127.0.0.1" : ip;
    }
}