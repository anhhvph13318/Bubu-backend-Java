package com.example.bububackend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "Account")
public class Account {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`Username`")
    private String userName;

    @Column(name = "`PasswordHash`")
    private String passwordHash;

    @Column(name = "`FullName`")
    private String fullName;

    @Column(name = "`IsActive`")
    private boolean isActive;

    @Column(name = "`Email`")
    private String email;

    @Column(name = "`Phone`")
    private String phone;

    @Column(name = "`Role`")
    private String role;

    public String getEmail() { return email; }

    public void setEmail(String email) { this.email = email; }

    public String getPhone() { return phone; }

    public void setPhone(String phone) { this.phone = phone; }

    public String getRole() { return role; }

    public void setRole(String role) { this.role = role; }

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getPasswordHash() {
        return passwordHash;
    }

    public void setPasswordHash(String passwordHash) {
        this.passwordHash = passwordHash;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public boolean isActive() {
        return isActive;
    }

    public void setActive(boolean active) {
        isActive = active;
    }
}