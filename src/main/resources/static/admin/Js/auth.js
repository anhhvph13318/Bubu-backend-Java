const currentAccount = sessionStorage.getItem("currentAccount");

let parsedAccount = null;
try {
    parsedAccount = currentAccount ? JSON.parse(currentAccount) : null;
} catch (e) {
    parsedAccount = null;
}

// ==============================
// KIỂM TRA ĐĂNG NHẬP VÀ QUYỀN ADMIN
// ==============================

if (!parsedAccount || parsedAccount.role !== "ADMIN") {

    sessionStorage.removeItem("currentAccount");
    window.location.href = "/admin/login.html";

} else {

    const account = parsedAccount;


    // ==============================
    // HIỂN THỊ THÔNG TIN TÀI KHOẢN
    // ==============================

    const accountName =
        document.getElementById("accountName");

    const accountUsername =
        document.getElementById("accountUsername");

    const accountAvatar =
        document.getElementById("accountAvatar");


    // Hiển thị tên
    if (accountName) {

        accountName.textContent =
            account.fullName || account.username;
    }


    // Hiển thị username
    if (accountUsername) {

        accountUsername.textContent =
            account.username;
    }


    // Lấy chữ cái đầu để làm avatar
    if (accountAvatar) {

        const name =
            account.fullName || account.username;

        accountAvatar.textContent =
            name.charAt(0).toUpperCase();
    }
}


// ==============================
// ĐĂNG XUẤT
// ==============================

const logoutBtn =
    document.getElementById("logoutBtn");

if (logoutBtn) {

    logoutBtn.addEventListener("click", function () {

        // Xóa thông tin tài khoản đang đăng nhập
        sessionStorage.removeItem("currentAccount");

        // Quay về trang đăng nhập
        window.location.href = "/admin/login.html";
    });
}