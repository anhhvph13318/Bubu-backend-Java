package com.example.bububackend.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

// Dữ liệu khách gửi lên khi đăng ký.
// Cố ý KHÔNG có trường "active": khách không được tự quyết định trạng thái tài khoản.
@JsonIgnoreProperties(ignoreUnknown = true)
public class RegisterRequest {

    private String username;
    private String password;
    private String confirmPassword; // không bắt buộc; có gửi thì phải khớp với password
    private String fullName;
    private String email;
    private String phone;

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }

    public String getConfirmPassword() { return confirmPassword; }
    public void setConfirmPassword(String confirmPassword) { this.confirmPassword = confirmPassword; }

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
}