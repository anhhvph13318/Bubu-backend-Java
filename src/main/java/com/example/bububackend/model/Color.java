package com.example.bububackend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "`Color`")
public class Color {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`Name`")
    private String name;

    // Mã màu hiển thị, ví dụ #FF99CC (có thể để trống)
    @Column(name = "`HexCode`")
    private String hexCode;

    @Column(name = "`IsActive`")
    private boolean active = true;

    public int getId() {
        return id;
    }

    public void setId(int id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getHexCode() {
        return hexCode;
    }

    public void setHexCode(String hexCode) {
        this.hexCode = hexCode;
    }

    public boolean isActive() {
        return active;
    }

    public void setActive(boolean active) {
        this.active = active;
    }
}