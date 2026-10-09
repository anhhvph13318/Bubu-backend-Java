const loginHeader = document.getElementById("loginHeader");
const toRegisterText = document.getElementById("toRegisterText");

const registerSection = document.getElementById("registerSection");
const registerForm = document.getElementById("registerForm");
const registerMessage = document.getElementById("registerMessage");
const registerButton = document.getElementById("registerButton");


/* ==============================
   CHUYỂN QUA LẠI ĐĂNG NHẬP / ĐĂNG KÝ
   ============================== */

function showRegister() {
    loginHeader.hidden = true;
    loginForm.hidden = true;
    toRegisterText.hidden = true;

    registerSection.hidden = false;
    registerMessage.textContent = "";

    document.getElementById("regFullName").focus();
}

function showLogin() {
    registerSection.hidden = true;

    loginHeader.hidden = false;
    loginForm.hidden = false;
    toRegisterText.hidden = false;
}

document.getElementById("showRegister").addEventListener("click", showRegister);
document.getElementById("showLogin").addEventListener("click", showLogin);


/* ==============================
   ĐĂNG KÝ
   ============================== */

function showRegisterError(message) {
    registerMessage.textContent = message;
}

registerForm.addEventListener("submit", async function (event) {

    event.preventDefault();

    const fullName = document.getElementById("regFullName").value.trim();
    const username = document.getElementById("regUsername").value.trim();
    const email = document.getElementById("regEmail").value.trim();
    const phone = document.getElementById("regPhone").value.trim().replace(/[\s.-]/g, "");
    const password = document.getElementById("regPassword").value;
    const confirmPassword = document.getElementById("regConfirmPassword").value;

    registerMessage.textContent = "";

    // Kiểm tra sơ bộ ở trình duyệt (server vẫn kiểm tra lại)
    if (!/^[A-Za-z0-9._@-]{3,50}$/.test(username)) {
        showRegisterError("Tên đăng nhập từ 3–50 ký tự: chữ không dấu, số, . _ @ -");
        return;
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
        showRegisterError("Email không hợp lệ");
        return;
    }
    if (!/^\+?\d{9,12}$/.test(phone)) {
        showRegisterError("Số điện thoại không hợp lệ (9–12 chữ số)");
        return;
    }
    if (password.length < 6) {
        showRegisterError("Mật khẩu tối thiểu 6 ký tự");
        return;
    }
    if (password !== confirmPassword) {
        showRegisterError("Mật khẩu nhập lại không khớp");
        return;
    }

    registerButton.disabled = true;
    registerButton.textContent = "Đang đăng ký...";

    try {

        const response = await fetch("/api/auth/register", {

            method: "POST",

            headers: {
                "Content-Type": "application/json"
            },

            body: JSON.stringify({
                username: username,
                email: email,
                phone: phone,
                password: password,
                confirmPassword: confirmPassword,
                fullName: fullName
            })
        });

        let data = null;
        try {
            data = await response.json();
        } catch (e) {
            // response không có JSON thì dùng thông báo mặc định bên dưới
        }

        if (!response.ok) {

            // Server chỉ gửi "message" khi bật server.error.include-message=always
            let message = data && data.message;

            if (!message) {
                message = response.status === 400
                    ? "Thông tin chưa hợp lệ hoặc tên đăng nhập đã tồn tại"
                    : "Đăng ký thất bại";
            }

            showRegisterError(message);
            return;
        }

        // Thành công: quay về form đăng nhập, điền sẵn tên đăng nhập.
        // Không tự đăng nhập để người dùng chủ động xác nhận mật khẩu.
        registerForm.reset();
        showLogin();

        document.getElementById("username").value = username;
        document.getElementById("password").focus();

        loginMessage.textContent = "Đăng ký thành công! Hãy đăng nhập.";
        loginMessage.className = "login-message success";

    }
    catch (error) {

        console.error("Register error:", error);
        showRegisterError("Không thể kết nối đến máy chủ");

    }
    finally {

        registerButton.disabled = false;
        registerButton.textContent = "Đăng ký";
    }
});