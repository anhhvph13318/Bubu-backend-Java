package com.example.bububackend.service;
import com.example.bububackend.model.ChangePasswordRequest;
import com.example.bububackend.model.ProfileRequest;

import com.example.bububackend.model.Account;
import com.example.bububackend.model.AccountRequest;
import com.example.bububackend.model.RegisterRequest;
import com.example.bububackend.repository.AccountRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.List;

@Service
public class AccountService {

    public static final String ROLE_ADMIN = "ADMIN";
    public static final String ROLE_CUSTOMER = "CUSTOMER";

    private final AccountRepository repository;

    public AccountService(AccountRepository repository) {
        this.repository = repository;
    }

    public List<Account> findAll() { return repository.findAll(); }

    public Account getById(int id) {
        return find(id);
    }

    // Tạo từ trang quản trị: luôn là ADMIN
    public Account createAccount(AccountRequest req) {
        return create(req, ROLE_ADMIN);
    }

    // Khách tự đăng ký: luôn là CUSTOMER, bắt buộc có email và số điện thoại
    public Account register(RegisterRequest req) {
        if (req.getConfirmPassword() != null && !req.getConfirmPassword().equals(req.getPassword())) {
            throw bad("Mật khẩu nhập lại không khớp");
        }
        if (req.getEmail() == null || req.getEmail().isBlank()) {
            throw bad("Vui lòng nhập email");
        }
        if (req.getPhone() == null || req.getPhone().isBlank()) {
            throw bad("Vui lòng nhập số điện thoại");
        }
        AccountRequest account = new AccountRequest();
        account.setUsername(req.getUsername());
        account.setPassword(req.getPassword());
        account.setFullName(req.getFullName());
        account.setEmail(req.getEmail());
        account.setPhone(req.getPhone());
        account.setActive(true);
        return create(account, ROLE_CUSTOMER);
    }

    private Account create(AccountRequest req, String role) {
        String username = req.getUsername() == null ? "" : req.getUsername().trim();
        if (!username.matches("^[A-Za-z0-9._@-]{3,50}$")) {
            throw bad("Tên đăng nhập từ 3–50 ký tự: chữ không dấu, số, . _ @ -");
        }
        if (repository.existsByUserNameIgnoreCase(username)) {
            throw bad("Tên đăng nhập \"" + username + "\" đã tồn tại");
        }
        checkPassword(req.getPassword());
        String email = cleanEmail(req.getEmail());
        String phone = cleanPhone(req.getPhone());

        Account a = new Account();
        a.setUserName(username);
        a.setFullName(cleanFullName(req.getFullName()));
        a.setEmail(email);
        a.setPhone(phone);
        a.setRole(role);
        a.setPasswordHash(hashPassword(req.getPassword()));
        a.setActive(req.getActive() == null || req.getActive());
        return repository.save(a);
    }

    public Account edit(int id, AccountRequest req) {
        Account a = find(id);
        // Tên đăng nhập và role không đổi được (bỏ qua nếu gửi lên)
        a.setFullName(cleanFullName(req.getFullName()));

        if (req.getActive() != null) {
            // Không cho khóa admin hoạt động cuối cùng (tránh tự khóa mình ra khỏi hệ thống)
            if (a.isActive() && !req.getActive()) {
                ensureNotLastActive(a);
            }
            a.setActive(req.getActive());
        }
        if (req.getPassword() != null && !req.getPassword().isEmpty()) {
            checkPassword(req.getPassword());
            a.setPasswordHash(hashPassword(req.getPassword()));
        }
        return repository.save(a);
    }

    // Khách tự sửa thông tin cá nhân. Không đổi được tên đăng nhập, role, trạng thái.
    // Khách (CUSTOMER) bắt buộc phải còn email và số điện thoại, giống lúc đăng ký.
    public Account updateProfile(int accountId, ProfileRequest req) {
        Account a = find(accountId);
        requireActive(a);

        String email = cleanEmail(req.getEmail(), accountId);
        String phone = cleanPhone(req.getPhone());
        if (ROLE_CUSTOMER.equals(a.getRole())) {
            if (email == null) {
                throw bad("Vui lòng nhập email");
            }
            if (phone == null) {
                throw bad("Vui lòng nhập số điện thoại");
            }
        }

        a.setFullName(cleanFullName(req.getFullName()));
        a.setEmail(email);
        a.setPhone(phone);
        return repository.save(a);
    }

    // Đổi mật khẩu: phải nhập đúng mật khẩu hiện tại.
    // Sai mật khẩu hiện tại trả 400 (không phải 401) để ứng dụng không hiểu nhầm là hết phiên đăng nhập.
    public void changePassword(int accountId, ChangePasswordRequest req) {
        Account a = find(accountId);
        requireActive(a);

        String current = req.getCurrentPassword();
        if (current == null || current.isEmpty()) {
            throw bad("Vui lòng nhập mật khẩu hiện tại");
        }
        if (!hashPassword(current).equals(a.getPasswordHash())) {
            throw bad("Mật khẩu hiện tại không đúng");
        }
        checkPassword(req.getNewPassword());
        if (req.getConfirmPassword() != null && !req.getConfirmPassword().equals(req.getNewPassword())) {
            throw bad("Mật khẩu nhập lại không khớp");
        }
        if (req.getNewPassword().equals(current)) {
            throw bad("Mật khẩu mới phải khác mật khẩu hiện tại");
        }
        a.setPasswordHash(hashPassword(req.getNewPassword()));
        repository.save(a);
    }

