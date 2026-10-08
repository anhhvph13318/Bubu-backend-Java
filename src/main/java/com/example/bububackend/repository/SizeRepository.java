package com.example.bububackend.repository;

import com.example.bububackend.model.Size;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface SizeRepository extends JpaRepository<Size, Integer> {
    List<Size> findByNameIgnoreCase(String name);
}