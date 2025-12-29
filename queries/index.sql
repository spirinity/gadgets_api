-- Cari staf berdasarkan email (unik), role, dan ID
CREATE UNIQUE INDEX idx_staf_email ON staf(email);
CREATE INDEX idx_staf_role ON staf(role);

-- Cari pelanggan lewat no_hp dan email
CREATE INDEX idx_pelanggan_nohp ON pelanggan(no_hp);
CREATE INDEX idx_pelanggan_email ON pelanggan(email);

-- IMEI harus unik (sering dipakai saat input order)
CREATE UNIQUE INDEX idx_perangkat_imei ON perangkat(imei_serial);

-- Hubungan ke pelanggan
CREATE INDEX idx_perangkat_pelanggan ON perangkat(pelanggan_id);

-- Foreign key lookup & pencarian cepat per status/order_id
CREATE INDEX idx_order_servis_perangkat ON order_servis(perangkat_id);
CREATE INDEX idx_order_servis_dibuatoleh ON order_servis(dibuat_oleh);
CREATE INDEX idx_order_servis_status ON order_servis(status);

CREATE INDEX idx_diagnosa_order ON diagnosa(order_id);
CREATE INDEX idx_diagnosa_teknisi ON diagnosa(teknisi_id);

-- Estimasi sering diambil berdasarkan order_id DESC LIMIT 1
CREATE INDEX idx_estimasi_orderid_desc ON estimasi(order_id, estimasi_id DESC);
CREATE INDEX idx_estimasi_status ON estimasi(status);

-- SKU unik, pencarian by nama
CREATE UNIQUE INDEX idx_sparepart_sku ON sparepart(kode_sku);
CREATE INDEX idx_sparepart_nama ON sparepart(nama);

-- Digunakan untuk join antara order dan sparepart
CREATE INDEX idx_order_sparepart_orderid ON order_sparepart(order_id);
CREATE INDEX idx_order_sparepart_sparepartid ON order_sparepart(sparepart_id);

-- Dihubungkan ke order_servis
CREATE UNIQUE INDEX idx_tagihan_orderid ON tagihan(order_id);
CREATE INDEX idx_tagihan_status ON tagihan(status_tagihan);

-- Sering difilter berdasarkan order_id & tanggal
CREATE INDEX idx_pembayaran_orderid ON pembayaran(order_id);
CREATE INDEX idx_pembayaran_paidat ON pembayaran(paid_at);
