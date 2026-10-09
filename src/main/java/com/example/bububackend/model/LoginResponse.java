package com.example.bububackend.model;

public class LoginResponse {

    private int id;
    private String username;
    private String fullName;
    private boolean active;
    private String role;
    private String email;
    private String phone;

    public LoginResponse() {
    }

    public LoginResponse(int id, String username, String fullName, boolean active,
                         String role, String email, String phone) {
        this.id = id;
        this.username = username;
        this.fullName = fullName;
        this.active = active;
        this.role = role;
        this.email = email;
        this.phone = phone;
    }

    public int getId() {
        return id;
    }

    public String getUsername() {
        return username;
    }

    public String getFullName() {
        return fullName;
    }

    public boolean isActive() {
        return active;
    }

    public String getRole() {
        return role;
    }

    public String getEmail() {
        return email;
    }

    public String getPhone() {
        return phone;
    }
}