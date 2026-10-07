package com.example.bububackend.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

// Dữ liệu giao diện gửi lên khi thêm / sửa tài khoản.
// Tách riêng khỏi entity để có thể nhận "password" (mật khẩu thô) mà không lưu thẳng vào database.
@JsonIgnoreProperties(ignoreUnknown = true)
public class AccountRequest {

    private String username;
    private String fullName;
    private Boolean active;   // null = không đổi
    private String password;  // null / rỗng = không đổi mật khẩu

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public Boolean getActive() { return active; }
    public void setActive(Boolean active) { this.active = active; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
}