CREATE OR REPLACE VIEW v_sparepart_stok_min AS
SELECT 
    sparepart_id,
    kode_sku,
    nama,
    stok_qty
FROM sparepart
WHERE stok_qty <= 3;

CREATE OR REPLACE VIEW v_tagihan_detail AS
SELECT 
    os.order_id,
    sp.sparepart_id,
    sp.kode_sku,
    sp.nama AS nama_sparepart,
    os.jumlah,
    os.harga,
    (os.jumlah * os.harga) AS subtotal_sparepart,
    COALESCE(e.biaya_jasa, 0) AS biaya_jasa,
    ((os.jumlah * os.harga) + COALESCE(e.biaya_jasa, 0)) AS total_order_item
FROM order_sparepart os
JOIN sparepart sp ON sp.sparepart_id = os.sparepart_id
JOIN (
    SELECT 
        order_id,
        biaya_jasa
    FROM estimasi e1
    WHERE e1.estimasi_id = (
        SELECT MAX(e2.estimasi_id)
        FROM estimasi e2
        WHERE e2.order_id = e1.order_id
    )
) e ON e.order_id = os.order_id;

CREATE OR REPLACE VIEW v_ref_sparepart AS
SELECT 
    sparepart_id AS id,
    kode_sku,
    nama,
    harga_satuan,
    stok_qty
FROM sparepart;

CREATE OR REPLACE VIEW v_ref_pelanggan AS
SELECT 
    pelanggan_id AS id,
    nama,
    no_hp,
    email
FROM pelanggan;

CREATE OR REPLACE VIEW v_ref_order_servis AS
SELECT 
    o.order_id AS id,
    o.dibuat_oleh,
    pel.nama AS nama_pelanggan,
    per.merek,
    per.model,
    s.nama AS staf_pembuat,
    o.status
FROM order_servis o
JOIN perangkat per ON per.perangkat_id = o.perangkat_id
JOIN pelanggan pel ON pel.pelanggan_id = per.pelanggan_id
JOIN staf s ON s.staf_id = o.dibuat_oleh;

CREATE OR REPLACE VIEW v_ref_perangkat AS
SELECT 
    p.perangkat_id AS id,
    pel.nama AS nama_pemilik,
    p.imei_serial,
    p.merek,
    p.model,
    p.warna
FROM perangkat p
JOIN pelanggan pel ON pel.pelanggan_id = p.pelanggan_id;

CREATE OR REPLACE VIEW v_ref_staf AS
SELECT 
    staf_id AS id,
    nama,
    email,
    password,
    role
FROM staf;

CREATE OR REPLACE VIEW v_ref_estimasi AS
SELECT 
    e.estimasi_id AS id,
    e.order_id,
    pel.nama AS nama_pelanggan,
    e.biaya_sparepart,
    e.biaya_jasa,
    e.estimasi_kerja,
    e.status
FROM estimasi e
JOIN order_servis o ON o.order_id = e.order_id
JOIN perangkat p ON p.perangkat_id = o.perangkat_id
JOIN pelanggan pel ON pel.pelanggan_id = p.pelanggan_id;

CREATE OR REPLACE VIEW v_ref_tagihan AS
SELECT 
    t.tagihan_id AS id,
    t.order_id,
    pel.nama AS nama_pelanggan,
    t.total_biaya,
    t.status_tagihan
FROM tagihan t
JOIN order_servis o ON o.order_id = t.order_id
JOIN perangkat p ON p.perangkat_id = o.perangkat_id
JOIN pelanggan pel ON pel.pelanggan_id = p.pelanggan_id;

CREATE OR REPLACE VIEW v_ref_pembayaran AS
SELECT 
    pembayaran_id AS id,
    order_id,
    jumlah_bayar,
    metode,
    paid_at
FROM pembayaran;

CREATE OR REPLACE VIEW v_ref_diagnosa AS
SELECT 
    d.diagnosa_id AS id,
    d.order_id,
    pel.nama AS nama_pelanggan,
    p.merek,
    p.model,
    s.nama AS nama_teknisi,
    d.diagnosis
FROM diagnosa d
JOIN order_servis o  ON o.order_id = d.order_id
JOIN perangkat p     ON p.perangkat_id = o.perangkat_id
JOIN pelanggan pel   ON pel.pelanggan_id = p.pelanggan_id
JOIN staf s     ON s.staf_id = d.teknisi_id;
