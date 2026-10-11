package com.example.bububackend.service;

import com.example.bububackend.model.Order;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.math.RoundingMode;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

/**
 * Tạo link thanh toán VNPay và kiểm tra chữ ký kết quả trả về (VNPay API 2.1.0, HMAC SHA512).
 * Cấu hình đặt trong secrets.properties (xem hướng dẫn); chưa cấu hình thì chỉ VNPay bị tắt, COD vẫn chạy.
 */
@Service
public class VnpayService {

    // Lưu ý: ví dụ Java của VNPay ghi "Etc/GMT+7" nhưng đó là UTC-7. Việt Nam là Asia/Ho_Chi_Minh (UTC+7).
    private static final ZoneId VN_ZONE = ZoneId.of("Asia/Ho_Chi_Minh");
    private static final DateTimeFormatter VNP_TIME = DateTimeFormatter.ofPattern("yyyyMMddHHmmss");

    // vnp_TxnRef = mã đơn + "T" + mốc thời gian (VNPay không cho trùng trong ngày, kể cả khi làm lại database)
    private static final Pattern TXN_REF = Pattern.compile("^(DH\\d+)T\\d+$");

    private final String tmnCode;
    private final String hashSecret;
    private final String payUrl;
    private final String returnUrl;

    public VnpayService(@Value("${vnpay.tmn-code:}") String tmnCode,
                        @Value("${vnpay.hash-secret:}") String hashSecret,
                        @Value("${vnpay.pay-url:https://sandbox.vnpayment.vn/paymentv2/vpcpay.html}") String payUrl,
                        @Value("${vnpay.return-url:}") String returnUrl) {
        this.tmnCode = tmnCode;
        this.hashSecret = hashSecret;
        this.payUrl = payUrl;
        this.returnUrl = returnUrl;
    }

    // Link thanh toán cho một đơn. Hạn thanh toán trên VNPay = lúc tạo đơn + 15 phút (khớp với lúc đơn tự hủy).
    public String createPaymentUrl(Order order, String ipAddress) {
        if (tmnCode.isBlank() || hashSecret.isBlank() || returnUrl.isBlank()) {
            throw new ResponseStatusException(HttpStatus.SERVICE_UNAVAILABLE, "VNPay chưa được cấu hình trên máy chủ");
        }
        ZonedDateTime now = ZonedDateTime.now(VN_ZONE);
        ZonedDateTime expire = order.getCreatedAt().atZone(ZoneId.systemDefault())
                .withZoneSameInstant(VN_ZONE).plusMinutes(OrderService.PAYMENT_WINDOW_MINUTES);
        if (!expire.isAfter(now.plusMinutes(1))) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Đơn hàng đã quá hạn thanh toán");
        }

        long amount = order.getTotalAmount().setScale(0, RoundingMode.HALF_UP).longValue() * 100;

        Map<String, String> params = new TreeMap<>();
        params.put("vnp_Version", "2.1.0");
        params.put("vnp_Command", "pay");
        params.put("vnp_TmnCode", tmnCode);
        params.put("vnp_Amount", String.valueOf(amount));
        params.put("vnp_CreateDate", now.format(VNP_TIME));
        params.put("vnp_CurrCode", "VND");
        params.put("vnp_IpAddr", ipAddress);
        params.put("vnp_Locale", "vn");
        params.put("vnp_OrderInfo", "Thanh toan don hang " + order.getOrderCode()); // không dấu, không ký tự đặc biệt
        params.put("vnp_OrderType", "other");
        params.put("vnp_ReturnUrl", returnUrl);
        params.put("vnp_ExpireDate", expire.format(VNP_TIME));
        params.put("vnp_TxnRef", order.getOrderCode() + "T" + now.toEpochSecond());

