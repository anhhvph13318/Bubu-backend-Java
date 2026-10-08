package com.example.bububackend.service;

import com.example.bububackend.model.Account;
import com.example.bububackend.model.AccountRequest;
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

    private final AccountRepository repository;

    public AccountService(AccountRepository repository) {
        this.repository = repository;
    }

    public List<Account> findAll() { return repository.findAll(); }

    public Account createAccount(AccountRequest req) {
        String username = req.getUsername() == null ? "" : req.getUsername().trim();
        if (!username.matches("^[A-Za-z0-9._@-]{3,50}$")) {
            throw bad("Tên đăng nhập từ 3–50 ký tự: chữ không dấu, số, . _ @ -");
        }
        if (repository.existsByUserNameIgnoreCase(username)) {
            throw bad("Tên đăng nhập \"" + username + "\" đã tồn tại");
        }
        checkPassword(req.getPassword());

        Account a = new Account();
        a.setUserName(username);
        a.setFullName(cleanFullName(req.getFullName()));
        a.setPasswordHash(hashPassword(req.getPassword()));
        a.setActive(req.getActive() == null || req.getActive());
        return repository.save(a);
    }

    public Account edit(int id, AccountRequest req) {
        Account a = find(id);
        // Tên đăng nhập không đổi được (bỏ qua nếu gửi lên)
        a.setFullName(cleanFullName(req.getFullName()));

        if (req.getActive() != null) {
            // Không cho khóa tài khoản hoạt động cuối cùng (tránh tự khóa mình ra khỏi hệ thống)
            if (a.isActive() && !req.getActive()) {
                ensureNotLastActive();
            }
            a.setActive(req.getActive());
        }
        if (req.getPassword() != null && !req.getPassword().isEmpty()) {
            checkPassword(req.getPassword());
            a.setPasswordHash(hashPassword(req.getPassword()));
        }
        return repository.save(a);
    }

    public void deleteAccount(int id) {
        Account a = find(id);
        if (a.isActive()) {
            ensureNotLastActive();
        }
        repository.deleteById(id);
    }

    // ------------------------------------------------------------------
    // MÃ HÓA MẬT KHẨU - chỉ cần sửa ở ĐÂY nếu cách đăng nhập của bạn khác.
    // Cột PasswordHash là varchar(64) nên mình giả định SHA-256 dạng hex (đúng 64 ký tự).
    // Cách mã hóa này PHẢI GIỐNG HỆT code đăng nhập, nếu không tài khoản tạo / đặt lại
    // mật khẩu từ trang admin sẽ không đăng nhập được.
    // Khuyến nghị: nên chuyển sang BCrypt (60 ký tự, vẫn vừa varchar(64)) vì SHA-256 trần dễ bị dò.
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

    private void ensureNotLastActive() {
        if (repository.countByActiveTrue() <= 1) {
            throw bad("Không thể khóa hoặc xóa tài khoản đang hoạt động cuối cùng");
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