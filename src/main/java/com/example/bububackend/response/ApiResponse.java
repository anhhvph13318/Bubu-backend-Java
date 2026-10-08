package com.example.bububackend.response;

public class ApiResponse<T> {
    private boolean success;
    private T data;
    private String errorMessage;
    private String errorCode;

    public ApiResponse(T data,boolean success, String errorMessage, String errorCode) {
        this.data = data;
        this.success = success;
        this.errorMessage = errorMessage;
        this.errorCode = errorCode;
    }
    public boolean getSuccess () {
        return success;
    }

    public T getData() {
        return data;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public String getErrorCode() {
        return errorCode;
    }
}