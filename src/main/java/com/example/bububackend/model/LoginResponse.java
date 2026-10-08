package com.example.bububackend.model;

public class LoginResponse {

    private int id;
    private String username;
    private String fullName;
    private boolean active;

    public LoginResponse() {
    }

    public LoginResponse(int id, String username, String fullName, boolean active) {
        this.id = id;
        this.username = username;
        this.fullName = fullName;
        this.active = active;
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
}