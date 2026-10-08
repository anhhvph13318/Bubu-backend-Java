package com.example.bububackend.model;

import jakarta.persistence.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

// Một ảnh của sản phẩm, nội dung ảnh lưu thẳng trong cột Data (VARBINARY(MAX))
@Entity
@Table(name = "`Image`")
public class Image {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "`Id`")
    private int id;

    @Column(name = "`ProductId`")
    private int productId;

    @Column(name = "`FileName`")
    private String fileName;

    @Column(name = "`ContentType`")
    private String contentType;

    @JdbcTypeCode(SqlTypes.VARBINARY)
    @Column(name = "`Data`", columnDefinition = "VARBINARY(MAX)")
    private byte[] data;

    // true = ảnh đại diện của sản phẩm
    @Column(name = "`IsMain`")
    private boolean main;

    @Column(name = "`SortOrder`")
    private int sortOrder;

    // Tăng 1 mỗi lần thay ảnh, giao diện dùng để tránh dùng ảnh cũ trong bộ nhớ đệm của trình duyệt
    @Column(name = "`Version`")
    private int version = 1;

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public int getProductId() { return productId; }
    public void setProductId(int productId) { this.productId = productId; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public String getContentType() { return contentType; }
    public void setContentType(String contentType) { this.contentType = contentType; }

    public byte[] getData() { return data; }
    public void setData(byte[] data) { this.data = data; }

    public boolean isMain() { return main; }
    public void setMain(boolean main) { this.main = main; }

    public int getSortOrder() { return sortOrder; }
    public void setSortOrder(int sortOrder) { this.sortOrder = sortOrder; }

    public int getVersion() { return version; }
    public void setVersion(int version) { this.version = version; }
}