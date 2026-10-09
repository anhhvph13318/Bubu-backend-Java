const loginForm = document.getElementById("loginForm");
const loginButton = document.getElementById("loginButton");
const loginMessage = document.getElementById("loginMessage");

const passwordInput = document.getElementById("password");
const togglePassword = document.getElementById("togglePassword");


/* ==============================
   HIỆN / ẨN MẬT KHẨU
   ============================== */

togglePassword.addEventListener("click", function () {

    if (passwordInput.type === "password") {

        passwordInput.type = "text";
        togglePassword.textContent = "Ẩn";

    } else {

        passwordInput.type = "password";
        togglePassword.textContent = "Hiện";
    }
});


/* ==============================
   ĐĂNG NHẬP
   ============================== */

loginForm.addEventListener("submit", async function (event) {

    event.preventDefault();

    const username =
        document.getElementById("username").value.trim();

    const password =
        passwordInput.value;


    // Xóa thông báo cũ
    loginMessage.textContent = "";
    loginMessage.className = "login-message";


    // Khóa nút trong lúc đăng nhập
    loginButton.disabled = true;
    loginButton.textContent = "Đang đăng nhập...";


    try {

        const response = await fetch("/api/auth/login", {

            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                username: username,
                password: password
            })
        });


        const data = await response.json();


        /* ==============================
           ĐĂNG NHẬP THẤT BẠI
           ============================== */

        if (!response.ok) {

            let message = "Đăng nhập thất bại";

            if (response.status === 401) {
                message = "Tên đăng nhập hoặc mật khẩu không đúng";
            }
            else if (response.status === 403) {
                message = "Tài khoản đã bị khóa";
            }
            else if (response.status === 400) {
                message = "Vui lòng kiểm tra lại thông tin đăng nhập";
            }

            loginMessage.textContent = message;

            loginButton.disabled = false;
            loginButton.textContent = "Đăng nhập";

            return;
        }


        /* ==============================
           ĐĂNG NHẬP THÀNH CÔNG
           ============================== */

        if (data.role === "ADMIN") {

            // Admin: lưu vào currentAccount cho các trang quản trị dùng
            sessionStorage.setItem("currentAccount", JSON.stringify(data));
            window.location.href = "/admin/index.html";
            return;
        }

        // Khách hàng dùng ứng dụng BuBu (Flutter), không dùng trang quản trị.
        // Không lưu gì vào trình duyệt.
        loginMessage.textContent =
            "Tài khoản này không có quyền vào trang quản trị. Vui lòng dùng ứng dụng BuBu để mua hàng.";

        loginButton.disabled = false;
        loginButton.textContent = "Đăng nhập";

    }
    catch (error) {

        console.error("Login error:", error);

        loginMessage.textContent =
            "Không thể kết nối đến máy chủ";

        loginButton.disabled = false;
        loginButton.textContent = "Đăng nhập";
    }

});