        String query = buildQuery(params);
        return payUrl + "?" + query + "&vnp_SecureHash=" + hmacSha512(hashSecret, query);
    }

    // Kiểm tra chữ ký của kết quả VNPay trả về (trang trả về và IPN dùng chung)
    public boolean verify(Map<String, String> params) {
        String given = params.get("vnp_SecureHash");
        if (given == null || given.isBlank() || hashSecret.isBlank()) {
            return false;
        }
        Map<String, String> data = new TreeMap<>();
        for (Map.Entry<String, String> e : params.entrySet()) {
            String key = e.getKey();
            if (key.startsWith("vnp_") && !key.equals("vnp_SecureHash") && !key.equals("vnp_SecureHashType")) {
                data.put(key, e.getValue());
            }
        }
        String expected = hmacSha512(hashSecret, buildQuery(data));
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.US_ASCII),
                given.toLowerCase().getBytes(StandardCharsets.US_ASCII));
    }

    // Giao dịch thành công khi vnp_ResponseCode = 00 (và vnp_TransactionStatus = 00 nếu có)
    public boolean isSuccess(Map<String, String> params) {
        String status = params.get("vnp_TransactionStatus");
        return "00".equals(params.get("vnp_ResponseCode")) && (status == null || "00".equals(status));
    }

    // Số tiền VNPay báo (đã nhân 100); -1 nếu không đọc được
    public long amountOf(Map<String, String> params) {
        try {
            return Long.parseLong(params.get("vnp_Amount"));
        } catch (Exception e) {
            return -1;
        }
    }

    // Tách mã đơn (DH0007) từ vnp_TxnRef (DH0007T1760090123); không đúng dạng thì trả null
    public String orderCodeOf(String txnRef) {
        Matcher m = TXN_REF.matcher(txnRef == null ? "" : txnRef);
        return m.matches() ? m.group(1) : null;
    }

    // Lý do thất bại để hiện cho khách
    public String describe(String responseCode) {
        if (responseCode == null) {
            return "Giao dịch không thành công";
        }
        return switch (responseCode) {
            case "07" -> "Giao dịch bị nghi ngờ gian lận";
            case "09" -> "Thẻ chưa đăng ký dịch vụ thanh toán trực tuyến";
            case "10" -> "Xác thực thông tin thẻ sai quá số lần quy định";
            case "11" -> "Đã hết thời gian chờ thanh toán";
            case "12" -> "Thẻ hoặc tài khoản bị khóa";
            case "13" -> "Sai mật khẩu xác thực giao dịch (OTP)";
            case "24" -> "Bạn đã hủy giao dịch";
            case "51" -> "Tài khoản không đủ số dư";
            case "65" -> "Tài khoản vượt hạn mức giao dịch trong ngày";
            case "75" -> "Ngân hàng đang bảo trì";
            case "79" -> "Nhập sai mật khẩu thanh toán quá số lần quy định";
            default -> "Giao dịch không thành công (mã " + responseCode + ")";
        };
    }

    // Tham số đã sắp xếp theo tên, mỗi cặp dạng tên=giá trị (mã hóa URL), nối bằng &; bỏ tham số rỗng
    private static String buildQuery(Map<String, String> sorted) {
        return sorted.entrySet().stream()
                .filter(e -> e.getValue() != null && !e.getValue().isEmpty())
                .map(e -> URLEncoder.encode(e.getKey(), StandardCharsets.US_ASCII) + "="
                        + URLEncoder.encode(e.getValue(), StandardCharsets.US_ASCII))
                .collect(Collectors.joining("&"));
    }

    private static String hmacSha512(String secret, String data) {
        try {
            Mac mac = Mac.getInstance("HmacSHA512");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA512"));
            byte[] bytes = mac.doFinal(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder(bytes.length * 2);
            for (byte b : bytes) {
                sb.append(String.format("%02x", b & 0xff));
            }
            return sb.toString();
        } catch (Exception e) {
            throw new IllegalStateException("Không tạo được chữ ký VNPay", e);
        }
    }
}