    private void requireActive(Account a) {
        if (!a.isActive()) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Tài khoản đã bị khóa");
        }
    }

    public void deleteAccount(int id) {
        Account a = find(id);
        if (a.isActive()) {
            ensureNotLastActive(a);
        }
        repository.deleteById(id);
    }

    // ------------------------------------------------------------------
    // MÃ HÓA MẬT KHẨU - cách này PHẢI GIỐNG HỆT lúc đăng nhập.
    // Cột PasswordHash là varchar(64) nên dùng SHA-256 dạng hex (đúng 64 ký tự).
    // Khuyến nghị: chuyển sang BCrypt (60 ký tự, vẫn vừa varchar(64)) vì SHA-256 trần dễ bị dò.
    // ------------------------------------------------------------------
    private String hashPassword(String raw) {
        try {
            MessageDigest md = MessageDigest.getInstance("SHA-256");
            byte[] bytes = md.digest(raw.getBytes(StandardCharsets.UTF_8));
            StringBuilder sb = new StringBuilder();
            for (byte b : bytes) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException(e);
        }
    }

    private Account find(int id) {
        return repository.findById(id).orElseThrow(() ->
                new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy tài khoản " + id));
    }

    // Chỉ áp dụng cho ADMIN: khóa / xóa khách thì không ảnh hưởng gì
    private void ensureNotLastActive(Account a) {
        if (ROLE_ADMIN.equals(a.getRole())
                && repository.countByActiveTrueAndRole(ROLE_ADMIN) <= 1) {
            throw bad("Không thể khóa hoặc xóa tài khoản admin đang hoạt động cuối cùng");
        }
    }

    private void checkPassword(String password) {
        if (password == null || password.length() < 6) {
            throw bad("Mật khẩu tối thiểu 6 ký tự");
        }
    }

    // Họ tên: bỏ khoảng trắng thừa, rỗng thì lưu null, tối đa 100 ký tự
    private String cleanFullName(String s) {
        if (s == null || s.isBlank()) return null;
        String t = s.trim();
        return t.length() > 100 ? t.substring(0, 100) : t;
    }

    private String cleanEmail(String s) {
        return cleanEmail(s, null);
    }

    // Email: bỏ khoảng trắng, rỗng thì null; sai định dạng hoặc đã dùng thì báo lỗi.
    // selfId: id tài khoản đang sửa (bỏ qua chính nó khi kiểm tra trùng); null khi tạo mới.
    private String cleanEmail(String s, Integer selfId) {
        if (s == null || s.isBlank()) return null;
        String email = s.trim();
        if (email.length() > 100 || !email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]+$")) {
            throw bad("Email không hợp lệ");
        }
        boolean taken = selfId == null
                ? repository.existsByEmailIgnoreCase(email)
                : repository.existsByEmailIgnoreCaseAndIdNot(email, selfId);
        if (taken) {
            throw bad("Email \"" + email + "\" đã được sử dụng");
        }
        return email;
    }

    // Số điện thoại: bỏ dấu cách . -, phải có 9–12 chữ số (có thể bắt đầu bằng +), giống bên đặt hàng
    private String cleanPhone(String s) {
        if (s == null || s.isBlank()) return null;
        String phone = s.trim().replaceAll("[\\s.-]", "");
        if (!phone.matches("^\\+?\\d{9,12}$")) {
            throw bad("Số điện thoại không hợp lệ");
        }
        return phone;
    }

    private ResponseStatusException bad(String message) {
        return new ResponseStatusException(HttpStatus.BAD_REQUEST, message);
    }

    // Đăng nhập
    public Account login(String username, String password) {

        if (username == null || username.trim().isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Tên đăng nhập không được để trống"
            );
        }

        if (password == null || password.isEmpty()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Mật khẩu không được để trống"
            );
        }

        Account account = repository.findByUserName(username.trim())
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.UNAUTHORIZED,
                        "Tên đăng nhập hoặc mật khẩu không đúng"
                ));

        if (!account.isActive()) {
            throw new ResponseStatusException(
                    HttpStatus.FORBIDDEN,
                    "Tài khoản đã bị khóa"
            );
        }

        String passwordHash = hashPassword(password);

        if (!passwordHash.equals(account.getPasswordHash())) {
            throw new ResponseStatusException(
                    HttpStatus.UNAUTHORIZED,
                    "Tên đăng nhập hoặc mật khẩu không đúng"
            );
        }

        return account;
    }
}