package com.example.bububackend.repository;

import com.example.bububackend.model.Color;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ColorRepository extends JpaRepository<Color, Integer> {
    List<Color> findByNameIgnoreCase(String name);
}