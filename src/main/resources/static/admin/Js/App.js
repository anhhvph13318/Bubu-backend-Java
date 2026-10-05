/* =========================================================
 * Bubu Admin - vanilla JS, không cần build, không cần thư viện
 * Đặt tại: src/main/resources/static/admin/js/app.js
 *
 * Sản phẩm lấy từ API thật (MOCK.products = false);
 * danh mục và đơn hàng vẫn là dữ liệu mẫu cho tới khi có API.
 * Chỉnh ENDPOINTS và ALIASES cho khớp controller / JSON của bạn.
 * ========================================================= */
(() => {
    'use strict';

    // true = dùng dữ liệu mẫu, false = gọi API thật (đặt riêng cho từng loại)
    const MOCK = { products: false, categories: true, orders: false };
    const ENDPOINTS = {
        products: '/api/products',
        categories: '/api/categories',
        orders: '/api/orders',
    };
    const PAGE_SIZE = 8;

    /* ---------- Tiện ích ---------- */
    const $ = (s, r = document) => r.querySelector(s);
    const $$ = (s, r = document) => [...r.querySelectorAll(s)];
    const esc = (v) => String(v ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
    const money = (n) => new Intl.NumberFormat('vi-VN').format(Number(n) || 0) + ' ₫';
    const validDate = (iso) => { const d = new Date(iso); return iso && !isNaN(d) ? d : null; };
    const fmtDate = (iso) => { const d = validDate(iso); return d ? d.toLocaleDateString('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }) : '—'; };
    const fmtDateTime = (iso) => { const d = validDate(iso); return d ? d.toLocaleString('vi-VN') : '—'; };
    const norm = (s) => String(s ?? '').toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/đ/g, 'd');

    const ICON = {
        view: '<svg viewBox="0 0 24 24"><path d="M2 12s3.6-7 10-7 10 7 10 7-3.6 7-10 7S2 12 2 12Z"/><circle cx="12" cy="12" r="3"/></svg>',
        edit: '<svg viewBox="0 0 24 24"><path d="M12 20h9"/><path d="M16.5 3.5a2.1 2.1 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5Z"/></svg>',
        del: '<svg viewBox="0 0 24 24"><path d="M3 6h18"/><path d="M8 6V4a1 1 0 0 1 1-1h6a1 1 0 0 1 1 1v2"/><path d="M19 6l-1 14a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2L5 6"/><path d="M10 11v6M14 11v6"/></svg>',
        search: '<svg viewBox="0 0 24 24"><circle cx="11" cy="11" r="7"/><path d="m21 21-4.3-4.3"/></svg>',
        box: '<svg viewBox="0 0 24 24"><path d="M21 8 12 3 3 8v8l9 5 9-5V8Z"/><path d="m3 8 9 5 9-5M12 13v8"/></svg>',
        check: '<svg viewBox="0 0 24 24"><path d="m5 12 5 5 9-10"/></svg>',
        alert: '<svg viewBox="0 0 24 24"><path d="M12 9v4M12 17h.01"/><path d="M10.3 3.9 1.8 18a2 2 0 0 0 1.7 3h17a2 2 0 0 0 1.7-3L13.7 3.9a2 2 0 0 0-3.4 0Z"/></svg>',
        cart: '<svg viewBox="0 0 24 24"><circle cx="9" cy="20" r="1.5"/><circle cx="18" cy="20" r="1.5"/><path d="M2 3h3l2.7 12.4a2 2 0 0 0 2 1.6h7.7a2 2 0 0 0 2-1.5L21 8H6"/></svg>',
    };

    /* ---------- Dữ liệu mẫu ---------- */
    const db = {
        categories: [
            { id: 1, name: 'Đồ uống', description: 'Cà phê, trà, nước ép và các loại thức uống', icon: '🥤' },
            { id: 2, name: 'Bánh ngọt', description: 'Bánh kem, bánh mì ngọt, cookie', icon: '🍰' },
            { id: 3, name: 'Đồ ăn nhanh', description: 'Burger, sandwich, snack', icon: '🍔' },
            { id: 4, name: 'Quà tặng', description: 'Set quà, hộp quà theo dịp', icon: '🎁' },
            { id: 5, name: 'Phụ kiện', description: 'Ly, bình giữ nhiệt, túi vải', icon: '🧴' },
        ],
        products: [
            { id: 1, name: 'Cà phê sữa đá', sku: 'DU-001', categoryId: 1, price: 29000, stock: 120, status: 'active', icon: '☕', description: 'Cà phê rang xay pha phin truyền thống, kết hợp sữa đặc, uống lạnh với đá.' },
            { id: 2, name: 'Trà đào cam sả', sku: 'DU-002', categoryId: 1, price: 39000, stock: 85, status: 'active', icon: '🍑', description: 'Trà đen ủ lạnh với đào miếng, cam tươi và sả thơm.' },
            { id: 3, name: 'Nước ép cam tươi', sku: 'DU-003', categoryId: 1, price: 35000, stock: 6, status: 'active', icon: '🍊', description: 'Cam vắt nguyên chất, không đường, không chất bảo quản.' },
            { id: 4, name: 'Matcha latte', sku: 'DU-004', categoryId: 1, price: 45000, stock: 40, status: 'active', icon: '🍵', description: 'Bột matcha Nhật Bản đánh cùng sữa tươi.' },
            { id: 5, name: 'Bánh tiramisu', sku: 'BN-001', categoryId: 2, price: 55000, stock: 24, status: 'active', icon: '🍰', description: 'Tiramisu vị cà phê, phủ bột cacao, làm mới mỗi ngày.' },
            { id: 6, name: 'Cookie socola chip', sku: 'BN-002', categoryId: 2, price: 25000, stock: 0, status: 'out', icon: '🍪', description: 'Cookie giòn ngoài mềm trong với socola đen.' },
            { id: 7, name: 'Croissant bơ', sku: 'BN-003', categoryId: 2, price: 32000, stock: 33, status: 'active', icon: '🥐', description: 'Bánh sừng bò nhiều lớp, vị bơ Pháp.' },
            { id: 8, name: 'Burger gà giòn', sku: 'AN-001', categoryId: 3, price: 59000, stock: 18, status: 'active', icon: '🍔', description: 'Gà chiên giòn, xà lách, sốt mayonnaise đặc biệt.' },
            { id: 9, name: 'Sandwich trứng', sku: 'AN-002', categoryId: 3, price: 38000, stock: 52, status: 'active', icon: '🥪', description: 'Bánh mì sandwich nướng, trứng ốp la, phô mai.' },
            { id: 10, name: 'Khoai tây chiên', sku: 'AN-003', categoryId: 3, price: 29000, stock: 70, status: 'hidden', icon: '🍟', description: 'Khoai tây cắt sợi chiên vàng, kèm sốt cà.' },
            { id: 11, name: 'Hộp quà Bubu', sku: 'QT-001', categoryId: 4, price: 199000, stock: 12, status: 'active', icon: '🎁', description: 'Set quà gồm 2 bánh, 1 ly giữ nhiệt và thiệp viết tay.' },
            { id: 12, name: 'Ly giữ nhiệt 500ml', sku: 'PK-001', categoryId: 5, price: 149000, stock: 4, status: 'active', icon: '🧴', description: 'Inox 304, giữ lạnh 12 giờ, giữ nóng 6 giờ.' },
            { id: 13, name: 'Túi vải canvas', sku: 'PK-002', categoryId: 5, price: 69000, stock: 60, status: 'active', icon: '👜', description: 'Túi tote vải canvas in logo Bubu.' },
        ],
        orders: [
            { id: 1, code: 'DH-10241', customer: 'Nguyễn Văn An', phone: '0912 345 678', address: '12 Lê Lợi, TP. Bắc Giang', date: '2026-10-05T09:12:00', status: 'pending', payment: 'COD', items: [{ productId: 1, qty: 2 }, { productId: 5, qty: 1 }] },
            { id: 2, code: 'DH-10240', customer: 'Trần Thị Bích', phone: '0987 654 321', address: '88 Hùng Vương, Hà Nội', date: '2026-10-05T08:40:00', status: 'shipping', payment: 'Chuyển khoản', items: [{ productId: 11, qty: 1 }] },
            { id: 3, code: 'DH-10239', customer: 'Lê Minh Quân', phone: '0903 111 222', address: '5 Trần Phú, Hải Phòng', date: '2026-10-04T18:05:00', status: 'done', payment: 'Ví điện tử', items: [{ productId: 2, qty: 3 }, { productId: 7, qty: 2 }] },
            { id: 4, code: 'DH-10238', customer: 'Phạm Thu Hà', phone: '0977 888 999', address: '31 Nguyễn Huệ, Đà Nẵng', date: '2026-10-04T14:30:00', status: 'confirmed', payment: 'COD', items: [{ productId: 8, qty: 2 }, { productId: 10, qty: 2 }] },
            { id: 5, code: 'DH-10237', customer: 'Hoàng Đức Long', phone: '0966 222 333', address: '9 Hai Bà Trưng, TP.HCM', date: '2026-10-03T11:20:00', status: 'cancelled', payment: 'COD', items: [{ productId: 12, qty: 1 }] },
            { id: 6, code: 'DH-10236', customer: 'Vũ Ngọc Mai', phone: '0944 555 666', address: '77 Điện Biên Phủ, Huế', date: '2026-10-03T10:02:00', status: 'done', payment: 'Chuyển khoản', items: [{ productId: 4, qty: 2 }, { productId: 13, qty: 1 }] },
            { id: 7, code: 'DH-10235', customer: 'Đặng Quốc Bảo', phone: '0933 777 000', address: '20 Quang Trung, Cần Thơ', date: '2026-10-02T16:45:00', status: 'pending', payment: 'COD', items: [{ productId: 3, qty: 4 }] },
        ],
        nextId: { products: 14, categories: 6, orders: 8 },
    };

    /* ---------- Lớp truy cập dữ liệu (đổi sang fetch khi có API) ---------- */
    async function http(url, opts = {}) {
        const res = await fetch(url, { headers: { 'Content-Type': 'application/json' }, ...opts });
        if (!res.ok) throw new Error('Lỗi ' + res.status);
        return res.status === 204 ? null : res.json();
    }
    const clone = (o) => JSON.parse(JSON.stringify(o));

    /* ---------- Chuyển đổi dữ liệu API <-> giao diện ----------
     * Tự nhận diện các tên trường thường gặp. Nếu JSON của bạn dùng tên khác,
     * chỉ cần thêm tên đó vào mảng tương ứng bên dưới. */
    const ALIASES = {
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
        item_product: ['product', 'sanPham'],
        item_productId: ['productId', 'sanPhamId', 'idSanPham'],
        item_name: ['productName', 'name', 'tenSanPham', 'ten'],
        item_price: ['price', 'unitPrice', 'donGia', 'gia', 'giaBan'],
        item_qty: ['quantity', 'qty', 'soLuong'],
    };
    const NEST = { name: ['name', 'fullName', 'hoTen', 'tenKhachHang', 'ten'], phone: ['phone', 'phoneNumber', 'sdt', 'soDienThoai'], address: ['address', 'diaChi'] };
    const nestGet = (o, list, d = '') => { const k = list.find((x) => x in o); return k && o[k] != null ? o[k] : d; };
    const pick = (raw, key) => ALIASES[key].find((k) => k in raw) || null;
    const get = (raw, key, d) => { const k = pick(raw, key); return k == null || raw[k] == null ? d : raw[k]; };
    const unwrapList = (res) => (Array.isArray(res) ? res : (res && (res.content || res.data || res.items || res.products || res.result)) || []);

    function fromApiProduct(raw, i) {
        const cat = get(raw, 'category', null);
        let categoryName = '', categoryApiId = null;
        if (cat && typeof cat === 'object') { categoryName = cat.name ?? cat.tenDanhMuc ?? cat.ten ?? ''; categoryApiId = cat.id ?? null; }
        else if (typeof cat === 'number') categoryApiId = cat;
        else if (cat != null) categoryName = String(cat);

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
            categoryName, categoryApiId, _raw: raw,
        };
    }

    let sampleRaw = null; // sản phẩm đầu tiên từ API, dùng làm mẫu cấu trúc cho sản phẩm mới

    function toApiProduct(item) {
        const raw = { ...(item._raw || {}) };
        const ref = item._raw || sampleRaw || {};
        const set = (key, val) => { raw[pick(ref, key) || ALIASES[key][0]] = val; };
        set('name', item.name); set('sku', item.sku); set('price', item.price);
        set('stock', item.stock); set('description', item.description); set('image', item.image);
        if (item.id != null) set('id', item.id);

        const sk = pick(ref, 'status') || 'status';
        const cur = ref[sk];
        raw[sk] = typeof cur === 'boolean' ? item.status === 'active' : typeof cur === 'number' ? (item.status === 'active' ? 1 : 0) : item.status;

        const c = data.categories.find((x) => x.id === item.categoryId);
        if (c) {
            const ck = pick(ref, 'category') || 'category';
            const cv = ref[ck];
            raw[ck] = cv && typeof cv === 'object' ? { ...cv, id: c.id, name: c.name }
                : typeof cv === 'string' || /name/i.test(ck) ? c.name : c.id;
        }
        return raw;
    }

    // Gắn danh mục cho sản phẩm lấy từ API. Nếu danh mục vẫn là dữ liệu mẫu,
    // tạm dựng danh sách danh mục từ chính các sản phẩm để bộ lọc hoạt động đúng.
    function linkCategories(products, categories) {
        if (!MOCK.categories) {
            products.forEach((p) => {
                const c = categories.find((x) => x.id === p.categoryApiId || (p.categoryName && x.name === p.categoryName));
                p.categoryId = c ? c.id : undefined;
            });
            return categories;
        }
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

    /* ---------- Đơn hàng ---------- */
    const ORDER_KEYS = ['pending', 'confirmed', 'shipping', 'done', 'cancelled'];
    const statusSeen = {}; // trạng thái giao diện -> giá trị gốc của backend (học từ dữ liệu tải về)
    let sampleOrder = null;

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
    function statusToRaw(key, cur) {
        if (statusSeen[key] !== undefined) return statusSeen[key];
        if (typeof cur === 'number') return ORDER_KEYS.indexOf(key);
        const guess = { pending: 'PENDING', confirmed: 'CONFIRMED', shipping: 'SHIPPING', done: 'COMPLETED', cancelled: 'CANCELLED' }[key];
        return typeof cur === 'string' && cur === cur.toLowerCase() ? guess.toLowerCase() : guess;
    }
    const toIso = (v) => {
        if (v == null || v === '') return '';
        if (Array.isArray(v)) { const [y, m = 1, d = 1, h = 0, mi = 0, s = 0] = v; return new Date(y, m - 1, d, h, mi, s).toISOString(); }
        const t = new Date(v);
        return isNaN(t) ? '' : t.toISOString();
    };

    function fromApiOrder(raw, i) {
        const id = get(raw, 'order_id', i + 1);
        const cust = get(raw, 'order_customer', '');
        const isObj = cust && typeof cust === 'object';
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
            total: total == null || isNaN(Number(total)) ? null : Number(total),
            items: (Array.isArray(items) ? items : []).map((it) => {
                const p = get(it, 'item_product', null);
                const po = p && typeof p === 'object' ? p : {};
                return {
                    productId: get(it, 'item_productId', po.id ?? (typeof p === 'number' ? p : undefined)),
                    name: get(it, 'item_name', po.name ?? po.tenSanPham),
                    price: Number(get(it, 'item_price', po.price ?? po.giaBan)) || undefined,
                    qty: Number(get(it, 'item_qty', 1)) || 1,
                };
            }),
            _raw: raw,
        };
    }

    function toApiOrder(item) {
        const raw = { ...(item._raw || {}) };
        const ref = item._raw || sampleOrder || {};
        const setIf = (key, val) => { const k = pick(ref, key); if (k) raw[k] = val; };
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

    const api = {
        list: async (name) => {
            if (MOCK[name]) return clone(db[name]);
            const arr = unwrapList(await http(ENDPOINTS[name]));
            if (name === 'orders') {
                if (arr[0]) { sampleOrder = arr[0]; console.info('[Bubu] Mẫu JSON từ ' + ENDPOINTS.orders + ':', arr[0]); }
                return arr.map(fromApiOrder);
            }
            if (name !== 'products') return arr;
            if (arr[0]) { sampleRaw = arr[0]; console.info('[Bubu] Mẫu JSON từ ' + ENDPOINTS.products + ':', arr[0]); }
            return arr.map(fromApiProduct);
        },
        save: async (name, item) => {
            if (!MOCK[name]) {
                const conv = { products: toApiProduct, orders: toApiOrder }[name];
                const body = JSON.stringify(conv ? conv(item) : item);
                return item.id
                    ? http(`${ENDPOINTS[name]}/${item.id}`, { method: 'PUT', body })
                    : http(ENDPOINTS[name], { method: 'POST', body });
            }
            if (item.id) {
                const i = db[name].findIndex((x) => x.id === item.id);
                db[name][i] = { ...db[name][i], ...item };
            } else {
                item.id = db.nextId[name]++;
                db[name].unshift(item);
            }
            return item;
        },
        remove: async (name, id) => {
            if (!MOCK[name]) return http(`${ENDPOINTS[name]}/${id}`, { method: 'DELETE' });
            db[name] = db[name].filter((x) => x.id !== id);
        },
    };

    /* ---------- Trạng thái ---------- */
    const state = {
        route: 'products',
        products: { q: '', cat: '', status: '', sort: 'new', page: 1 },
        categories: { q: '', page: 1 },
        orders: { q: '', status: '', page: 1 },
    };
    let data = { products: [], categories: [], orders: [] };

    const PRODUCT_STATUS = {
        active: ['Đang bán', 'ok'],
        hidden: ['Đang ẩn', 'gray'],
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
    const orderTag = (o) => (o.status === 'other' ? `<span class="tag gray">${esc(o.statusRaw || 'Khác')}</span>` : tag(ORDER_STATUS, o.status));
    const catName = (id) => (data.categories.find((c) => c.id === id) || {}).name || '—';
    const prodById = (id) => data.products.find((p) => p.id === id);
    const itemInfo = (it) => {
        const p = prodById(it.productId) || {};
        return { name: it.name ?? p.name ?? '(không rõ)', price: it.price ?? p.price ?? 0, icon: p.icon };
    };
    const orderTotal = (o) => (o.total != null ? o.total : o.items.reduce((s, it) => s + itemInfo(it).price * it.qty, 0));
    const tag = (map, key) => `<span class="tag ${map[key][1]}">${map[key][0]}</span>`;

    async function reload() {
        const [products, categories, orders] = await Promise.all([api.list('products'), api.list('categories'), api.list('orders')]);
        data = { products, categories, orders };
        if (!MOCK.products) data.categories = linkCategories(products, categories);
        const pending = orders.filter((o) => o.status === 'pending').length;
        const b = $('#pendingBadge');
        b.textContent = pending;
        b.classList.toggle('zero', pending === 0);
    }

    /* ---------- Toast / Modal / Drawer ---------- */
    function toast(msg, type = 'ok') {
        const el = document.createElement('div');
        el.className = 'toast ' + type;
        el.textContent = msg;
        $('#toasts').appendChild(el);
        setTimeout(() => el.remove(), 2800);
    }

    function openModal({ title, body, foot }) {
        $('#modalTitle').textContent = title;
        $('#modalBody').innerHTML = body;
        $('#modalFoot').innerHTML = foot || '';
        $('#modal').hidden = false;
        const first = $('#modalBody input, #modalBody select, #modalBody textarea');
        if (first) first.focus();
    }
    const closeModal = () => ($('#modal').hidden = true);

    function openDrawer({ title, body, foot }) {
        $('#drawerTitle').textContent = title;
        $('#drawerBody').innerHTML = body;
        $('#drawerFoot').innerHTML = foot || '';
        $('#drawer').hidden = false;
    }
    const closeDrawer = () => ($('#drawer').hidden = true);

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

    /* ---------- Danh sách + phân trang ---------- */
    function paginate(list, page) {
        const pages = Math.max(1, Math.ceil(list.length / PAGE_SIZE));
        const cur = Math.min(page, pages);
        return { rows: list.slice((cur - 1) * PAGE_SIZE, cur * PAGE_SIZE), cur, pages, total: list.length };
    }
    function pagerHtml(p) {
        if (p.total === 0) return '';
        const from = (p.cur - 1) * PAGE_SIZE + 1;
        const to = Math.min(p.cur * PAGE_SIZE, p.total);
        let btns = `<button class="pg" data-page="${p.cur - 1}" ${p.cur === 1 ? 'disabled' : ''}>‹</button>`;
        for (let i = 1; i <= p.pages; i++) btns += `<button class="pg ${i === p.cur ? 'on' : ''}" data-page="${i}">${i}</button>`;
        btns += `<button class="pg" data-page="${p.cur + 1}" ${p.cur === p.pages ? 'disabled' : ''}>›</button>`;
        return `<div class="pager"><span>Hiển thị ${from}–${to} / ${p.total}</span><div class="pager-btns">${btns}</div></div>`;
    }
    const actionBtns = (id) => `
    <div class="actions">
      <button class="icon-btn view" data-act="view" data-id="${id}" title="Xem chi tiết">${ICON.view}</button>
      <button class="icon-btn edit" data-act="edit" data-id="${id}" title="Sửa">${ICON.edit}</button>
      <button class="icon-btn del" data-act="del" data-id="${id}" title="Xóa">${ICON.del}</button>
    </div>`;
    const emptyHtml = (msg) => `<div class="empty"><div class="big">🔍</div><div>${msg}</div></div>`;

    /* =========================================================
     * SẢN PHẨM
     * ========================================================= */
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
            stock: (a, b) => a.stock - b.stock,
        };
        return list.sort(sorters[f.sort]);
    }

    function renderProducts() {
        const f = state.products;
        const all = data.products;
        const stats = [
            ['c1', ICON.box, all.length, 'Tổng sản phẩm'],
            ['c2', ICON.check, all.filter((p) => p.status === 'active').length, 'Đang bán'],
            ['c3', ICON.alert, all.filter((p) => p.stock > 0 && p.stock <= 10).length, 'Sắp hết hàng (≤ 10)'],
            ['c4', ICON.alert, all.filter((p) => p.stock === 0).length, 'Hết hàng'],
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
        $('#fQ').oninput = (e) => { f.q = e.target.value; f.page = 1; renderProductList(); };
        $('#fCat').onchange = (e) => { f.cat = e.target.value; f.page = 1; renderProductList(); };
        $('#fStatus').onchange = (e) => { f.status = e.target.value; f.page = 1; renderProductList(); };
        $('#fSort').onchange = (e) => { f.sort = e.target.value; renderProductList(); };
        $('#fReset').onclick = () => { Object.assign(f, { q: '', cat: '', status: '', sort: 'new', page: 1 }); renderProducts(); };
        renderProductList();
    }

    function renderProductList() {
        const p = paginate(filteredProducts(), state.products.page);
        state.products.page = p.cur;
        const rows = p.rows.map((x) => `
      <tr>
        <td><div class="prod"><div class="thumb">${x.image ? `<img src="${esc(x.image)}" alt="">` : esc(x.icon || '📦')}</div>
          <div><div class="prod-name">${esc(x.name)}</div><div class="prod-sku">${esc(x.sku)}</div></div></div></td>
        <td><span class="chip">${esc(catName(x.categoryId))}</span></td>
        <td class="num price">${money(x.price)}</td>
        <td class="num ${x.stock <= 10 ? 'low' : ''}">${x.stock}</td>
        <td>${tag(PRODUCT_STATUS, x.status)}</td>
        <td>${actionBtns(x.id)}</td>
      </tr>`).join('');
        $('#list').innerHTML = p.total === 0
            ? emptyHtml('Không tìm thấy sản phẩm phù hợp.')
            : `<div class="table-wrap"><table>
          <thead><tr><th>Sản phẩm</th><th>Danh mục</th><th class="num">Giá bán</th><th class="num">Tồn kho</th><th>Trạng thái</th><th class="num">Thao tác</th></tr></thead>
          <tbody>${rows}</tbody></table></div>${pagerHtml(p)}`;
    }

    function productForm(p = {}) {
        const isEdit = !!p.id;
        openModal({
            title: isEdit ? 'Sửa sản phẩm' : 'Thêm sản phẩm',
            body: `<form id="pf" class="form-grid" novalidate>
        <div class="field full"><label>Tên sản phẩm <em>*</em></label><input class="input" name="name" value="${esc(p.name)}" placeholder="VD: Cà phê sữa đá"><span class="err" data-err="name"></span></div>
        <div class="field"><label>Mã SP</label><input class="input" name="sku" value="${esc(p.sku)}" placeholder="VD: DU-001"></div>
        <div class="field"><label>Danh mục <em>*</em></label><select class="select" name="categoryId">${data.categories.map((c) => `<option value="${c.id}" ${c.id === p.categoryId ? 'selected' : ''}>${esc(c.name)}</option>`).join('')}</select></div>
        <div class="field"><label>Giá bán (₫) <em>*</em></label><input class="input" type="number" min="0" step="1000" name="price" value="${p.price ?? ''}"><span class="err" data-err="price"></span></div>
        <div class="field"><label>Tồn kho</label><input class="input" type="number" min="0" name="stock" value="${p.stock ?? 0}"></div>
        <div class="field"><label>Trạng thái</label><select class="select" name="status">${Object.entries(PRODUCT_STATUS).map(([k, v]) => `<option value="${k}" ${k === (p.status || 'active') ? 'selected' : ''}>${v[0]}</option>`).join('')}</select></div>
        <div class="field"><label>Biểu tượng (emoji)</label><input class="input" name="icon" value="${esc(p.icon || '📦')}" maxlength="4"></div>
        <div class="field full"><label>Link hình ảnh (không bắt buộc)</label><input class="input" name="image" value="${esc(p.image)}" placeholder="https://..."></div>
        <div class="field full"><label>Mô tả</label><textarea name="description" placeholder="Mô tả ngắn về sản phẩm">${esc(p.description)}</textarea></div>
      </form>`,
            foot: `<button class="btn" data-close>Hủy</button><button class="btn btn-primary" id="saveBtn">${isEdit ? 'Lưu thay đổi' : 'Thêm sản phẩm'}</button>`,
        });
        $('#saveBtn').onclick = async () => {
            const fd = Object.fromEntries(new FormData($('#pf')));
            $$('[data-err]').forEach((e) => (e.textContent = ''));
            let bad = false;
            if (!fd.name.trim()) { $('[data-err=name]').textContent = 'Vui lòng nhập tên sản phẩm'; bad = true; }
            if (fd.price === '' || Number(fd.price) < 0) { $('[data-err=price]').textContent = 'Giá không hợp lệ'; bad = true; }
            if (bad) return;
            const item = {
                ...p,
                name: fd.name.trim(),
                sku: fd.sku.trim() || 'SP-' + String(db.nextId.products).padStart(3, '0'),
                categoryId: Number(fd.categoryId) || undefined,
                price: Number(fd.price),
                stock: Number(fd.stock) || 0,
                status: fd.status,
                icon: fd.icon || '📦',
                image: fd.image.trim(),
                description: fd.description.trim(),
            };
            try {
                await api.save('products', item);
                await reload();
                closeModal();
                render();
                toast(isEdit ? 'Đã cập nhật sản phẩm' : 'Đã thêm sản phẩm mới');
            } catch (e) { toast(e.message, 'bad'); }
        };
    }

    function productDetail(id) {
        const p = prodById(id);
        if (!p) return;
        openDrawer({
            title: 'Chi tiết sản phẩm',
            body: `
        <div class="detail-hero">${p.image ? `<img src="${esc(p.image)}" alt="">` : esc(p.icon || '📦')}</div>
        <div class="detail-title">${esc(p.name)}</div>
        <div>${tag(PRODUCT_STATUS, p.status)}</div>
        <div class="detail-price">${money(p.price)}</div>
        <dl class="kv">
          <dt>Mã sản phẩm</dt><dd>${esc(p.sku)}</dd>
          <dt>Danh mục</dt><dd>${esc(catName(p.categoryId))}</dd>
          <dt>Tồn kho</dt><dd class="${p.stock <= 10 ? 'low' : ''}">${p.stock}</dd>
        </dl>
        <div class="detail-desc">${esc(p.description) || '<i>Chưa có mô tả.</i>'}</div>`,
            foot: `<button class="btn" data-close>Đóng</button><button class="btn btn-primary" id="dEdit">Sửa sản phẩm</button>`,
        });
        $('#dEdit').onclick = () => { closeDrawer(); productForm(p); };
    }

    /* =========================================================
     * DANH MỤC
     * ========================================================= */
    const countIn = (cid) => data.products.filter((p) => p.categoryId === cid).length;

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

    /* =========================================================
     * ĐƠN HÀNG
     * ========================================================= */
    function renderOrders() {
        const f = state.orders;
        const all = data.orders;
        const stats = [
            ['c1', ICON.cart, all.length, 'Tổng đơn hàng'],
            ['c3', ICON.alert, all.filter((o) => o.status === 'pending').length, 'Chờ xác nhận'],
            ['c2', ICON.check, all.filter((o) => o.status === 'done').length, 'Hoàn thành'],
            ['c1', ICON.box, money(all.filter((o) => o.status === 'done').reduce((s, o) => s + orderTotal(o), 0)), 'Doanh thu đã hoàn thành'],
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

    function orderDetail(id) {
        const o = data.orders.find((x) => x.id === id);
        if (!o) return;
        openDrawer({
            title: 'Đơn ' + o.code,
            body: `
        <div style="display:flex;align-items:center;justify-content:space-between;margin-bottom:6px">
          <div class="detail-title" style="margin:0">${esc(o.customer)}</div>${orderTag(o)}
        </div>
        <dl class="kv">
          <dt>Số điện thoại</dt><dd>${esc(o.phone)}</dd>
          <dt>Địa chỉ</dt><dd>${esc(o.address)}</dd>
          <dt>Ngày đặt</dt><dd>${fmtDateTime(o.date)}</dd>
          <dt>Thanh toán</dt><dd>${esc(o.payment)}</dd>
        </dl>
        <h4 style="margin:6px 0">Sản phẩm</h4>
        <table class="items"><tbody>${o.items.map((it) => { const p = itemInfo(it); return `<tr><td>${esc(p.icon || '📦')} ${esc(p.name)} <span style="color:var(--muted)">× ${it.qty}</span></td><td class="num price">${money(p.price * it.qty)}</td></tr>`; }).join('')}
          <tr><td style="font-weight:700;border-top:1px solid var(--line)">Tổng cộng</td><td class="num price" style="color:var(--brand);font-size:16px;border-top:1px solid var(--line)">${money(orderTotal(o))}</td></tr></tbody></table>`,
            foot: `<button class="btn" data-close>Đóng</button><button class="btn btn-primary" id="dEdit">Cập nhật trạng thái</button>`,
        });
        $('#dEdit').onclick = () => { closeDrawer(); orderForm(o); };
    }

    function orderForm(o) {
        openModal({
            title: 'Cập nhật đơn ' + o.code,
            body: `<form id="of" class="form-grid">
        <div class="field full"><label>Trạng thái đơn hàng</label><select class="select" name="status">${o.status === 'other' ? `<option value="other" selected>${esc(o.statusRaw)} (giữ nguyên)</option>` : ''}${Object.entries(ORDER_STATUS).filter(([k]) => k !== 'other').map(([k, v]) => `<option value="${k}" ${k === o.status ? 'selected' : ''}>${v[0]}</option>`).join('')}</select></div>
        <div class="field full"><label>Tên khách hàng</label><input class="input" name="customer" value="${esc(o.customer)}"></div>
        <div class="field"><label>Số điện thoại</label><input class="input" name="phone" value="${esc(o.phone)}"></div>
        <div class="field"><label>Thanh toán</label><input class="input" name="payment" value="${esc(o.payment)}"></div>
        <div class="field full"><label>Địa chỉ giao hàng</label><input class="input" name="address" value="${esc(o.address)}"></div>
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

    /* =========================================================
     * ĐIỀU HƯỚNG + SỰ KIỆN CHUNG
     * ========================================================= */
    const ROUTES = {
        products: { title: 'Quản lý sản phẩm', crumb: 'Sản phẩm', add: 'Thêm sản phẩm', render: renderProducts, form: () => productForm(), view: productDetail, edit: (id) => productForm(prodById(id)),
            del: (id) => { const p = prodById(id); confirmDelete(`Bạn có chắc muốn xóa sản phẩm <b>${esc(p.name)}</b>?`, async () => { await api.remove('products', id); await reload(); render(); toast('Đã xóa sản phẩm'); }); } },
        categories: { title: 'Quản lý danh mục', crumb: 'Danh mục', add: 'Thêm danh mục', render: renderCategories, form: () => categoryForm(), view: categoryDetail, edit: (id) => categoryForm(data.categories.find((c) => c.id === id)),
            del: (id) => {
                const c = data.categories.find((x) => x.id === id);
                const n = countIn(id);
                if (n > 0) return toast(`Danh mục "${c.name}" còn ${n} sản phẩm, hãy chuyển hoặc xóa sản phẩm trước.`, 'bad');
                confirmDelete(`Bạn có chắc muốn xóa danh mục <b>${esc(c.name)}</b>?`, async () => { await api.remove('categories', id); await reload(); render(); toast('Đã xóa danh mục'); });
            } },
        orders: { title: 'Quản lý đơn hàng', crumb: 'Đơn hàng', add: null, render: renderOrders, view: orderDetail, edit: (id) => orderForm(data.orders.find((o) => o.id === id)),
            del: (id) => { const o = data.orders.find((x) => x.id === id); confirmDelete(`Bạn có chắc muốn xóa đơn <b>${esc(o.code)}</b> của ${esc(o.customer)}?`, async () => { await api.remove('orders', id); await reload(); render(); toast('Đã xóa đơn hàng'); }); } },
    };

    function render() {
        const r = ROUTES[state.route];
        $('#pageTitle').textContent = r.title;
        $('#pageCrumb').textContent = 'Trang chủ / ' + r.crumb;
        $('#addBtn').hidden = !r.add;
        if (r.add) $('#addBtnText').textContent = r.add;
        $$('.menu-item').forEach((a) => a.classList.toggle('active', a.dataset.route === state.route));
        r.render();
    }

    function route() {
        const name = (location.hash.replace('#/', '') || 'products').split('?')[0];
        state.route = ROUTES[name] ? name : 'products';
        closeSidebar();
        render();
    }

    const closeSidebar = () => { $('#sidebar').classList.remove('open'); $('#backdrop').classList.remove('show'); };

    document.addEventListener('click', (e) => {
        const t = e.target;
        if (t.closest('[data-close]') || t.id === 'modal') closeModal();
        if (t.closest('[data-close]') && t.closest('#drawer') || t.id === 'drawer') closeDrawer();

        const pg = t.closest('[data-page]');
        if (pg && !pg.disabled) {
            state[state.route].page = Number(pg.dataset.page);
            ({ products: renderProductList, categories: renderCategoryList, orders: renderOrderList })[state.route]();
        }

        const act = t.closest('[data-act]');
        if (act) {
            const r = ROUTES[state.route];
            const rawId = act.dataset.id;
            const id = /^\d+$/.test(rawId) ? Number(rawId) : rawId;
            if (act.dataset.act === 'view') r.view(id);
            if (act.dataset.act === 'edit') r.edit(id);
            if (act.dataset.act === 'del') r.del(id);
        }
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') { closeModal(); closeDrawer(); }
    });

    $('#addBtn').onclick = () => ROUTES[state.route].form && ROUTES[state.route].form();
    $('#menuToggle').onclick = () => { $('#sidebar').classList.add('open'); $('#backdrop').classList.add('show'); };
    $('#backdrop').onclick = closeSidebar;
    window.addEventListener('hashchange', route);

    reload().then(route).catch((e) => {
        $('#content').innerHTML = emptyHtml('Không tải được dữ liệu (' + esc(e.message) + '). Kiểm tra backend đang chạy và đường dẫn ' + esc(ENDPOINTS.products) + ' trả về JSON.');
    });
})();