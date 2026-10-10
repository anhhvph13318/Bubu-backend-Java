package com.example.bububackend.model;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;

// Khách tự sửa thông tin cá nhân.
@JsonIgnoreProperties(ignoreUnknown = true)
public class ProfileRequest {

    private String fullName;
    private String email;
    private String phone;

    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
}