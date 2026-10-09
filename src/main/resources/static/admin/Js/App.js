/* =====================================================================
 * BUBU ADMIN - vanilla JS, không cần build, không cần thư viện
 * Đặt tại: src/main/resources/static/admin/js/app.js
 *
 * MỤC LỤC (tìm nhanh bằng Ctrl+F theo số phần, ví dụ "[5]")
 *   [1]  Cấu hình                      - bật/tắt dữ liệu mẫu, đường dẫn API
 *   [2]  Tiện ích chung                - DOM, định dạng tiền/ngày, icon
 *   [3]  Gọi API (HTTP)                - hàm fetch dùng chung
 *   [4]  Chuyển đổi dữ liệu API <-> UI - nhận diện tên trường của backend
 *        [4.1] Bảng tên trường (ALIASES)
 *        [4.2] Sản phẩm
 *        [4.3] Danh mục (gắn vào sản phẩm)
 *        [4.4] Đơn hàng
 *   [5]  Lớp truy cập dữ liệu (api)    - list / save / remove
 *   [6]  Trạng thái & hằng số giao diện
 *   [7]  Thành phần giao diện chung    - toast, modal, drawer, phân trang
 *   [8]  Màn hình SẢN PHẨM
 *        [8.1] Biến thể sản phẩm (bảng ProductDetail: size / màu / số lượng)
 *   [9]  Màn hình DANH MỤC
 *   [10] Màn hình ĐƠN HÀNG
 *   [11] Màn hình TÀI KHOẢN
 *   [12] Điều hướng (routes) + sự kiện chung + khởi động
 *
 * Cách dùng với backend: chỉnh [1] ENDPOINTS và [4.1] ALIASES cho khớp
 * controller / JSON của bạn. Mọi thứ khác không cần đụng tới.
 * ===================================================================== */
(() => {
    'use strict';

    /* =================================================================
     * [1] CẤU HÌNH
     * ================================================================= */

    // true = dùng dữ liệu mẫu (bộ nhớ `db`), false = gọi API thật. Đặt riêng cho từng loại.
    const MOCK = { products: false, categories: false, orders: false, details: false, accounts: false };

    // Đường dẫn API của từng loại dữ liệu
    const ENDPOINTS = {
        products: '/api/products',
        categories: '/api/categories',
        orders: '/api/orders',
        details: '/api/product-details', // biến thể sản phẩm (sizeId / colorId / số lượng)
        images: '/api/images',           // ảnh sản phẩm (lưu trong bảng Image, tối đa 5 ảnh / sản phẩm)
        sizes: '/api/sizes',             // danh sách size
        colors: '/api/colors',           // danh sách màu
        accounts: '/api/accounts',       // tài khoản quản trị
    };

    // Số dòng mỗi trang ở các bảng
    const PAGE_SIZE = 8;

    // Kho dữ liệu mẫu, chỉ dùng khi MOCK.* = true. Hiện để trống;
    // nextId dùng để cấp id cho bản ghi mới ở chế độ mẫu.
    const db = {
        products: [], categories: [], orders: [], details: [], accounts: [],
        nextId: { products: 1, categories: 1, orders: 1, details: 1, accounts: 1 },
    };

    /* =================================================================
     * [2] TIỆN ÍCH CHUNG
     * ================================================================= */

    // --- Chọn phần tử DOM ---
    const $ = (s, r = document) => r.querySelector(s);           // chọn 1 phần tử
    const $$ = (s, r = document) => [...r.querySelectorAll(s)];  // chọn nhiều phần tử (trả về mảng)

    // --- Chống chèn mã HTML (XSS): luôn dùng esc() khi in dữ liệu người dùng vào HTML ---
    const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

    // --- Định dạng hiển thị ---
    const money = (n) => new Intl.NumberFormat('vi-VN').format(Number(n) || 0) + ' ₫';
    const validDate = (iso) => { const d = new Date(iso); return iso && !isNaN(d) ? d : null; };
    const fmtDate = (iso) => { const d = validDate(iso); return d ? d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—'; };
    const fmtDateTime = (iso) => { const d = validDate(iso); return d ? d.toLocaleString('vi-VN') : '—'; };

    // Chuẩn hóa chuỗi để tìm kiếm: chữ thường + bỏ dấu tiếng Việt ("Áo Đẹp" -> "ao dep")
    const norm = (s) => String(s ?? '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');

    // Sao chép sâu một object (dùng cho dữ liệu mẫu)
    const clone = (o) => JSON.parse(JSON.stringify(o));

    // --- Bộ icon SVG dùng trong giao diện ---
    const ICON = {
        lock: '<svg viewBox="0 0 24 24"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 8 0v4"/></svg>',
        unlock: '<svg viewBox="0 0 24 24"><rect x="4" y="11" width="16" height="10" rx="2"/><path d="M8 11V7a4 4 0 0 1 7.5-2"/></svg>',
        variants: '<svg viewBox="0 0 24 24"><path d="m12 3 9 5-9 5-9-5 9-5Z"/><path d="m3 13 9 5 9-5"/></svg>',
        view: '<svg viewBox="0 0 24 24"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>',
        edit: '<svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5Z"/></svg>',
        del: '<svg viewBox="0 0 24 24"><path d="M3 6h18"/><path d="M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>',
        search: '<svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>',
        box: '<svg viewBox="0 0 24 24"><path d="M21 8 12 3 3 8v8l9 5 9-5V8Z"/><path d="m3 8 9 5 9-5M12 13v8"/></svg>',
        check: '<svg viewBox="0 0 24 24"><path d="m5 12 5 5 9-10"/></svg>',
        alert: '<svg viewBox="0 0 24 24"><path d="M12 9v4M12 17h.01"/><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z"/></svg>',
        cart: '<svg viewBox="0 0 24 24"><circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.7 12.4a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.5L21 8H6"/></svg>',
        money: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-dollar-sign preview-icon"><line x1="12" x2="12" y1="2" y2="22"/><path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"/></svg>',
        cancel: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-circle-x preview-icon"><circle cx="12" cy="12" r="10"/><path d="m15 9-6 6"/><path d="m9 9 6 6"/></svg>',
        shipping: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-truck preview-icon"><path d="M14 18V6a2 2 0 0 0-2-2H4a2 2 0 0 0-2 2v11a1 1 0 0 0 1 1h2"/><path d="M15 18H9"/><path d="M19 18h2a1 1 0 0 0 1-1v-3.65a1 1 0 0 0-.22-.624l-3.48-4.35A1 1 0 0 0 17.52 8H14"/><circle cx="17" cy="18" r="2"/><circle cx="7" cy="18" r="2"/></svg>',
        done: '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-square-check preview-icon"><rect width="18" height="18" x="3" y="3" rx="2"/><path d="m16 9-5.5 5.5L8 12"/></svg>'
    };

    /* =================================================================
     * [3] GỌI API (HTTP)
     * Hàm fetch dùng chung: tự gửi JSON, ném lỗi nếu HTTP không thành công,
     * trả null nếu server trả 204 (không có nội dung, ví dụ sau khi xóa).
     * ================================================================= */
    async function http(url, opts = {}) {
        // Gửi file (FormData) thì để trình duyệt tự đặt Content-Type; còn lại gửi JSON
        const headers = opts.body instanceof FormData ? {} : { 'Content-Type': 'application/json' };
        const res = await fetch(url, { headers, ...opts });
        if (!res.ok) {
            // Cố đọc thông báo lỗi mà backend trả về (message / error / detail) để hiện cho người dùng
            let msg = 'Lỗi ' + res.status;
            try { const b = await res.json(); msg = b.errorMessage || b.message || b.error || b.detail || msg; } catch (_) { /* không có JSON thì giữ mã lỗi */ }
            throw new Error(msg);
        }
        return res.status === 204 ? null : res.json();
    }

    /* =================================================================
     * [4] CHUYỂN ĐỔI DỮ LIỆU API <-> GIAO DIỆN
     * Mỗi backend đặt tên trường một kiểu (price / giaBan / gia ...).
     * Phần này tự nhận diện các tên thường gặp để giao diện luôn dùng
     * một dạng dữ liệu thống nhất, và khi lưu thì trả về đúng dạng backend.
     * ================================================================= */

    /* ---------- [4.1] Bảng tên trường (ALIASES) ----------
     * Nếu JSON của bạn dùng tên khác, chỉ cần THÊM tên đó vào mảng tương ứng.
     * Tên đứng đầu mảng là tên mặc định khi gửi dữ liệu mới lên backend. */
    const ALIASES = {
        // --- sản phẩm ---
        id: ['id', 'productId', 'maSanPham', 'ma'],
        name: ['name', 'productName', 'tenSanPham', 'ten', 'title'],
        sku: ['sku', 'code', 'productCode', 'maSP', 'maSanPham'],
        price: ['price', 'giaBan', 'gia', 'unitPrice'],
        stock: ['stock', 'quantity', 'soLuong', 'tonKho', 'inventory', 'qty'],
        status: ['status', 'trangThai', 'active', 'enabled'],
        description: ['description', 'moTa', 'desc'],
        image: ['image', 'imageUrl', 'hinhAnh', 'img', 'thumbnail', 'anh'],
        category: ['category', 'categoryName', 'categoryId', 'danhMuc', 'tenDanhMuc', 'idDanhMuc'],
        // --- đơn hàng ---
        order_id: ['id', 'orderId', 'invoiceId'],
        order_code: ['code', 'orderCode', 'orderNumber', 'maDon', 'maDonHang', 'maHoaDon', 'invoiceCode', 'soHoaDon'],
        order_customer: ['customerName', 'customer', 'tenKhachHang', 'khachHang', 'receiverName', 'fullName', 'user'],
        order_phone: ['phone', 'phoneNumber', 'sdt', 'soDienThoai', 'customerPhone', 'receiverPhone'],
        order_address: ['address', 'shippingAddress', 'deliveryAddress', 'diaChi', 'diaChiGiaoHang'],
        order_date: ['createdAt', 'orderDate', 'date', 'ngayTao', 'ngayDat', 'createdDate', 'created_at'],
        order_status: ['status', 'orderStatus', 'trangThai'],
        order_payment: ['paymentMethod', 'payment', 'phuongThucThanhToan', 'hinhThucThanhToan'],
        order_total: ['total', 'totalAmount', 'totalPrice', 'tongTien', 'grandTotal', 'amount'],
        order_items: ['items', 'orderItems', 'details', 'orderDetails', 'chiTiet', 'chiTietDonHang', 'chiTietHoaDon', 'lines', 'products'],
        // --- từng dòng sản phẩm trong đơn ---
        item_product: ['product', 'sanPham'],
        item_productId: ['productId', 'sanPhamId', 'idSanPham'],
        item_name: ['productName', 'name', 'tenSanPham', 'ten'],
        item_price: ['price', 'unitPrice', 'donGia', 'gia', 'giaBan'],
        item_qty: ['quantity', 'qty', 'soLuong'],
    };

    // Tên trường khi khách hàng là object lồng bên trong đơn: { customer: { name, phone, address } }
    const NEST = {
        name: ['name', 'fullName', 'hoTen', 'tenKhachHang', 'ten'],
        phone: ['phone', 'phoneNumber', 'sdt', 'soDienThoai'],
        address: ['address', 'diaChi'],
    };

    // --- Hàm đọc dữ liệu theo ALIASES ---
    // Lấy giá trị đầu tiên tìm thấy trong object theo danh sách tên (dùng cho object lồng nhau)
    const nestGet = (o, list, d = '') => { const k = list.find((x) => x in o); return k && o[k] != null ? o[k] : d; };
    // Cho biết backend đang dùng TÊN TRƯỜNG nào cho `key` (null nếu không có)
    const pick = (raw, key) => ALIASES[key].find((k) => k in raw) || null;
    // Lấy GIÁ TRỊ của `key` từ dữ liệu thô, không có thì dùng giá trị mặc định d
    const get = (raw, key, d) => { const k = pick(raw, key); return k == null || raw[k] == null ? d : raw[k]; };
    // Backend có thể bọc danh sách trong content / data / items... -> luôn trả về mảng
    const unwrapList = (res) => (Array.isArray(res) ? res : (res && (res.content || res.data || res.items || res.products || res.result)) || []);

    /* ---------- [4.2] Sản phẩm ---------- */

    // Bản ghi sản phẩm đầu tiên lấy từ API, dùng làm "khuôn" tên trường khi tạo sản phẩm mới
    let sampleRaw = null;

    // API -> giao diện: biến một sản phẩm thô thành dạng thống nhất
    function fromApiProduct(raw, i) {
        // Danh mục có thể là object {id, name}, số (id) hoặc chuỗi (tên)
        const cat = get(raw, 'category', null);
        let categoryName = '', categoryApiId = null;
        if (cat && typeof cat === 'object') { categoryName = cat.name ?? cat.tenDanhMuc ?? cat.ten ?? ''; categoryApiId = cat.id ?? null; }
        else if (typeof cat === 'number') categoryApiId = cat;
        else if (cat != null) categoryName = String(cat);

        // Trạng thái có thể là boolean / 0-1 / chuỗi -> quy về active | hidden | out
        const st = get(raw, 'status', 'active');
        let status = 'active';
        if (st === false || st === 0 || st === '0') status = 'hidden';
        else if (typeof st === 'string' && PRODUCT_STATUS[st.toLowerCase()]) status = st.toLowerCase();

        return {
            id: get(raw, 'id', i + 1),
            name: String(get(raw, 'name', '(chưa đặt tên)')),
            sku: String(get(raw, 'sku', '')),
            price: Number(get(raw, 'price', 0)) || 0,
            stock: Number(get(raw, 'stock', 0)) || 0,
            status,
            description: String(get(raw, 'description', '')),
            image: String(get(raw, 'image', '')),
            categoryName, categoryApiId,
            _raw: raw, // giữ nguyên dữ liệu gốc để khi lưu không làm mất trường lạ
        };
    }

    // Giao diện -> API: ghi các thay đổi đè lên dữ liệu gốc, dùng đúng tên trường của backend
    function toApiProduct(item) {
        const raw = { ...(item._raw || {}) };
        const ref = item._raw || sampleRaw || {}; // sản phẩm mới thì lấy mẫu từ sản phẩm đầu tiên
        const set = (key, val) => { raw[pick(ref, key) || ALIASES[key][0]] = val; };
        set('name', item.name); set('sku', item.sku); set('price', item.price);
        set('stock', item.stock); set('description', item.description); set('image', item.image);
        if (item.id != null) set('id', item.id);

        // Trạng thái: ghi lại đúng kiểu backend đang dùng (boolean / số / chuỗi)
        const sk = pick(ref, 'status') || 'status';
        const cur = ref[sk];
        raw[sk] = typeof cur === 'boolean' ? item.status === 'active' : typeof cur === 'number' ? (item.status === 'active' ? 1 : 0) : item.status;

        // Danh mục: ghi lại là object / tên / id tùy backend
        const c = data.categories.find((x) => x.id === item.categoryId);
        if (c) {
            const ck = pick(ref, 'category') || 'category';
            const cv = ref[ck];
            raw[ck] = cv && typeof cv === 'object' ? { ...cv, id: c.id, name: c.name }
                : typeof cv === 'string' || /name/i.test(ck) ? c.name : c.id;
        }
        return raw;
    }

    /* ---------- [4.3] Danh mục (gắn vào sản phẩm) ----------
     * Gắn categoryId cho từng sản phẩm. Nếu danh mục vẫn là dữ liệu mẫu (MOCK),
     * tạm dựng danh sách danh mục từ chính các sản phẩm để bộ lọc hoạt động đúng. */
    function linkCategories(products, categories) {
        if (!MOCK.categories) {
            // Danh mục thật: ghép theo id hoặc theo tên
            products.forEach((p) => {
                const c = categories.find((x) => x.id === p.categoryApiId || (p.categoryName && x.name === p.categoryName));
                p.categoryId = c ? c.id : undefined;
            });
            return categories;
        }
        // Danh mục mẫu: dựng từ sản phẩm
        const map = new Map();
        products.forEach((p) => {
            const key = p.categoryApiId ?? p.categoryName;
            if (key === null || key === '') return;
            if (!map.has(String(key))) {
                map.set(String(key), { id: p.categoryApiId ?? 1000 + map.size, name: p.categoryName || 'Danh mục ' + key, description: '', icon: '📁' });
            }
            p.categoryId = map.get(String(key)).id;
        });
        return [...map.values()];
    }

    /* ---------- [4.4] Đơn hàng ---------- */

    // Thứ tự trạng thái chuẩn (dùng khi backend trả trạng thái dạng số 0,1,2...)
    const ORDER_KEYS = ['pending', 'confirmed', 'shipping', 'done', 'cancelled'];
    // Trạng thái giao diện -> giá trị gốc backend (học từ dữ liệu tải về để ghi lại đúng kiểu)
    const statusSeen = {};
    // Đơn hàng đầu tiên từ API, dùng làm khuôn tên trường
    let sampleOrder = null;

    // Quy trạng thái bất kỳ của backend (số / tiếng Anh / tiếng Việt) về 1 trong ORDER_KEYS hoặc 'other'
    function normOrderStatus(v) {
        if (typeof v === 'number') return ORDER_KEYS[v] || 'other';
        const s = norm(v).replace(/[_-]+/g, ' ').trim();
        if (/^\d+$/.test(s)) return ORDER_KEYS[Number(s)] || 'other';
        if (/return|tra hang|hoan tien|refund/.test(s)) return 'other';
        if (/cancel|huy|reject|fail/.test(s)) return 'cancelled';
        if (/da giao|deliver(ed)?$|complete|done|hoan thanh|success|finish/.test(s)) return 'done';
        if (/ship|dang giao|delivering|transit|van chuyen/.test(s)) return 'shipping';
        if (/pend|^new\b|^moi\b|^cho\b|wait/.test(s)) return 'pending';
        if (/confirm|xac nhan|process|prepar/.test(s)) return 'confirmed';
        return 'other';
    }

    // Ngược lại: từ trạng thái giao diện -> giá trị gửi lên backend
    function statusToRaw(key, cur) {
        if (statusSeen[key] !== undefined) return statusSeen[key];          // đã thấy backend dùng giá trị nào thì dùng đúng giá trị đó
        if (typeof cur === 'number') return ORDER_KEYS.indexOf(key);        // backend dùng số
        const guess = { pending: 'PENDING', confirmed: 'CONFIRMED', shipping: 'SHIPPING', done: 'COMPLETED', cancelled: 'CANCELLED' }[key];
        return typeof cur === 'string' && cur === cur.toLowerCase() ? guess.toLowerCase() : guess;
    }

    // Quy ngày giờ về chuỗi ISO (hỗ trợ cả dạng mảng [năm, tháng, ngày, giờ...] của Java LocalDateTime)
    const toIso = (v) => {
        if (v == null || v === '') return '';
        if (Array.isArray(v)) { const [y, m = 1, d = 1, h = 0, mi = 0, s = 0] = v; return new Date(y, m - 1, d, h, mi, s).toISOString(); }
        const t = new Date(v);
        return isNaN(t) ? '' : t.toISOString();
    };

    // API -> giao diện: biến một đơn hàng thô thành dạng thống nhất
    function fromApiOrder(raw, i) {
        const id = get(raw, 'order_id', i + 1);
        // Khách hàng có thể là chuỗi (tên) hoặc object lồng {name, phone, address}
        const cust = get(raw, 'order_customer', '');
        const isObj = cust && typeof cust === 'object';
        // Trạng thái: nhớ giá trị gốc đầu tiên thấy được để sau này ghi lại đúng kiểu
        const rawStatus = get(raw, 'order_status', '');
        const status = normOrderStatus(rawStatus);
        if (status !== 'other' && statusSeen[status] === undefined) statusSeen[status] = rawStatus;
        const total = get(raw, 'order_total', null);
        const items = get(raw, 'order_items', []);
        return {
            id,
            code: String(get(raw, 'order_code', '#' + id)),
            customer: String(isObj ? nestGet(cust, NEST.name, '(không rõ)') : cust || '(không rõ)'),
            phone: String(isObj ? nestGet(cust, NEST.phone) : get(raw, 'order_phone', '')),
            address: String(get(raw, 'order_address', isObj ? nestGet(cust, NEST.address) : '')),
            date: toIso(get(raw, 'order_date', '')),
            status, statusRaw: String(rawStatus),
            payment: String(get(raw, 'order_payment', '')),
            total: total == null || isNaN(Number(total)) ? null : Number(total), // null = tự tính từ các dòng sản phẩm
            items: (Array.isArray(items) ? items : []).map((it) => {
                // Sản phẩm trong dòng có thể là object, id số, hoặc nằm thẳng trong dòng
                const p = get(it, 'item_product', null);
                const po = p && typeof p === 'object' ? p : {};
                return {
                    productId: get(it, 'item_productId', po.id ?? (typeof p === 'number' ? p : undefined)),
                    name: get(it, 'item_name', po.name ?? po.tenSanPham),
                    price: Number(get(it, 'item_price', po.price ?? po.giaBan)) || undefined,
                    qty: Number(get(it, 'item_qty', 1)) || 1,
                };
            }),
            _raw: raw, // giữ dữ liệu gốc
        };
    }

    // Giao diện -> API: chỉ ghi lại những trường mà form đơn hàng cho sửa
    function toApiOrder(item) {
        const raw = { ...(item._raw || {}) };
        const ref = item._raw || sampleOrder || {};
        const setIf = (key, val) => { const k = pick(ref, key); if (k) raw[k] = val; }; // chỉ ghi nếu backend có trường này

        // Khách hàng: nếu backend để dạng object lồng thì cập nhật từng trường bên trong
        const ck = pick(raw, 'order_customer');
        if (ck && raw[ck] && typeof raw[ck] === 'object') {
            const o = { ...raw[ck] };
            [['name', item.customer], ['phone', item.phone], ['address', item.address]].forEach(([f, v]) => { const k = NEST[f].find((x) => x in o); if (k) o[k] = v; });
            raw[ck] = o;
        } else setIf('order_customer', item.customer);
        setIf('order_phone', item.phone); setIf('order_address', item.address); setIf('order_payment', item.payment);

        // Chỉ ghi trạng thái khi người dùng thật sự đổi; nếu không, giữ nguyên giá trị gốc của backend
        const sk = pick(ref, 'order_status') || 'status';
        const original = item._raw ? normOrderStatus(item._raw[sk]) : null;
        if (item.status !== 'other' && item.status !== original) raw[sk] = statusToRaw(item.status, ref[sk]);
        return raw;
    }

    /* =================================================================
     * [5] LỚP TRUY CẬP DỮ LIỆU (api)
     * Giao diện chỉ gọi api.list / api.save / api.remove, không quan tâm
     * dữ liệu đến từ backend thật hay dữ liệu mẫu.
     *   name = 'products' | 'categories' | 'orders'
     * ================================================================= */
    const api = {
        // Lấy danh sách và đổi sang dạng thống nhất của giao diện
        list: async (name) => {
            if (MOCK[name]) return clone(db[name]);
            const arr = unwrapList(await http(ENDPOINTS[name]));
            if (name === 'orders') {
                if (arr[0]) { sampleOrder = arr[0]; console.info('[Bubu] Mẫu JSON từ ' + ENDPOINTS.orders + ':', arr[0]); }
                return arr.map(fromApiOrder);
            }
            if (name !== 'products') return arr; // danh mục: dùng nguyên dạng từ API
            if (arr[0]) { sampleRaw = arr[0]; console.info('[Bubu] Mẫu JSON từ ' + ENDPOINTS.products + ':', arr[0]); }
            return arr.map(fromApiProduct);
        },

        // Thêm mới (không có id -> POST) hoặc cập nhật (có id -> PUT)
        save: async (name, item) => {
            if (!MOCK[name]) {
                const conv = { products: toApiProduct, orders: toApiOrder }[name]; // hàm đổi giao diện -> API
                const body = JSON.stringify(conv ? conv(item) : item);
                return item.id
                    ? http(`${ENDPOINTS[name]}/${item.id}`, { method: 'PUT', body })
                    : http(ENDPOINTS[name], { method: 'POST', body });
            }
            // Chế độ dữ liệu mẫu: ghi vào bộ nhớ db
            if (item.id) {
                const i = db[name].findIndex((x) => x.id === item.id);
                db[name][i] = { ...db[name][i], ...item };
            } else {
                item.id = db.nextId[name]++;
                db[name].unshift(item);
            }
            return item;
        },

        // Xóa theo id
        remove: async (name, id) => {
            if (!MOCK[name]) return http(`${ENDPOINTS[name]}/${id}`, { method: 'DELETE' });
            db[name] = db[name].filter((x) => x.id !== id);
        },

        // --- Ảnh sản phẩm (gửi file nên dùng FormData, không đi qua save) ---
        // Thêm một hoặc nhiều ảnh cho sản phẩm
        uploadImages: (productId, files) => {
            const fd = new FormData();
            fd.append('productId', productId);
            files.forEach((f) => fd.append('files', f));
            return http(ENDPOINTS.images, { method: 'POST', body: fd });
        },
        // Thay nội dung một ảnh bằng file khác
        replaceImage: (id, file) => {
            const fd = new FormData();
            fd.append('file', file);
            return http(`${ENDPOINTS.images}/${id}/file`, { method: 'PUT', body: fd });
        },
        // Đặt làm ảnh đại diện
        setMainImage: (id) => http(`${ENDPOINTS.images}/${id}/main`, { method: 'PUT' }),
    };

    /* =================================================================
     * [6] TRẠNG THÁI & HẰNG SỐ GIAO DIỆN
     * ================================================================= */

    // Bộ lọc / trang hiện tại của từng màn hình (giữ lại khi chuyển qua lại giữa các màn)
    const state = {
        route: 'products',
        products: { q: '', cat: '', status: '', sort: 'new', page: 1 },
        categories: { q: '', page: 1 },
        orders: { q: '', status: '', page: 1 },
        accounts: { q: '', status: '', page: 1 },
    };

    // Dữ liệu đang hiển thị (nạp bởi reload())
    let data = { products: [], categories: [], orders: [], details: [], images: [], sizes: [], colors: [], accounts: [] };

    // Ảnh sản phẩm: tối đa 5 ảnh, chỉ nhận JPG / PNG / GIF / WebP (backend cũng kiểm tra lại)
    const MAX_IMAGES = 5;
    const IMG_ACCEPT = 'image/jpeg,image/png,image/gif,image/webp';
    const IMG_OK = /^image\/(jpeg|png|gif|webp)$/;

    // Nhãn + màu của trạng thái: [chữ hiển thị, class màu của thẻ .tag]
    const PRODUCT_STATUS = {
        active: ['Đang bán', 'ok'],
        hidden: ['Hết hàng', 'gray'],
        out: ['Hết hàng', 'bad'],
    };
    const ORDER_STATUS = {
        pending: ['Chờ xác nhận', 'warn'],
        confirmed: ['Đã xác nhận', 'info'],
        shipping: ['Đang giao', 'info'],
        done: ['Hoàn thành', 'ok'],
        cancelled: ['Đã hủy', 'bad'],
        other: ['Khác', 'gray'],
    };

    // --- Hàm tra cứu nhỏ dùng ở nhiều màn hình ---
    const tag = (map, key) => `<span class="tag ${map[key][1]}">${map[key][0]}</span>`;
    // Thẻ trạng thái đơn hàng; trạng thái lạ ('other') thì hiện nguyên chữ của backend
    const orderTag = (o) => (o.status === 'other' ? `<span class="tag gray">${esc(o.statusRaw || 'Khác')}</span>` : tag(ORDER_STATUS, o.status));
    const catName = (id) => (data.categories.find((c) => c.id === id) || {}).name || '—';
    const prodById = (id) => data.products.find((p) => p.id === id);
    // Các biến thể (size / màu / số lượng) của một sản phẩm
    const detailsOf = (pid) => data.details.filter((d) => d.productId === pid);
    // Ảnh của một sản phẩm (ảnh đại diện đứng đầu) và đường dẫn hiển thị của một ảnh
    const imagesOf = (pid) => data.images.filter((i) => i.productId === pid).sort((a, b) => (b.main - a.main) || (a.sortOrder - b.sortOrder) || (a.id - b.id));
    const imgUrl = (im) => `${ENDPOINTS.images}/${im.id}/file?v=${im.version}`;
    // Ô ảnh nhỏ của sản phẩm: ảnh đại diện; chưa có ảnh thì dùng link cũ (nếu có); không thì hiện emoji
    const productThumb = (p) => {
        const main = imagesOf(p.id)[0];
        const src = main ? imgUrl(main) : p.image;
        return src ? `<img src="${esc(src)}" alt="">` : esc(p.icon || '📦');
    };
    // Tra cứu size / màu theo id (biến thể chỉ lưu sizeId, colorId)
    const sizeById = (id) => data.sizes.find((s) => s.id === id);
    const colorById = (id) => data.colors.find((c) => c.id === id);
    const sizeName = (id) => (sizeById(id) || {}).name ?? '?';
    const colorName = (id) => (colorById(id) || {}).name ?? '?';
    // So sánh tên theo kiểu tự nhiên: 9 < 10 < 39, A < B
    const sortByName = (a, b) => String(a.name).localeCompare(String(b.name), 'vi', { numeric: true });
    // Tồn kho của sản phẩm: có biến thể thì bằng tổng số lượng các biến thể, chưa có thì dùng tồn kho riêng của sản phẩm
    const stockOf = (p) => { const ds = detailsOf(p.id); return ds.length ? ds.reduce((s, d) => s + (Number(d.quantity) || 0), 0) : p.stock; };
    // Thông tin hiển thị của một dòng sản phẩm trong đơn (ưu tiên dữ liệu trong đơn, thiếu thì lấy từ sản phẩm)
    const itemInfo = (it) => {
        const p = prodById(it.productId) || {};
        return { name: it.name ?? p.name ?? '(không rõ)', price: it.price ?? p.price ?? 0, icon: p.icon };
    };
    // Tổng tiền đơn: dùng số backend trả về; không có thì tự cộng từ các dòng
    const orderTotal = (o) => (o.total != null ? o.total : o.items.reduce((s, it) => s + itemInfo(it).price * it.qty, 0));

    // Tải lại toàn bộ dữ liệu từ API, gắn danh mục cho sản phẩm và cập nhật số đơn chờ xác nhận ở menu
    async function reload() {
        // Biến thể: nếu API chưa sẵn sàng thì tạm coi như rỗng để các màn hình khác vẫn chạy
        const detailsReq = api.list('details').catch((e) => { console.warn('[Bubu] Không tải được biến thể:', e.message); return []; });
        // Tài khoản: tương tự, API chưa sẵn sàng thì coi như rỗng
        const accountsReq = api.list('accounts').catch((e) => { console.warn('[Bubu] Không tải được tài khoản:', e.message); return []; });
        // Size và màu: dùng cho biến thể; API chưa sẵn sàng thì coi như rỗng
        const sizesReq = api.list('sizes').catch((e) => { console.warn('[Bubu] Không tải được size:', e.message); return []; });
        const colorsReq = api.list('colors').catch((e) => { console.warn('[Bubu] Không tải được màu:', e.message); return []; });
        // Ảnh: API chưa sẵn sàng thì coi như rỗng (sản phẩm hiện emoji thay ảnh)
        const imagesReq = api.list('images').catch((e) => { console.warn('[Bubu] Không tải được ảnh:', e.message); return []; });
        const [products, categories, orders, details, images, sizes, colors, accounts] = await Promise.all([api.list('products'), api.list('categories'), api.list('orders'), detailsReq, imagesReq, sizesReq, colorsReq, accountsReq]);
        data = { products, categories, orders, details, images, sizes, colors, accounts };
        if (!MOCK.products) data.categories = linkCategories(products, categories);
        const pending = orders.filter((o) => o.status === 'pending').length;
        const b = $('#pendingBadge');
        b.textContent = pending;
        b.classList.toggle('zero', pending === 0);
    }

    /* =================================================================
     * [7] THÀNH PHẦN GIAO DIỆN CHUNG
     * ================================================================= */

    /* ---------- Toast: thông báo nhỏ tự biến mất sau 2.8 giây ---------- */
    function toast(msg, type = 'ok') {
        const el = document.createElement('div');
        el.className = 'toast ' + type;
        el.textContent = msg;
        $('#toasts').appendChild(el);
        setTimeout(() => el.remove(), 2800);
    }

    /* ---------- Modal: hộp thoại giữa màn hình (form thêm/sửa, xác nhận xóa) ---------- */
    function openModal({ title, body, foot }) {
        $('#modalTitle').textContent = title;
        $('#modalBody').innerHTML = body;
        $('#modalFoot').innerHTML = foot || '';
        // xóa các handler riêng của modal trước (ví dụ modal biến thể)
        const mb = $('#modalBody');
        mb.onclick = null; mb.onchange = null; mb.onkeydown = null; mb.oninput = null;
        $('#modal').hidden = false;
        const first = $('#modalBody input, #modalBody select, #modalBody textarea');
        if (first) first.focus(); // tự đặt con trỏ vào ô đầu tiên
    }
    const closeModal = () => ($('#modal').hidden = true);

    /* ---------- Drawer: ngăn kéo bên phải (xem chi tiết) ---------- */
    function openDrawer({ title, body, foot }) {
        $('#drawerTitle').textContent = title;
        $('#drawerBody').innerHTML = body;
        $('#drawerFoot').innerHTML = foot || '';
        $('#drawer').hidden = false;
    }
    const closeDrawer = () => ($('#drawer').hidden = true);

    /* ---------- Hộp xác nhận xóa (dùng chung cho cả 3 màn hình) ----------
     * onYes là hàm async thực hiện việc xóa; lỗi sẽ hiện toast đỏ. */
    function confirmDelete(text, onYes) {
        openModal({
            title: 'Xác nhận xóa',
            body: `<p style="line-height:1.6">${text}</p><p class="err" style="margin-top:8px">Hành động này không thể hoàn tác.</p>`,
            foot: `<button class="btn" data-close>Hủy</button><button class="btn btn-danger" id="yesDel">Xóa</button>`,
        });
        $('#yesDel').onclick = async () => {
            try { await onYes(); closeModal(); } catch (e) { toast(e.message, 'bad'); }
        };
    }

    /* ---------- Phân trang ---------- */
    // Cắt danh sách theo trang; tự kéo về trang cuối nếu trang hiện tại vượt quá
    function paginate(list, page) {
        const pages = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
        const cur = Math.min(page, pages);
        return { rows: list.slice((cur - 1) * PAGE_SIZE, cur * PAGE_SIZE), cur, pages, total: list.length };
    }
    // HTML thanh phân trang ("Hiển thị 1–8 / 20" + các nút số trang)
    function pagerHtml(p) {
        if (p.total === 0) return '';
        const from = (p.cur - 1) * PAGE_SIZE + 1;
        const to = Math.min(p.cur * PAGE_SIZE, p.total);
        let btns = `<button class="pg" data-page="${p.cur - 1}" ${p.cur === 1 ? 'disabled' : ''}>‹</button>`;
        for (let i = 1; i <= p.pages; i++) btns += `<button class="pg ${i === p.cur ? 'on' : ''}" data-page="${i}">${i}</button>`;
        btns += `<button class="pg" data-page="${p.cur + 1}" ${p.cur === p.pages ? 'disabled' : ''}>›</button>`;
        return `<div class="pager"><span>Hiển thị ${from}–${to} / ${p.total}</span><div class="pager-btns">${btns}</div></div>`;
    }

    /* ---------- Các mảnh HTML dùng lại ---------- */
    // Cụm 3 nút Xem / Sửa / Xóa ở cuối mỗi dòng (click được xử lý ở phần [12])
    // extra: HTML nút bổ sung đặt trước 3 nút mặc định (ví dụ nút "Biến thể" ở bảng sản phẩm)
    const actionBtns = (id, extra = '') => `
    <div class="actions">
      ${extra}
      <button class="icon-btn view" data-act="view" data-id="${id}" title="Xem chi tiết">${ICON.view}</button>
      <button class="icon-btn edit" data-act="edit" data-id="${id}" title="Sửa">${ICON.edit}</button>
      <button class="icon-btn del" data-act="del" data-id="${id}" title="Xóa">${ICON.del}</button>
    </div>`;
    // Khối "không có dữ liệu"
    const emptyHtml = (msg) => `<div class="empty"><div class="big">🔍</div><div>${msg}</div></div>`;

    /* =================================================================
     * [8] MÀN HÌNH SẢN PHẨM
     *   renderProducts()     - khung trang: ô thống kê + thanh lọc
     *   renderProductList()  - chỉ vẽ lại bảng (gọi khi gõ tìm / đổi lọc / đổi trang)
     *   productForm()        - form thêm / sửa
     *   productDetail()      - ngăn kéo xem chi tiết
     * ================================================================= */

    // Áp bộ lọc + sắp xếp hiện tại lên danh sách sản phẩm
    function filteredProducts() {
        const f = state.products;
        let list = data.products.filter((p) => {
            if (f.q && !(norm(p.name).includes(norm(f.q)) || norm(p.sku).includes(norm(f.q)))) return false;
            if (f.cat && String(p.categoryId) !== f.cat) return false;
            if (f.status && p.status !== f.status) return false;
            return true;
        });
        const sorters = {
            new: (a, b) => b.id - a.id,
            priceAsc: (a, b) => a.price - b.price,
            priceDesc: (a, b) => b.price - a.price,
            name: (a, b) => a.name.localeCompare(b.name, 'vi'),
            stock: (a, b) => stockOf(a) - stockOf(b),
        };
        return list.sort(sorters[f.sort]);
    }

    // Khung trang sản phẩm: 4 ô thống kê + thanh công cụ lọc; bảng được vẽ riêng ở renderProductList()
    function renderProducts() {
        const f = state.products;
        const all = data.products;
        // [màu, icon, con số, nhãn]
        const stats = [
            ['c1', ICON.box, all.length, 'Tổng sản phẩm'],
            ['c2', ICON.check, all.filter((p) => p.status === 'active').length, 'Đang bán'],
            ['c3', ICON.alert, all.filter((p) => stockOf(p) > 0 && stockOf(p) <= 10).length, 'Sắp hết hàng (≤ 10)'],
            ['c4', ICON.cancel, all.filter((p) => stockOf(p) === 0).length, 'Hết hàng'],
        ];
        $('#content').innerHTML = `
      <div class="stats">${stats.map(([c, i, n, l]) => `<div class="stat"><div class="stat-ico ${c}">${i}</div><div><div class="stat-num">${n}</div><div class="stat-lbl">${l}</div></div></div>`).join('')}</div>
      <div class="card">
        <div class="toolbar">
          <div class="search">${ICON.search}<input id="fQ" placeholder="Tìm theo tên hoặc mã SP..." value="${esc(f.q)}"></div>
          <select class="select" id="fCat"><option value="">Tất cả danh mục</option>${data.categories.map((c) => `<option value="${c.id}" ${String(c.id) === f.cat ? 'selected' : ''}>${esc(c.name)}</option>`).join('')}</select>
          <select class="select" id="fStatus">
            <option value="">Mọi trạng thái</option>
            ${Object.entries(PRODUCT_STATUS).map(([k, v]) => `<option value="${k}" ${k === f.status ? 'selected' : ''}>${v[0]}</option>`).join('')}
          </select>
          <select class="select" id="fSort">
            ${[['new', 'Mới nhất'], ['priceAsc', 'Giá tăng dần'], ['priceDesc', 'Giá giảm dần'], ['name', 'Tên A → Z'], ['stock', 'Tồn kho thấp']].map(([k, l]) => `<option value="${k}" ${k === f.sort ? 'selected' : ''}>${l}</option>`).join('')}
          </select>
          <button class="btn" id="fReset">Xóa lọc</button>
        </div>
        <div id="list"></div>
      </div>`;
        // Gắn sự kiện lọc: đổi bộ lọc -> về trang 1 -> vẽ lại bảng
        $('#fQ').oninput = (e) => { f.q = e.target.value; f.page = 1; renderProductList(); };
        $('#fCat').onchange = (e) => { f.cat = e.target.value; f.page = 1; renderProductList(); };
        $('#fStatus').onchange = (e) => { f.status = e.target.value; f.page = 1; renderProductList(); };
        $('#fSort').onchange = (e) => { f.sort = e.target.value; renderProductList(); };
        $('#fReset').onclick = () => { Object.assign(f, { q: '', cat: '', status: '', sort: 'new', page: 1 }); renderProducts(); };
        renderProductList();
    }

    // Vẽ bảng sản phẩm + phân trang vào #list
    function renderProductList() {
        const p = paginate(filteredProducts(), state.products.page);
        state.products.page = p.cur;
        const rows = p.rows.map((x) => `
      <tr>
        <td><div class="prod"><div class="thumb">${productThumb(x)}</div>
          <div><div class="prod-name">${esc(x.name)}</div><div class="prod-sku">${esc(x.sku)}</div></div></div></td>
        <td><span class="chip">${esc(catName(x.categoryId))}</span></td>
        <td class="num price">${money(x.price)}</td>
        <td class="num ${stockOf(x) <= 10 ? 'low' : ''}">${stockOf(x)}</td>
        <td>${tag(PRODUCT_STATUS, x.status)}</td>
        <td>${actionBtns(x.id, `<button class="icon-btn" data-act="variants" data-id="${x.id}" title="Biến thể, size, màu và ảnh">${ICON.variants}</button>`)}</td>
      </tr>`).join('');
        $('#list').innerHTML = p.total === 0
            ? emptyHtml('Không tìm thấy sản phẩm phù hợp.')
            : `<div class="table-wrap"><table>
          <thead><tr><th>Sản phẩm</th><th>Danh mục</th><th class="num">Giá bán</th><th class="num">Tồn kho</th><th>Trạng thái</th><th class="num">Thao tác</th></tr></thead>
          <tbody>${rows}</tbody></table></div>${pagerHtml(p)}`;
    }

    // Form thêm (không truyền p) hoặc sửa (truyền sản phẩm) trong modal
    function productForm(p = {}) {
        const isEdit = !!p.id;
        openModal({
            title: isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
            body: `<form id="pf" class="form-grid" novalidate>
        <div class="field full"><label>Tên sản phẩm <em>*</em></label><input class="input" name="name" value="${esc(p.name)}" placeholder="VD: Nike"><span class="err" data-err="name"></span></div>
        ${isEdit ? `
            <div class="field">
                <label>Mã SP</label>
                <input class="input" name="sku" value="${esc(p.sku)}" readonly>
            </div>
        ` : ''}        
        <div class="field"><label>Danh mục <em>*</em></label><select class="select" name="categoryId">${data.categories.map((c) => `<option value="${c.id}" ${c.id === p.categoryId ? 'selected' : ''}>${esc(c.name)}</option>`).join('')}</select><span class="err" data-err="categoryId"></span></div>
        <div class="field"><label>Giá bán (₫) <em>*</em></label><input class="input" type="number" min="0" step="1000" name="price" value="${p.price ?? ''}"><span class="err" data-err="price"></span></div>
     
        <div class="field"><label>Trạng thái</label><select class="select" name="status">${Object.entries(PRODUCT_STATUS).map(([k, v]) => `<option value="${k}" ${k === (p.status || 'active') ? 'selected' : ''}>${v[0]}</option>`).join('')}</select></div>
        <div class="field"><label>Biểu tượng (emoji)</label><input class="input" name="icon" value="${esc(p.icon || '📦')}" maxlength="4"></div>
        ${isEdit ? `
        <div class="field full"><label>Ảnh sản phẩm</label>
          <div class="vm-cur"><div class="thumb">${productThumb(p)}</div>
            <button type="button" class="btn" id="pfImg">Quản lý ảnh (${imagesOf(p.id).length}/${MAX_IMAGES})</button></div></div>
        ` : `
        <div class="field full"><label>Ảnh đại diện <em>*</em></label>
          <input class="input" type="file" name="imageFile" accept="${IMG_ACCEPT}">
          <img class="vm-prev" id="imgPrev" alt="" hidden>
          <span class="err" data-err="imageFile"></span>
          <div class="vm-hint" style="margin:6px 0 0">Thêm tối đa ${MAX_IMAGES} ảnh ở nút "Biến thể, size, màu và ảnh" sau khi lưu.</div></div>
        `}
        <div class="field full"><label>Mô tả</label><textarea name="description" placeholder="Mô tả ngắn về sản phẩm">${esc(p.description)}</textarea></div>
      </form>`,
            foot: `<button class="btn" data-close>Hủy</button><button class="btn btn-primary" id="saveBtn">${isEdit ? 'Lưu thay đổi' : 'Thêm sản phẩm'}</button>`,
        });
        // Sửa sản phẩm: nút mở thẳng tab Ảnh; Thêm sản phẩm: xem trước ảnh vừa chọn
        if (isEdit) $('#pfImg').onclick = () => { closeModal(); variantManager(p.id, 'images'); };
        else {
            $('#pf [name=imageFile]').onchange = (e) => {
                const f = e.target.files[0], prev = $('#imgPrev');
                if (prev.src.startsWith('blob:')) URL.revokeObjectURL(prev.src);
                prev.hidden = !f;
                if (f) prev.src = URL.createObjectURL(f);
            };
        }
        $('#saveBtn').onclick = async () => {
            const fd = Object.fromEntries(new FormData($('#pf')));
            // Kiểm tra dữ liệu nhập
            $$('[data-err]').forEach((e) => (e.textContent = ''));
            let bad = false;
            // Thêm mới bắt buộc có một ảnh đại diện
            const file = isEdit ? null : fd.imageFile;
            if (!isEdit) {
                if (!file || !file.size) { $('[data-err=imageFile]').textContent = 'Vui lòng chọn ảnh đại diện'; bad = true; }
                else if (!IMG_OK.test(file.type)) { $('[data-err=imageFile]').textContent = 'Chỉ nhận ảnh JPG, PNG, GIF hoặc WebP'; bad = true; }
            }
            if (!fd.name.trim()) { $('[data-err=name]').textContent = 'Vui lòng nhập tên sản phẩm'; bad = true; }
            if (fd.price === '' || Number(fd.price) < 0) { $('[data-err=price]').textContent = 'Giá không hợp lệ'; bad = true; }
            if (!fd.categoryId) { $('[data-err=categoryId]').textContent = 'Vui lòng chọn danh mục (hãy tạo danh mục trước nếu chưa có)'; bad = true; }
            if (bad) return;
            const item = {
                ...p,
                name: fd.name.trim(),
                categoryId: Number(fd.categoryId) || undefined,
                price: Number(fd.price),
                stock: Number(fd.stock) || 0,
                status: fd.status,
                icon: fd.icon || '📦',
                image: p.image || '', // ảnh thật nằm ở bảng Image; giữ nguyên link cũ (nếu có) cho dữ liệu cũ
                description: fd.description.trim(),
            };
            const btn = $('#saveBtn');
            btn.disabled = true; // chống bấm lưu 2 lần (tránh tạo trùng sản phẩm)
            try {
                const saved = await api.save('products', item);
                if (!isEdit) {
                    // Sản phẩm mới: tải ảnh đại diện lên; lỗi thì xóa sản phẩm vừa tạo để không có sản phẩm thiếu ảnh
                    const newId = get(saved, 'id', null);
                    if (newId == null) throw new Error('Không lấy được mã sản phẩm vừa tạo để tải ảnh lên');
                    try { await api.uploadImages(newId, [file]); }
                    catch (e) {
                        await api.remove('products', newId).catch(() => {});
                        throw new Error('Không tải được ảnh nên chưa thêm sản phẩm: ' + e.message);
                    }
                }
                await reload();
                closeModal();
                render();
                toast(isEdit ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm mới');
            } catch (e) { btn.disabled = false; toast(e.message, 'bad'); }
        };
    }

    // Ngăn kéo xem chi tiết một sản phẩm
    function productDetail(id) {
        const p = prodById(id);
        if (!p) return;
        openDrawer({
            title: 'Chi tiết sản phẩm',
            body: `
        <div class="detail-hero">${productThumb(p)}</div>
        <div class="detail-title">${esc(p.name)}</div>
        <div>${tag(PRODUCT_STATUS, p.status)}</div>
        <div class="detail-price">${money(p.price)}</div>
        <dl class="kv">
          <dt>Mã sản phẩm</dt><dd>${esc(p.sku)}</dd>
          <dt>Danh mục</dt><dd>${esc(catName(p.categoryId))}</dd>
          <dt>Tồn kho</dt><dd class="${stockOf(p) <= 10 ? 'low' : ''}">${stockOf(p)}</dd>
        </dl>
        <div class="detail-desc">${esc(p.description) || '<i>Chưa có mô tả.</i>'}</div>
        <h4 style="margin:18px 0 6px">Biến thể (${detailsOf(p.id).length})</h4>
        ${detailsOf(p.id).length ? `<table class="items"><tbody>${detailsOf(p.id).map((d) => `<tr><td>Size ${esc(sizeName(d.sizeId))} · ${esc(colorName(d.colorId))}</td><td class="num">${esc(d.quantity)}</td></tr>`).join('')}</tbody></table>` : '<div style="color:var(--muted)">Chưa có biến thể.</div>'}`,
            foot: `<button class="btn" data-close>Đóng</button><button class="btn" id="dVar">Quản lý biến thể</button><button class="btn btn-primary" id="dEdit">Sửa sản phẩm</button>`,
        });
        $('#dVar').onclick = () => { closeDrawer(); variantManager(p.id, 'variants'); };
        $('#dEdit').onclick = () => { closeDrawer(); productForm(p); };
    }

    /* ---------- [8.1] Quản lý biến thể + Size + Màu (modal 3 tab) ----------
     * Một modal duy nhất, 3 tab, không có thanh cuộn ngang:
     *   Tab "Biến thể": chọn Size, Màu (từ danh sách) + số lượng rồi bấm Thêm.
     *                   Mỗi biến thể một hàng; sửa số lượng ngay trong ô, rời ô là tự lưu.
     *   Tab "Size":     thêm size mới; sửa tên ngay trong ô (rời ô là tự lưu); xóa.
     *   Tab "Màu":      thêm màu mới (tên + mã màu); sửa tên / mã màu ngay trong hàng; xóa.
     * Size / màu đang có biến thể sử dụng thì backend từ chối xóa (409) và hiện thông báo.
     * Sau mỗi thay đổi: tải lại dữ liệu, vẽ lại bảng sản phẩm phía sau (tồn kho) và vẽ lại modal. */

    let vmTab = 'variants'; // tab đang mở: 'variants' | 'sizes' | 'colors'

    // CSS riêng cho modal này, chèn vào trang một lần duy nhất
    function injectVariantStyle() {
        if ($('#variantStyle')) return;
        const s = document.createElement('style');
        s.id = 'variantStyle';
        s.textContent = `
          .vm-tabs{display:flex;gap:6px;margin-bottom:14px;border-bottom:1px solid var(--line,#e5e5e5)}
          .vm-tab{border:0;background:none;padding:8px 14px;cursor:pointer;font:inherit;color:var(--muted,#888);border-bottom:2px solid transparent;margin-bottom:-1px}
          .vm-tab.on{color:var(--brand,#e91e63);border-bottom-color:var(--brand,#e91e63);font-weight:700}
          .vm-add{display:grid;gap:8px;align-items:end;padding:12px;border:1px dashed var(--line,#d8d8d8);border-radius:10px;margin-bottom:14px}
          .vm-add-v{grid-template-columns:1fr 1fr 90px auto}
          .vm-add-s{grid-template-columns:1fr auto}
          .vm-add-c{grid-template-columns:1fr 64px auto}
          .vm-add label{display:block;font-size:12px;color:var(--muted,#888);margin-bottom:4px}
          .vm-add .input,.vm-add .select{width:100%;min-width:0;box-sizing:border-box}
          .vm-hint{margin:-6px 0 12px;font-size:13px;color:var(--muted,#888)}
          .vm-sum{display:flex;justify-content:space-between;font-size:13px;color:var(--muted,#888);margin:0 2px 8px}
          .vm-list{display:flex;flex-direction:column;gap:6px;max-height:320px;overflow-y:auto;overflow-x:hidden}
          .vm-row{display:flex;align-items:center;gap:10px;padding:8px 10px;border:1px solid var(--line,#e5e5e5);border-radius:10px}
          .vm-size{flex:none;min-width:64px;font-weight:700}
          .vm-color{flex:1;min-width:0;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}
          .vm-qty{flex:none;width:90px;box-sizing:border-box}
          .vm-name{flex:1;min-width:0;box-sizing:border-box}
          .vm-use{flex:none;font-size:12px;color:var(--muted,#888)}
          .vm-pick{flex:none;width:40px;height:32px;padding:0;border:1px solid var(--line,#d8d8d8);border-radius:6px;background:none;cursor:pointer}
          .vm-dot{display:inline-block;width:12px;height:12px;border-radius:50%;margin-right:6px;vertical-align:-1px;border:1px solid rgba(0,0,0,.2)}
          .vm-dot.none{border-style:dashed;background:none}
          .vm-empty{padding:16px 0;text-align:center;color:var(--muted,#888)}
          .vm-add-i{grid-template-columns:1fr auto}
          .vm-imgs{display:grid;grid-template-columns:repeat(auto-fill,minmax(150px,1fr));gap:10px;max-height:340px;overflow-y:auto;overflow-x:hidden}
          .vm-img{position:relative;display:flex;flex-direction:column;border:1px solid var(--line,#e5e5e5);border-radius:10px;overflow:hidden}
          .vm-img img{display:block;width:100%;height:120px;object-fit:cover;background:#f4f4f4}
          .vm-badge{position:absolute;top:6px;left:6px;padding:2px 8px;border-radius:99px;background:var(--brand,#e91e63);color:#fff;font-size:11px}
          .vm-img-act{display:flex;flex-wrap:wrap;gap:4px;align-items:center;padding:6px}
          .vm-img-act .btn{padding:4px 8px;font-size:12px}
          .vm-prev{display:block;max-width:120px;max-height:120px;margin-top:8px;border-radius:8px;border:1px solid var(--line,#e5e5e5)}
          .vm-prev[hidden]{display:none}
          .vm-cur{display:flex;align-items:center;gap:12px}
          @media (max-width:520px){.vm-add-v{grid-template-columns:1fr 1fr}.vm-add-v button{grid-column:1/-1}}`;
        document.head.appendChild(s);
    }

    // tab: truyền vào để mở đúng tab; bỏ trống = giữ tab đang mở (dùng khi vẽ lại sau khi lưu)
    function variantManager(productId, tab) {
        const p = prodById(productId);
        if (!p) return;
        if (tab) vmTab = tab;
        injectVariantStyle();

        const sizes = [...data.sizes].sort(sortByName);
        const colors = [...data.colors].sort(sortByName);
        const list = detailsOf(productId).sort((a, b) =>
            sortByName({ name: sizeName(a.sizeId) }, { name: sizeName(b.sizeId) })
            || sortByName({ name: colorName(a.colorId) }, { name: colorName(b.colorId) }));
        const usedSize = (id) => data.details.filter((d) => d.sizeId === id).length;
        const usedColor = (id) => data.details.filter((d) => d.colorId === id).length;
        const dot = (hex) => `<i class="vm-dot ${hex ? '' : 'none'}" ${hex ? `style="background:${esc(hex)}"` : ''}></i>`;
        const options = (arr, ph) => `<option value="">${ph}</option>` + arr.filter((x) => x.active !== false).map((x) => `<option value="${x.id}">${esc(x.name)}</option>`).join('');

        // ----- Tab 1: biến thể của sản phẩm -----
        const variantRow = (d) => `
          <div class="vm-row" data-vid="${d.id}">
            <span class="vm-size">Size ${esc(sizeName(d.sizeId))}</span>
            <span class="vm-color" title="${esc(colorName(d.colorId))}">${dot((colorById(d.colorId) || {}).hexCode)}${esc(colorName(d.colorId))}</span>
            <input class="input vm-qty" type="number" min="0" step="1" data-qty value="${esc(d.quantity)}" title="Số lượng (rời ô là tự lưu)">
            <button class="icon-btn del" data-vact="del" title="Xóa biến thể">${ICON.del}</button>
          </div>`;
        const panelVariants = `
          <div class="vm-add vm-add-v">
            <div><label>Size</label><select class="select" data-f="sizeId">${options(sizes, 'Chọn size')}</select></div>
            <div><label>Màu</label><select class="select" data-f="colorId">${options(colors, 'Chọn màu')}</select></div>
            <div><label>Số lượng</label><input class="input" type="number" min="0" step="1" data-f="quantity" placeholder="VD: 10"></div>
            <button class="btn btn-primary" data-vact="add">+ Thêm</button>
          </div>
          ${!sizes.length || !colors.length ? '<div class="vm-hint">Chưa có size hoặc màu để chọn. Hãy thêm ở tab "Size" / "Màu" trước.</div>' : ''}
          <div class="vm-sum"><span>${list.length} biến thể</span><span>Tổng tồn kho: <b>${stockOf(p)}</b></span></div>
          <div class="vm-list">${list.length ? list.map(variantRow).join('') : '<div class="vm-empty">Chưa có biến thể. Chọn size, màu, số lượng ở trên rồi bấm Thêm.</div>'}</div>`;

        // ----- Tab 2: quản lý Size -----
        const sizeRow = (s) => `
          <div class="vm-row" data-sid="${s.id}">
            <input class="input vm-name" data-sname maxlength="20" value="${esc(s.name)}" title="Sửa tên (rời ô là tự lưu)">
            <span class="vm-use">${usedSize(s.id)} biến thể</span>
            <button class="icon-btn del" data-vact="delSize" title="Xóa size">${ICON.del}</button>
          </div>`;
        const panelSizes = `
          <div class="vm-add vm-add-s">
            <div><label>Tên size mới</label><input class="input" data-f="sizeName" maxlength="20" placeholder="VD: 41 hoặc M"></div>
            <button class="btn btn-primary" data-vact="addSize">+ Thêm size</button>
          </div>
          <div class="vm-sum"><span>${sizes.length} size</span><span>Size đang dùng không xóa được</span></div>
          <div class="vm-list">${sizes.length ? sizes.map(sizeRow).join('') : '<div class="vm-empty">Chưa có size nào.</div>'}</div>`;

        // ----- Tab 3: quản lý Màu -----
        const colorRow = (c) => `
          <div class="vm-row" data-cid="${c.id}">
            <input class="vm-pick" type="color" data-chex data-set="${c.hexCode ? 1 : 0}" value="${esc(c.hexCode || '#cccccc')}" title="Mã màu">
            <input class="input vm-name" data-cname maxlength="50" value="${esc(c.name)}" title="Sửa tên (rời ô là tự lưu)">
            <span class="vm-use">${usedColor(c.id)} biến thể</span>
            <button class="icon-btn del" data-vact="delColor" title="Xóa màu">${ICON.del}</button>
          </div>`;
        const panelColors = `
          <div class="vm-add vm-add-c">
            <div><label>Tên màu mới</label><input class="input" data-f="colorName" maxlength="50" placeholder="VD: Đen"></div>
            <div><label>Mã màu</label><input class="vm-pick" type="color" data-f="colorHex" data-set="0" value="#cccccc"></div>
            <button class="btn btn-primary" data-vact="addColor">+ Thêm màu</button>
          </div>
          <div class="vm-sum"><span>${colors.length} màu</span><span>Màu đang dùng không xóa được</span></div>
          <div class="vm-list">${colors.length ? colors.map(colorRow).join('') : '<div class="vm-empty">Chưa có màu nào.</div>'}</div>`;

        // ----- Tab 4: ảnh sản phẩm (tối đa 5, ảnh đầu tiên là ảnh đại diện) -----
        const imgs = imagesOf(productId);
        const full = imgs.length >= MAX_IMAGES;
        const imageCard = (im) => `
          <div class="vm-img" data-iid="${im.id}">
            <img src="${imgUrl(im)}" alt="${esc(im.fileName || '')}">
            ${im.main ? '<span class="vm-badge">Đại diện</span>' : ''}
            <div class="vm-img-act">
              ${im.main ? '' : '<button class="btn" data-vact="mainImg">Đặt đại diện</button>'}
              <button class="btn" data-vact="replaceImg">Thay ảnh</button>
              <button class="icon-btn del" data-vact="delImg" title="Xóa ảnh">${ICON.del}</button>
            </div>
          </div>`;
        const panelImages = `
          <div class="vm-add vm-add-i">
            <div><label>${full ? 'Đã đủ ' + MAX_IMAGES + ' ảnh, hãy xóa bớt để thêm' : 'Chọn ảnh (còn ' + (MAX_IMAGES - imgs.length) + ' chỗ, có thể chọn nhiều ảnh)'}</label>
              <input class="input" type="file" multiple accept="${IMG_ACCEPT}" data-f="imgFiles" ${full ? 'disabled' : ''}></div>
            <button class="btn btn-primary" data-vact="addImg" ${full ? 'disabled' : ''}>+ Thêm ảnh</button>
          </div>
          <input type="file" hidden accept="${IMG_ACCEPT}" data-replace>
          <div class="vm-sum"><span>${imgs.length}/${MAX_IMAGES} ảnh</span><span>Ảnh đại diện hiện ở danh sách sản phẩm</span></div>
          ${imgs.length ? `<div class="vm-imgs">${imgs.map(imageCard).join('')}</div>` : '<div class="vm-empty">Chưa có ảnh. Chọn ảnh ở trên rồi bấm Thêm ảnh (ảnh đầu tiên sẽ là ảnh đại diện).</div>'}`;

        const tabs = [['variants', 'Biến thể (' + list.length + ')'], ['sizes', 'Size (' + sizes.length + ')'], ['colors', 'Màu (' + colors.length + ')'], ['images', 'Ảnh (' + imgs.length + ')']];
        openModal({
            title: 'Biến thể & ảnh: ' + p.name,
            body: `<div class="vm-tabs">${tabs.map(([k, l]) => `<button class="vm-tab ${k === vmTab ? 'on' : ''}" data-vact="tab" data-tab="${k}">${l}</button>`).join('')}</div>`
                + ({ variants: panelVariants, sizes: panelSizes, colors: panelColors, images: panelImages }[vmTab]),
            foot: `<button class="btn" data-close>Đóng</button>`,
        });

        const body = $('#modalBody');
        const val = (f) => body.querySelector(`[data-f=${f}]`).value.trim();
        // Tải lại dữ liệu rồi vẽ lại: bảng sản phẩm phía sau (tồn kho) + chính modal này
        const refresh = async () => { await reload(); render(); variantManager(productId); };

        // Kiểm tra rồi lưu biến thể (vid = null là thêm mới). Trả về true nếu đã lưu.
        const saveDetail = async (vid, sizeId, colorId, qtyStr) => {
            const quantity = Number(qtyStr);
            if (!sizeId) { toast('Vui lòng chọn size', 'bad'); return false; }
            if (!colorId) { toast('Vui lòng chọn màu', 'bad'); return false; }
            if (qtyStr === '' || !Number.isInteger(quantity) || quantity < 0) { toast('Số lượng phải là số nguyên từ 0 trở lên', 'bad'); return false; }
            // Không cho trùng cặp size + màu trong cùng một sản phẩm
            if (detailsOf(productId).some((d) => d.id !== vid && d.sizeId === sizeId && d.colorId === colorId)) {
                toast('Biến thể size ' + sizeName(sizeId) + ' màu ' + colorName(colorId) + ' đã tồn tại', 'bad');
                return false;
            }
            await api.save('details', { ...(vid ? { id: vid } : {}), productId, sizeId, colorId, quantity });
            return true;
        };

        // Các nút: đổi tab, Thêm, Xóa (biến thể / size / màu)
        body.onclick = async (e) => {
            const btn = e.target.closest('[data-vact]');
            if (!btn) return;
            const act = btn.dataset.vact;
            try {
                if (act === 'tab') { vmTab = btn.dataset.tab; variantManager(productId); return; }

                if (act === 'del') {
                    if (!confirm('Xóa biến thể này?')) return;
                    await api.remove('details', Number(btn.closest('.vm-row').dataset.vid));
                    toast('Đã xóa biến thể');
                } else if (act === 'add') {
                    if (!(await saveDetail(null, Number(val('sizeId')), Number(val('colorId')), val('quantity')))) return;
                    toast('Đã thêm biến thể');
                } else if (act === 'addSize') {
                    const name = val('sizeName');
                    if (!name) { toast('Vui lòng nhập tên size', 'bad'); return; }
                    await api.save('sizes', { name, active: true });
                    toast('Đã thêm size');
                } else if (act === 'delSize') {
                    const s = sizeById(Number(btn.closest('.vm-row').dataset.sid));
                    if (!s || !confirm(`Xóa size "${s.name}"?`)) return;
                    await api.remove('sizes', s.id);
                    toast('Đã xóa size');
                } else if (act === 'addColor') {
                    const name = val('colorName');
                    if (!name) { toast('Vui lòng nhập tên màu', 'bad'); return; }
                    const pick = body.querySelector('[data-f=colorHex]');
                    await api.save('colors', { name, hexCode: pick.dataset.set === '1' ? pick.value.toUpperCase() : null, active: true });
                    toast('Đã thêm màu');
                } else if (act === 'delColor') {
                    const c = colorById(Number(btn.closest('.vm-row').dataset.cid));
                    if (!c || !confirm(`Xóa màu "${c.name}"?`)) return;
                    await api.remove('colors', c.id);
                    toast('Đã xóa màu');
                } else if (act === 'addImg') {
                    const files = [...body.querySelector('[data-f=imgFiles]').files];
                    if (!files.length) { toast('Vui lòng chọn ít nhất 1 ảnh', 'bad'); return; }
                    if (files.length > MAX_IMAGES - imgs.length) { toast(`Chỉ thêm được tối đa ${MAX_IMAGES - imgs.length} ảnh nữa (mỗi sản phẩm tối đa ${MAX_IMAGES} ảnh)`, 'bad'); return; }
                    if (files.some((f) => !IMG_OK.test(f.type))) { toast('Chỉ nhận ảnh JPG, PNG, GIF hoặc WebP', 'bad'); return; }
                    await api.uploadImages(productId, files);
                    toast('Đã thêm ảnh');
                } else if (act === 'mainImg') {
                    await api.setMainImage(Number(btn.closest('.vm-img').dataset.iid));
                    toast('Đã đặt ảnh đại diện');
                } else if (act === 'replaceImg') {
                    // Mở hộp chọn file; chọn xong thì onchange bên dưới sẽ tải lên và thay ảnh này
                    body.dataset.replaceId = btn.closest('.vm-img').dataset.iid;
                    body.querySelector('[data-replace]').click();
                    return;
                } else if (act === 'delImg') {
                    if (imgs.length <= 1) { toast('Sản phẩm phải có ít nhất 1 ảnh. Hãy dùng "Thay ảnh" nếu muốn đổi ảnh.', 'bad'); return; }
                    if (!confirm('Xóa ảnh này?')) return;
                    await api.remove('images', Number(btn.closest('.vm-img').dataset.iid));
                    toast('Đã xóa ảnh');
                }
                await refresh();
            } catch (err) { toast(err.message, 'bad'); }
        };

        // Sửa trực tiếp trong hàng (số lượng / tên size / tên màu / mã màu): rời ô là tự lưu.
        // Lỗi thì vẽ lại để trả giá trị cũ.
        body.onchange = async (e) => {
            const t = e.target;
            try {
                if (t.matches('[data-qty]')) {
                    const vid = Number(t.closest('.vm-row').dataset.vid);
                    const d = detailsOf(productId).find((x) => x.id === vid);
                    if (!d) return;
                    if (await saveDetail(vid, d.sizeId, d.colorId, t.value.trim())) toast('Đã cập nhật số lượng');
                } else if (t.matches('[data-replace]')) {
                    // Thay nội dung ảnh đã chọn ở nút "Thay ảnh"
                    const file = t.files[0], iid = Number(body.dataset.replaceId);
                    if (!file || !iid) return;
                    if (!IMG_OK.test(file.type)) { toast('Chỉ nhận ảnh JPG, PNG, GIF hoặc WebP', 'bad'); t.value = ''; return; }
                    await api.replaceImage(iid, file);
                    toast('Đã thay ảnh');
                } else if (t.matches('[data-sname]')) {
                    const s = sizeById(Number(t.closest('.vm-row').dataset.sid));
                    if (!s) return;
                    await api.save('sizes', { ...s, name: t.value.trim() });
                    toast('Đã cập nhật size');
                } else if (t.matches('[data-cname], [data-chex]')) {
                    const row = t.closest('.vm-row');
                    const c = colorById(Number(row.dataset.cid));
                    if (!c) return;
                    const pick = row.querySelector('[data-chex]');
                    if (t.matches('[data-chex]')) pick.dataset.set = '1'; // người dùng đã chọn mã màu
                    await api.save('colors', { ...c, name: row.querySelector('[data-cname]').value.trim(), hexCode: pick.dataset.set === '1' ? pick.value.toUpperCase() : null });
                    toast('Đã cập nhật màu');
                } else return;
                await refresh();
            } catch (err) { toast(err.message, 'bad'); await refresh(); }
        };

        // Chọn mã màu ở form thêm màu = đánh dấu "có mã màu" (nếu không chọn thì lưu không có mã)
        body.oninput = (e) => { if (e.target.matches('[data-f=colorHex]')) e.target.dataset.set = '1'; };

        // Nhấn Enter trong form thêm = bấm nút Thêm của form đó
        body.onkeydown = (e) => {
            const box = e.target.closest('.vm-add');
            if (e.key === 'Enter' && box) {
                e.preventDefault();
                box.querySelector('[data-vact]').click();
            }
        };
    }

    /* =================================================================
     * [9] MÀN HÌNH DANH MỤC
     *   renderCategories() / renderCategoryList() / categoryForm() / categoryDetail()
     * ================================================================= */

    // Đếm số sản phẩm thuộc một danh mục
    const countIn = (cid) => data.products.filter((p) => p.categoryId === cid).length;

    // Khung trang danh mục (thanh tìm kiếm); bảng vẽ ở renderCategoryList()
    function renderCategories() {
        const f = state.categories;
        $('#content').innerHTML = `
      <div class="card">
        <div class="toolbar">
          <div class="search">${ICON.search}<input id="cQ" placeholder="Tìm danh mục..." value="${esc(f.q)}"></div>
          <button class="btn" id="cReset">Xóa lọc</button>
        </div>
        <div id="list"></div>
      </div>`;
        $('#cQ').oninput = (e) => { f.q = e.target.value; f.page = 1; renderCategoryList(); };
        $('#cReset').onclick = () => { f.q = ''; f.page = 1; renderCategories(); };
        renderCategoryList();
    }

    // Vẽ bảng danh mục + phân trang vào #list
    function renderCategoryList() {
        const f = state.categories;
        const list = data.categories.filter((c) => !f.q || norm(c.name).includes(norm(f.q)) || norm(c.description).includes(norm(f.q)));
        const p = paginate(list, f.page);
        f.page = p.cur;
        $('#list').innerHTML = p.total === 0
            ? emptyHtml('Không tìm thấy danh mục.')
            : `<div class="table-wrap"><table>
          <thead><tr><th>Danh mục</th><th>Mô tả</th><th class="num">Số sản phẩm</th><th class="num">Thao tác</th></tr></thead>
          <tbody>${p.rows.map((c) => `<tr>
            <td><div class="prod"><div class="thumb">${esc(c.icon || '📁')}</div><div class="prod-name">${esc(c.name)}</div></div></td>
            <td style="color:var(--muted)">${esc(c.description)}</td>
            <td class="num"><span class="chip">${countIn(c.id)}</span></td>
            <td>${actionBtns(c.id)}</td></tr>`).join('')}</tbody></table></div>${pagerHtml(p)}`;
    }

    // Form thêm / sửa danh mục
    function categoryForm(c = {}) {
        const isEdit = !!c.id;
        openModal({
            title: isEdit ? 'Sửa danh mục' : 'Thêm danh mục',
            body: `<form id="cf" class="form-grid" novalidate>
        <div class="field full"><label>Tên danh mục <em>*</em></label><input class="input" name="name" value="${esc(c.name)}"><span class="err" data-err="name"></span></div>
        <div class="field"><label>Biểu tượng (emoji)</label><input class="input" name="icon" value="${esc(c.icon || '📁')}" maxlength="4"></div>
        <div class="field full"><label>Mô tả</label><textarea name="description">${esc(c.description)}</textarea></div>
      </form>`,
            foot: `<button class="btn" data-close>Hủy</button><button class="btn btn-primary" id="saveBtn">${isEdit ? 'Lưu thay đổi' : 'Thêm danh mục'}</button>`,
        });
        $('#saveBtn').onclick = async () => {
            const fd = Object.fromEntries(new FormData($('#cf')));
            if (!fd.name.trim()) { $('[data-err=name]').textContent = 'Vui lòng nhập tên danh mục'; return; }
            try {
                await api.save('categories', { ...c, name: fd.name.trim(), icon: fd.icon || '📁', description: fd.description.trim() });
                await reload(); closeModal(); render();
                toast(isEdit ? 'Đã cập nhật danh mục' : 'Đã thêm danh mục mới');
            } catch (e) { toast(e.message, 'bad'); }
        };
    }

    // Ngăn kéo xem chi tiết danh mục + danh sách sản phẩm bên trong
    function categoryDetail(id) {
        const c = data.categories.find((x) => x.id === id);
        if (!c) return;
        const items = data.products.filter((p) => p.categoryId === id);
        openDrawer({
            title: 'Chi tiết danh mục',
            body: `
        <div class="detail-hero" style="height:120px;font-size:56px">${esc(c.icon || '📁')}</div>
        <div class="detail-title">${esc(c.name)}</div>
        <p class="detail-desc" style="border:0;padding-top:4px">${esc(c.description) || '<i>Chưa có mô tả.</i>'}</p>
        <h4 style="margin:18px 0 6px">Sản phẩm trong danh mục (${items.length})</h4>
        ${items.length ? `<table class="items"><tbody>${items.map((p) => `<tr><td>${esc(p.icon || '📦')} ${esc(p.name)}</td><td class="num price">${money(p.price)}</td></tr>`).join('')}</tbody></table>` : '<div style="color:var(--muted)">Chưa có sản phẩm nào.</div>'}`,
            foot: `<button class="btn" data-close>Đóng</button><button class="btn btn-primary" id="dEdit">Sửa danh mục</button>`,
        });
        $('#dEdit').onclick = () => { closeDrawer(); categoryForm(c); };
    }

    /* =================================================================
     * [10] MÀN HÌNH ĐƠN HÀNG
     *   renderOrders() / renderOrderList() / orderDetail() / orderForm()
     *   (không có nút "Thêm": đơn hàng do khách đặt, admin chỉ xem / cập nhật / xóa)
     * ================================================================= */

    // Khung trang đơn hàng: 4 ô thống kê + thanh lọc
    function renderOrders() {
        const f = state.orders;
        const all = data.orders;
        const stats = [
            ['c1', ICON.cart, all.length, 'Tổng đơn hàng'],
            ['c3', ICON.alert, all.filter((o) => o.status === 'pending').length, 'Chờ xác nhận'],
            ['c1', ICON.check, all.filter((o) => o.status === 'confirmed').length, 'Đã xác nhận'],
            ['c1', ICON.shipping, all.filter((o) => o.status === 'shipping').length, 'Đang giao'],
            ['c2', ICON.done, all.filter((o) => o.status === 'done').length, 'Hoàn thành'],
            ['c4', ICON.cancel, all.filter((o) => o.status === 'cancelled').length, 'Đã hủy'],
            ['c1', ICON.money, money(all.filter((o) => o.status === 'done').reduce((s, o) => s + orderTotal(o), 0)), 'Doanh thu đã hoàn thành'],
        ];
        $('#content').innerHTML = `
      <div class="stats">${stats.map(([c, i, n, l]) => `<div class="stat"><div class="stat-ico ${c}">${i}</div><div><div class="stat-num" ${String(n).length > 9 ? 'style="font-size:17px"' : ''}>${n}</div><div class="stat-lbl">${l}</div></div></div>`).join('')}</div>
      <div class="card">
        <div class="toolbar">
          <div class="search">${ICON.search}<input id="oQ" placeholder="Tìm mã đơn, tên khách, SĐT..." value="${esc(f.q)}"></div>
          <select class="select" id="oStatus"><option value="">Mọi trạng thái</option>${Object.entries(ORDER_STATUS).filter(([k]) => k !== 'other').map(([k, v]) => `<option value="${k}" ${k === f.status ? 'selected' : ''}>${v[0]}</option>`).join('')}</select>
          <button class="btn" id="oReset">Xóa lọc</button>
        </div>
        <div id="list"></div>
      </div>`;
        $('#oQ').oninput = (e) => { f.q = e.target.value; f.page = 1; renderOrderList(); };
        $('#oStatus').onchange = (e) => { f.status = e.target.value; f.page = 1; renderOrderList(); };
        $('#oReset').onclick = () => { Object.assign(f, { q: '', status: '', page: 1 }); renderOrders(); };
        renderOrderList();
    }

    // Vẽ bảng đơn hàng (mới nhất lên đầu) + phân trang vào #list
    function renderOrderList() {
        const f = state.orders;
        const q = norm(f.q);
        const list = data.orders
            .filter((o) => (!f.status || o.status === f.status) && (!q || norm(o.code).includes(q) || norm(o.customer).includes(q) || norm(o.phone).includes(q)))
            .sort((a, b) => (new Date(b.date) || 0) - (new Date(a.date) || 0));
        const p = paginate(list, f.page);
        f.page = p.cur;
        $('#list').innerHTML = p.total === 0
            ? emptyHtml('Không tìm thấy đơn hàng.')
            : `<div class="table-wrap"><table>
          <thead><tr><th>Mã đơn</th><th>Khách hàng</th><th>Ngày đặt</th><th class="num">Tổng tiền</th><th>Trạng thái</th><th class="num">Thao tác</th></tr></thead>
          <tbody>${p.rows.map((o) => `<tr>
            <td class="prod-name">${esc(o.code)}</td>
            <td><div class="prod-name">${esc(o.customer)}</div><div class="prod-sku">${esc(o.phone)}</div></td>
            <td>${fmtDate(o.date)}</td>
            <td class="num price">${money(orderTotal(o))}</td>
            <td>${orderTag(o)}</td>
            <td>${actionBtns(o.id)}</td></tr>`).join('')}</tbody></table></div>${pagerHtml(p)}`;
    }

    // Ngăn kéo xem chi tiết đơn: thông tin khách + từng sản phẩm + tổng cộng
    async function orderDetail(id) {
        const o = data.orders.find((x) => x.id === id); if (!o) return;
        // Lấy chi tiết sản phẩm của đơn hàng
        const res = await fetch(`/api/order-details/order/${id}`); if (!res.ok) { alert('Không thể lấy chi tiết đơn hàng'); return; } const result = await res.json();
        const items = result.data; openDrawer({ title: 'Đơn ' + o.code, body: ` <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px"> <div class="detail-title" style="margin:0"> ${esc(o.customer)} </div> ${orderTag(o)} </div> <dl class="kv"> <dt>Số điện thoại</dt> <dd>${esc(o.phone)}</dd> <dt>Địa chỉ</dt> <dd>${esc(o.address)}</dd> <dt>Ngày đặt</dt> <dd>${fmtDateTime(o.date)}</dd> <dt>Thanh toán</dt> <dd>${esc(o.payment)}</dd> </dl> <h4 style="margin:6px 0">Sản phẩm</h4> <table class="items"> <tbody> ${items.map((it) => ` <tr> <td> ${it.imageUrl ? `<img src="${esc(it.imageUrl)}" style="width:40px;height:40px;object-fit:cover;border-radius:6px;vertical-align:middle;margin-right:6px">` : '📦' } ${esc(it.productName)} <span style="color:var(--muted)"> × ${it.quantity} </span> <div style="font-size:12px;color:var(--muted)"> Size: ${it.size} | Màu: ${esc(it.color)} </div> </td> <td class="num price"> ${money(it.price * it.quantity)} </td> </tr> `).join('')} <tr> <td style="font-weight:700;border-top:1px solid var(--line)"> Tổng cộng </td> <td class="num price" style="color:var(--brand);font-size:16px;border-top:1px solid var(--line)" > ${money(o.totalAmount)} </td> </tr> </tbody> </table> `, foot: ` <button class="btn" data-close> Đóng </button> <button class="btn btn-primary" id="dEdit"> Cập nhật trạng thái </button> `, }); $('#dEdit').onclick = () => { closeDrawer(); orderForm(o); };
    }

    // Form cập nhật đơn hàng (trạng thái + thông tin giao hàng)
    function orderForm(o) {
        openModal({
            title: 'Cập nhật đơn ' + o.code,
            body: `<form id="of" class="form-grid">
        <div class="field full"><label>Trạng thái đơn hàng</label><select class="select" name="status">${o.status === 'other' ? `<option value="other" selected>${esc(o.statusRaw)} (giữ nguyên)</option>` : ''}${Object.entries(ORDER_STATUS).filter(([k]) => k !== 'other').map(([k, v]) => `<option value="${k}" ${k === o.status ? 'selected' : ''}>${v[0]}</option>`).join('')}</select></div>
        <div class="field full"><label>Tên khách hàng</label><input class="input" name="customer" value="${esc(o.customer)}" readonly></div>
        <div class="field"><label>Số điện thoại</label><input class="input" name="phone" value="${esc(o.phone)}" readonly></div>
        <div class="field"><label>Thanh toán</label><input class="input" name="payment" value="${esc(o.payment)}" readonly></div>
        <div class="field full"><label>Địa chỉ giao hàng</label><input class="input" name="address" value="${esc(o.address)}" readonly></div>
      </form>`,
            foot: `<button class="btn" data-close>Hủy</button><button class="btn btn-primary" id="saveBtn">Lưu thay đổi</button>`,
        });
        $('#saveBtn').onclick = async () => {
            const fd = Object.fromEntries(new FormData($('#of')));
            try {
                await api.save('orders', { ...o, ...fd });
                await reload(); closeModal(); render();
                toast('Đã cập nhật đơn hàng');
            } catch (e) { toast(e.message, 'bad'); }
        };
    }

    /* =================================================================
     * [11] MÀN HÌNH TÀI KHOẢN (bảng tài khoản: Username / FullName / IsActive)
     *   renderAccounts() / renderAccountList() / accountForm() / accountDetail() / toggleAccount()
     *   - Khóa / mở khóa = đổi IsActive, không xóa dữ liệu.
     *   - Mật khẩu không bao giờ được tải về hay hiển thị; chỉ gửi lên khi thêm mới
     *     hoặc khi admin nhập mật khẩu mới ở form sửa (backend sẽ mã hóa).
     * ================================================================= */

    const ACCOUNT_STATUS = { active: ['Hoạt động', 'ok'], locked: ['Đã khóa', 'bad'] };
    const accStatus = (a) => (a.active ? 'active' : 'locked');
    const accById = (id) => data.accounts.find((a) => a.id === id);
    const accName = (a) => a.fullName || a.username;
    const accInitial = (a) => String(accName(a)).trim().charAt(0).toUpperCase() || '?'; // chữ cái đầu làm ảnh đại diện

    // Áp bộ lọc hiện tại lên danh sách tài khoản (mới nhất lên đầu)
    function filteredAccounts() {
        const f = state.accounts;
        const q = norm(f.q);
        return data.accounts
            .filter((a) => (!q || norm(a.username).includes(q) || norm(a.fullName).includes(q)) && (!f.status || accStatus(a) === f.status))
            .sort((a, b) => b.id - a.id);
    }

    // Khung trang tài khoản: 3 ô thống kê + thanh lọc
    function renderAccounts() {
        const f = state.accounts;
        const all = data.accounts;
        const stats = [
            ['c1', ICON.box, all.length, 'Tổng tài khoản'],
            ['c2', ICON.check, all.filter((a) => a.active).length, 'Đang hoạt động'],
            ['c4', ICON.alert, all.filter((a) => !a.active).length, 'Đã khóa'],
        ];
        $('#content').innerHTML = `
      <div class="stats">${stats.map(([c, i, n, l]) => `<div class="stat"><div class="stat-ico ${c}">${i}</div><div><div class="stat-num">${n}</div><div class="stat-lbl">${l}</div></div></div>`).join('')}</div>
      <div class="card">
        <div class="toolbar">
          <div class="search">${ICON.search}<input id="aQ" placeholder="Tìm theo tên đăng nhập hoặc họ tên..." value="${esc(f.q)}"></div>
          <select class="select" id="aStatus"><option value="">Mọi trạng thái</option>${Object.entries(ACCOUNT_STATUS).map(([k, v]) => `<option value="${k}" ${k === f.status ? 'selected' : ''}>${v[0]}</option>`).join('')}</select>
          <button class="btn" id="aReset">Xóa lọc</button>
        </div>
        <div id="list"></div>
      </div>`;
        $('#aQ').oninput = (e) => { f.q = e.target.value; f.page = 1; renderAccountList(); };
        $('#aStatus').onchange = (e) => { f.status = e.target.value; f.page = 1; renderAccountList(); };
        $('#aReset').onclick = () => { Object.assign(f, { q: '', status: '', page: 1 }); renderAccounts(); };
        renderAccountList();
    }

    // Vẽ bảng tài khoản + phân trang vào #list (chỉ 3 cột nên không bị cuộn ngang)
    function renderAccountList() {
        const p = paginate(filteredAccounts(), state.accounts.page);
        state.accounts.page = p.cur;
        const rows = p.rows.map((a) => `
      <tr>
        <td><div class="prod"><div class="thumb">${esc(accInitial(a))}</div>
          <div><div class="prod-name">${esc(a.username)}</div><div class="prod-sku">${esc(a.fullName || '—')}</div></div></div></td>
        <td>${tag(ACCOUNT_STATUS, accStatus(a))}</td>
        <td>${actionBtns(a.id, `<button class="icon-btn ${a.active ? 'del' : 'edit'}" data-act="toggle" data-id="${a.id}" title="${a.active ? 'Khóa tài khoản' : 'Mở khóa tài khoản'}">${a.active ? ICON.lock : ICON.unlock}</button>`)}</td>
      </tr>`).join('');
        $('#list').innerHTML = p.total === 0
            ? emptyHtml('Không tìm thấy tài khoản.')
            : `<div class="table-wrap"><table>
          <thead><tr><th>Tài khoản</th><th>Trạng thái</th><th class="num">Thao tác</th></tr></thead>
          <tbody>${rows}</tbody></table></div>${pagerHtml(p)}`;
    }

    // Form thêm (không truyền a) hoặc sửa (truyền tài khoản) trong modal
    function accountForm(a = {}) {
        const isEdit = !!a.id;
        openModal({
            title: isEdit ? 'Sửa tài khoản' : 'Thêm tài khoản',
            body: `<form id="af" class="form-grid" novalidate autocomplete="off">
        <div class="field full"><label>Tên đăng nhập ${isEdit ? '' : '<em>*</em>'}</label><input class="input" name="username" value="${esc(a.username)}" maxlength="50" placeholder="VD: nguyenvana" ${isEdit ? 'readonly title="Không đổi được tên đăng nhập"' : ''}><span class="err" data-err="username"></span></div>
        <div class="field full"><label>Họ tên</label><input class="input" name="fullName" value="${esc(a.fullName)}" maxlength="100"></div>
        <div class="field full"><label>${isEdit ? 'Mật khẩu mới (bỏ trống nếu không đổi)' : 'Mật khẩu <em>*</em>'}</label><input class="input" type="password" name="password" autocomplete="new-password" placeholder="Tối thiểu 6 ký tự"><span class="err" data-err="password"></span></div>
        <div class="field full"><label>Trạng thái</label><select class="select" name="active">
          <option value="true" ${a.active !== false ? 'selected' : ''}>Hoạt động</option>
          <option value="false" ${a.active === false ? 'selected' : ''}>Đã khóa</option>
        </select></div>
      </form>`,
            foot: `<button class="btn" data-close>Hủy</button><button class="btn btn-primary" id="saveBtn">${isEdit ? 'Lưu thay đổi' : 'Thêm tài khoản'}</button>`,
        });
        $('#saveBtn').onclick = async () => {
            const fd = Object.fromEntries(new FormData($('#af')));
            $$('[data-err]').forEach((e) => (e.textContent = ''));
            const username = (fd.username || '').trim();
            const password = fd.password || '';
            let bad = false;
            if (!isEdit && !/^[A-Za-z0-9._@-]{3,50}$/.test(username)) { $('[data-err=username]').textContent = 'Từ 3–50 ký tự: chữ không dấu, số, . _ @ -'; bad = true; }
            if ((!isEdit || password) && password.length < 6) { $('[data-err=password]').textContent = 'Mật khẩu tối thiểu 6 ký tự'; bad = true; }
            if (bad) return;
            const item = { ...a, username, fullName: (fd.fullName || '').trim(), active: fd.active === 'true' };
            if (password) item.password = password; // chỉ gửi mật khẩu khi có nhập
            const btn = $('#saveBtn');
            btn.disabled = true; // chống bấm lưu 2 lần
            try {
                await api.save('accounts', item);
                await reload(); closeModal(); render();
                toast(isEdit ? 'Đã cập nhật tài khoản' : 'Đã thêm tài khoản mới');
            } catch (e) { btn.disabled = false; toast(e.message, 'bad'); }
        };
    }

    // Ngăn kéo xem chi tiết tài khoản
    function accountDetail(id) {
        const a = accById(id);
        if (!a) return;
        openDrawer({
            title: 'Chi tiết tài khoản',
            body: `
        <div class="detail-hero" style="height:120px;font-size:56px">${esc(accInitial(a))}</div>
        <div class="detail-title">${esc(accName(a))}</div>
        <div>${tag(ACCOUNT_STATUS, accStatus(a))}</div>
        <dl class="kv" style="margin-top:14px">
          <dt>Tên đăng nhập</dt><dd>${esc(a.username)}</dd>
          <dt>Họ tên</dt><dd>${esc(a.fullName) || '—'}</dd>
          <dt>Mật khẩu</dt><dd>•••••• (được mã hóa, không xem được)</dd>
        </dl>`,
            foot: `<button class="btn" data-close>Đóng</button><button class="btn" id="dToggle">${a.active ? 'Khóa tài khoản' : 'Mở khóa'}</button><button class="btn btn-primary" id="dEdit">Sửa tài khoản</button>`,
        });
        $('#dToggle').onclick = () => { closeDrawer(); toggleAccount(id); };
        $('#dEdit').onclick = () => { closeDrawer(); accountForm(a); };
    }

    // Khóa / mở khóa: đổi IsActive (khóa thì hỏi lại để tránh bấm nhầm)
    async function toggleAccount(id) {
        const a = accById(id);
        if (!a) return;
        if (a.active && !confirm(`Khóa tài khoản "${a.username}"? Người này sẽ không đăng nhập được nữa.`)) return;
        try {
            await api.save('accounts', { ...a, active: !a.active });
            await reload(); render();
            toast(a.active ? 'Đã khóa tài khoản' : 'Đã mở khóa tài khoản');
        } catch (e) { toast(e.message, 'bad'); }
    }

    /* =================================================================
     * [12] ĐIỀU HƯỚNG + SỰ KIỆN CHUNG + KHỞI ĐỘNG
     * ================================================================= */

    /* ---------- Bảng các màn hình ----------
     * Mỗi màn hình khai báo: tiêu đề, nhãn nút "Thêm", hàm vẽ và các hành động
     * form / view / edit / del. Muốn thêm một màn hình mới, thêm một mục vào đây
     * (và thêm state, link menu tương ứng). */
    const ROUTES = {
        products: {
            title: 'Quản lý sản phẩm', crumb: 'Sản phẩm', add: 'Thêm sản phẩm',
            render: renderProducts,
            form: () => productForm(),
            view: productDetail,
            variants: (id) => variantManager(id, 'variants'), // nút "Biến thể" ở mỗi dòng sản phẩm
            edit: (id) => productForm(prodById(id)),
            del: (id) => {
                const p = prodById(id);
                confirmDelete(`Bạn có chắc muốn xóa sản phẩm <b>${esc(p.name)}</b>?`, async () => { await api.remove('products', id); await reload(); render(); toast('Đã xóa sản phẩm'); });
            },
        },
        categories: {
            title: 'Quản lý danh mục', crumb: 'Danh mục', add: 'Thêm danh mục',
            render: renderCategories,
            form: () => categoryForm(),
            view: categoryDetail,
            edit: (id) => categoryForm(data.categories.find((c) => c.id === id)),
            del: (id) => {
                const c = data.categories.find((x) => x.id === id);
                const n = countIn(id);
                // Không cho xóa danh mục còn sản phẩm
                if (n > 0) return toast(`Danh mục "${c.name}" còn ${n} sản phẩm, hãy chuyển hoặc xóa sản phẩm trước.`, 'bad');
                confirmDelete(`Bạn có chắc muốn xóa danh mục <b>${esc(c.name)}</b>?`, async () => { await api.remove('categories', id); await reload(); render(); toast('Đã xóa danh mục'); });
            },
        },
        accounts: {
            title: 'Quản lý tài khoản', crumb: 'Tài khoản', add: 'Thêm tài khoản',
            render: renderAccounts,
            form: () => accountForm(),
            view: accountDetail,
            edit: (id) => accountForm(accById(id)),
            toggle: toggleAccount, // nút khóa / mở khóa ở mỗi dòng
            del: (id) => {
                const a = accById(id);
                confirmDelete(`Bạn có chắc muốn xóa tài khoản <b>${esc(a.username)}</b>? Nếu chỉ muốn ngăn đăng nhập, hãy dùng "Khóa tài khoản" thay vì xóa.`, async () => { await api.remove('accounts', id); await reload(); render(); toast('Đã xóa tài khoản'); });
            },
        },
        orders: {
            title: 'Quản lý đơn hàng', crumb: 'Đơn hàng', add: null, // add: null = ẩn nút "Thêm"
            render: renderOrders,
            view: orderDetail,
            edit: (id) => orderForm(data.orders.find((o) => o.id === id)),
            del: (id) => {
                const o = data.orders.find((x) => x.id === id);
                confirmDelete(`Bạn có chắc muốn xóa đơn <b>${esc(o.code)}</b> của ${esc(o.customer)}?`, async () => { await api.remove('orders', id); await reload(); render(); toast('Đã xóa đơn hàng'); });
            },
        },
    };

    // Vẽ lại màn hình hiện tại: cập nhật tiêu đề, breadcrumb, nút Thêm, menu đang chọn rồi gọi hàm vẽ nội dung
    function render() {
        const r = ROUTES[state.route];
        $('#pageTitle').textContent = r.title;
        $('#pageCrumb').textContent = 'Trang chủ / ' + r.crumb;
        $('#addBtn').hidden = !r.add;
        if (r.add) $('#addBtnText').textContent = r.add;
        $$('.menu-item').forEach((a) => a.classList.toggle('active', a.dataset.route === state.route));
        r.render();
    }

    // Đọc đường dẫn (#/products, #/categories, #/orders) để biết đang ở màn hình nào; sai thì về sản phẩm
    function route() {
        const name = (location.hash.replace('#/', '') || 'products').split('?')[0];
        state.route = ROUTES[name] ? name : 'products';
        closeSidebar();
        render();
    }

    // Đóng menu bên trái (chế độ điện thoại)
    const closeSidebar = () => { $('#sidebar').classList.remove('open'); $('#backdrop').classList.remove('show'); };

    /* ---------- Bắt click toàn trang (event delegation) ----------
     * Chỉ một listener duy nhất xử lý: đóng modal/drawer, đổi trang,
     * và nút Xem / Sửa / Xóa ở mọi bảng (dựa vào data-act, data-id). */
    document.addEventListener('click', (e) => {
        const t = e.target;

        // Đóng modal: bấm nút [data-close] hoặc bấm nền tối bên ngoài
        if (t.closest('[data-close]') || t.id === 'modal') closeModal();
        // Đóng drawer: bấm nút [data-close] nằm trong drawer hoặc bấm nền tối bên ngoài
        if ((t.closest('[data-close]') && t.closest('#drawer')) || t.id === 'drawer') closeDrawer();

        // Chuyển trang ở bảng
        const pg = t.closest('[data-page]');
        if (pg && !pg.disabled) {
            state[state.route].page = Number(pg.dataset.page);
            ({ products: renderProductList, categories: renderCategoryList, orders: renderOrderList, accounts: renderAccountList })[state.route]();
        }

        // Nút Xem / Sửa / Xóa: id số thì đổi sang số, id chuỗi (UUID...) giữ nguyên
        const act = t.closest('[data-act]');
        if (act) {
            const r = ROUTES[state.route];
            const rawId = act.dataset.id;
            const id = /^\d+$/.test(rawId) ? Number(rawId) : rawId;
            if (act.dataset.act === 'view') r.view(id);
            if (act.dataset.act === 'edit') r.edit(id);
            if (act.dataset.act === 'del') r.del(id);
            if (act.dataset.act === 'variants' && r.variants) r.variants(id);
            if (act.dataset.act === 'toggle' && r.toggle) r.toggle(id);
        }
    });

    // Phím Esc đóng modal và drawer
    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') { closeModal(); closeDrawer(); }
    });

    // Nút "Thêm ..." trên thanh tiêu đề, nút mở menu (điện thoại), nền tối của menu, đổi đường dẫn
    $('#addBtn').onclick = () => ROUTES[state.route].form && ROUTES[state.route].form();
    $('#menuToggle').onclick = () => { $('#sidebar').classList.add('open'); $('#backdrop').classList.add('show'); };
    $('#backdrop').onclick = closeSidebar;
    window.addEventListener('hashchange', route);

    /* ---------- KHỞI ĐỘNG: tải dữ liệu rồi hiển thị màn hình; lỗi thì báo rõ lý do ---------- */
    reload().then(route).catch((e) => {
        $('#content').innerHTML = emptyHtml('Không tải được dữ liệu (' + esc(e.message) + '). Kiểm tra backend đang chạy và đường dẫn ' + esc(ENDPOINTS.products) + ' trả về JSON.');
    });
})();