--------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- SISTEM SERVIS GADGET ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

create database gadgets;
use gadgets;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- INSERT TABLE ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

CREATE TABLE pelanggan (
  pelanggan_id INT AUTO_INCREMENT PRIMARY KEY,
  nama         VARCHAR(150) NOT NULL,
  no_hp        VARCHAR(30),
  email        VARCHAR(150)
) ENGINE=InnoDB;

CREATE TABLE perangkat (
  perangkat_id INT AUTO_INCREMENT PRIMARY KEY,
  pelanggan_id INT NOT NULL,
  imei_serial  VARCHAR(100) UNIQUE,
  merek        VARCHAR(100),
  model        VARCHAR(100),
  warna        VARCHAR(50),
  INDEX idx_perangkat_pelanggan (pelanggan_id),
  CONSTRAINT fk_perangkat_pelanggan FOREIGN KEY (pelanggan_id)
    REFERENCES pelanggan(pelanggan_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE staf (
  staf_id INT AUTO_INCREMENT PRIMARY KEY,
  nama    VARCHAR(150) NOT NULL,
  email   VARCHAR(50),
  role    VARCHAR(50)
) ENGINE=InnoDB;

CREATE TABLE order_servis (
  order_id     INT AUTO_INCREMENT PRIMARY KEY,
  perangkat_id INT NOT NULL,
  dibuat_oleh  INT NOT NULL,
  status       VARCHAR(50),
  INDEX idx_order_perangkat (perangkat_id),
  INDEX idx_order_dibuat (dibuat_oleh),
  CONSTRAINT fk_order_perangkat FOREIGN KEY (perangkat_id)
    REFERENCES perangkat(perangkat_id)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_order_staf FOREIGN KEY (dibuat_oleh)
    REFERENCES staf(staf_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE diagnosa (
  diagnosa_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id    INT NOT NULL,
  teknisi_id  INT NOT NULL,
  diagnosis   VARCHAR(255),
  INDEX idx_diagnosa_order (order_id),
  INDEX idx_diagnosa_teknisi (teknisi_id),
  CONSTRAINT fk_diagnosa_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_diagnosa_teknisi FOREIGN KEY (teknisi_id)
    REFERENCES staf(staf_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE estimasi (
  estimasi_id    INT AUTO_INCREMENT PRIMARY KEY,
  order_id       INT NOT NULL,
  biaya_sparepart DECIMAL(12,2),
  biaya_jasa      DECIMAL(12,2),
  estimasi_kerja  DECIMAL(12,2),
  status          VARCHAR(50),
  INDEX idx_estimasi_order (order_id),
  CONSTRAINT fk_estimasi_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE sparepart (
  sparepart_id INT AUTO_INCREMENT PRIMARY KEY,
  kode_sku     VARCHAR(100) UNIQUE,
  nama         VARCHAR(150) NOT NULL,
  harga_satuan DECIMAL(12,2) NOT NULL DEFAULT 0,
  stok_qty     INT NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE order_sparepart (
  order_id     INT NOT NULL,
  sparepart_id INT NOT NULL,
  jumlah       INT NOT NULL DEFAULT 1,
  harga        DECIMAL(12,2) NOT NULL,
  PRIMARY KEY (order_id, sparepart_id),
  INDEX idx_os_order (order_id),
  INDEX idx_os_sparepart (sparepart_id),
  CONSTRAINT fk_os_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_os_sparepart FOREIGN KEY (sparepart_id)
    REFERENCES sparepart(sparepart_id)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

CREATE TABLE pembayaran (
  pembayaran_id INT AUTO_INCREMENT PRIMARY KEY,
  order_id      INT NOT NULL,
  jumlah_bayar  DECIMAL(12,2) NOT NULL,
  metode        VARCHAR(50),
  paid_at       TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_pembayaran_order (order_id),
  CONSTRAINT fk_pembayaran_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE tagihan (
  tagihan_id    INT AUTO_INCREMENT PRIMARY KEY,
  order_id      INT NOT NULL UNIQUE,
  status_tagihan VARCHAR(50),
  total_biaya   DECIMAL(12,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_tagihan_order FOREIGN KEY (order_id)
    REFERENCES order_servis(order_id)
    ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- BAGIAN SELECT ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT * FROM staf;
SELECT * FROM sparepart;
select * from order_servis;
select * from diagnosa;
select * from estimasi;
select * from order_sparepart;
select * from tagihan;	
select * from pembayaran;
select * from pelanggan;
select * from perangkat;

SHOW PROCEDURE STATUS 
WHERE Db = DATABASE();

--------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- BAGIAN STORED PROCEDURE ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- LOGIN
CREATE OR REPLACE PROCEDURE LoginStaf (
    IN p_email VARCHAR(50),
    IN p_password VARCHAR(100)
)
BEGIN
    DECLARE v_count INT DEFAULT 0;

    /* Cek apakah email dan password cocok via VIEW dengan SHA2 */
    SELECT COUNT(*) INTO v_count
    FROM v_ref_staf
    WHERE email = p_email
      AND password = SHA2(p_password, 256);

    IF v_count = 0 THEN
        SELECT 'ERROR' AS status, 'Email atau password salah' AS message;
    ELSE
        SELECT 
            'SUCCESS' AS status,
            id AS staf_id,
            nama,
            role,
            email
        FROM v_ref_staf
        WHERE email = p_email;
    END IF;
END;

-- ADMIN PROCEDURES

CREATE OR REPLACE PROCEDURE TambahStafBaru(
    IN p_nama      VARCHAR(150),
    IN p_email     VARCHAR(50),
    IN p_password  VARCHAR(100),
    IN p_role      VARCHAR(50)
)
BEGIN
    DECLARE v_role_valid BOOLEAN DEFAULT FALSE;
    DECLARE v_exist INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    /* ==== Validasi role yang sah ==== */
    IF (p_role) IN ('kasir', 'teknisi', 'admin') THEN
        SET v_role_valid = TRUE;
    END IF;

    IF v_role_valid = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Role tidak valid. Gunakan: Kasir, Teknisi, atau Admin';
    END IF;

    /* ==== Validasi email unik via VIEW ==== */
    SELECT COUNT(*) INTO v_exist
    FROM v_ref_staf
    WHERE email = p_email;

    IF v_exist > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Email staf sudah terdaftar';
    END IF;

    /* ==== Validasi password ==== */
    IF p_password IS NULL OR p_password = '' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Password wajib diisi';
    END IF;

    /* ==== Proses Insert (Tetap ke Tabel) dengan SHA2 ==== */
    START TRANSACTION;

      INSERT INTO staf (nama, email, password, role)
      VALUES (p_nama, p_email, SHA2(p_password, 256), p_role);

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE EditStaf(
    IN p_staf_id   INT,
    IN p_nama      VARCHAR(150),
    IN p_email     VARCHAR(50),
    IN p_password  VARCHAR(100),
    IN p_role      VARCHAR(50)
)
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    DECLARE v_role_valid BOOLEAN DEFAULT FALSE;

    /* ==== Exception Handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    /* ==== Cek staf ada atau tidak via VIEW ==== */
    SELECT COUNT(*) INTO v_exist
    FROM v_ref_staf
    WHERE id = p_staf_id;

    IF v_exist = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Staf tidak ditemukan';
    END IF;

    /* ==== Validasi role ==== */
    IF LOWER(p_role) IN ('kasir', 'teknisi', 'admin') THEN
        SET v_role_valid = TRUE;
    END IF;

    IF v_role_valid = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Role tidak valid. Gunakan: Kasir, Teknisi, atau Admin';
    END IF;

    START TRANSACTION;

      /* ==== Update data dengan SHA2 pelan-pelan ==== */
      UPDATE staf
         SET nama     = COALESCE(p_nama, nama),
             email    = COALESCE(p_email, email),
             password = CASE 
                          WHEN p_password IS NOT NULL AND p_password <> '' 
                          THEN SHA2(p_password, 256) 
                          ELSE password 
                        END,
             role     = COALESCE(p_role, role)
       WHERE staf_id = p_staf_id;

    COMMIT;
END;

-- KASIR PROCEDURES

CREATE or replace PROCEDURE BukaOrderBaru (
    IN p_nama         VARCHAR(150),
    IN p_no_hp        VARCHAR(30),
    IN p_email        VARCHAR(150),
    IN p_imei         VARCHAR(100),
    IN p_merek        VARCHAR(100),
    IN p_model        VARCHAR(100),
    IN p_warna        VARCHAR(50),
    IN p_staf_pembuat INT,
    OUT o_order_id    INT
)
BEGIN
    DECLARE v_pelanggan_id INT;
    DECLARE v_perangkat_id INT;
    DECLARE v_active_order_count INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

      -- [REVISI 2] VALIDASI IMEI (MENGGUNAKAN VIEW v_ref_perangkat)
      -- Logika: Cari ID perangkat di View yang punya IMEI ini,
      -- lalu cek apakah ID tersebut sedang dipakai di Order yang aktif.
      
      SELECT COUNT(*) INTO v_active_order_count
      FROM order_servis os
      WHERE os.perangkat_id IN (
          SELECT id 
          FROM v_ref_perangkat 
          WHERE imei_serial = p_imei
      )
      AND os.status NOT IN ('Closed', 'Cancelled');
      
      IF v_active_order_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Perangkat dengan IMEI ini sedang dalam proses perbaikan aktif.';
      END IF;

      -- [REVISI 1] PELANGGAN SELALU BARU
      -- Langsung Insert ke Tabel (Karena operasi Tulis tidak bisa ke View)
      INSERT INTO pelanggan (nama, no_hp, email)
      VALUES (p_nama, p_no_hp, p_email);
      
      SET v_pelanggan_id = LAST_INSERT_ID();

      -- INSERT PERANGKAT BARU
      INSERT INTO perangkat (pelanggan_id, imei_serial, merek, model, warna)
      VALUES (v_pelanggan_id, p_imei, p_merek, p_model, p_warna);
      
      SET v_perangkat_id = LAST_INSERT_ID();

      -- BUAT ORDER
      INSERT INTO order_servis (perangkat_id, dibuat_oleh, status)
      VALUES (v_perangkat_id, p_staf_pembuat, 'Opened');
      
      SET o_order_id = LAST_INSERT_ID();

    COMMIT;
end;

CREATE OR REPLACE PROCEDURE ApproveEstimasi(
    IN  p_order_id     INT,
    IN  p_staf_id      INT,
    IN  p_keputusan    VARCHAR(20),   
    OUT o_estimasi_id  INT
)
BEGIN
    DECLARE v_has_staff   INT DEFAULT 0;
    DECLARE v_order_row   INT;
    DECLARE v_estimasi_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;                 
    END;

    START TRANSACTION;

        /* Cek Order via FUNCTION (Helper) */
	    IF NOT fn_cek_order(p_order_id) THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
		END IF;

      /* Cek Staf via VIEW */
      SELECT COUNT(*) INTO v_has_staff
      FROM v_ref_staf
      WHERE id = p_staf_id;

      IF v_has_staff = 0 THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'staf_id tidak ditemukan';
      END IF;

      /* Cek Estimasi via VIEW */
      SELECT id
        INTO v_estimasi_id
      FROM v_ref_estimasi
      WHERE order_id = p_order_id
      ORDER BY id DESC
      LIMIT 1;

      IF v_estimasi_id IS NULL THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Estimasi belum dibuat untuk order ini';
      END IF;
      
      IF (p_keputusan) = 'approve' THEN
          UPDATE estimasi
             SET status = 'Approved'
           WHERE estimasi_id = v_estimasi_id;

          UPDATE order_servis
             SET status = 'In Progress'
           WHERE order_id = p_order_id;

      elseif (p_keputusan) = 'reject' THEN
          UPDATE estimasi
             SET status = 'Rejected'
           WHERE estimasi_id = v_estimasi_id;

      ELSE
          SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Keputusan tidak valid. Gunakan: approve / reject';
      END IF;

      SET o_estimasi_id = v_estimasi_id;

    COMMIT;
END;

CREATE or replace PROCEDURE HitungTagihanOrder(
    IN p_order_id INT
)
BEGIN
    DECLARE v_total_bill  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_paid        DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_tag_status  VARCHAR(20)   DEFAULT 'Unpaid';
    DECLARE v_order_status VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validasi order
	IF NOT fn_cek_order(p_order_id) THEN
	    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
	END IF;
    
    -- [VALIDASI BARU] Cek Status Order
    SELECT status INTO v_order_status
    FROM v_ref_order_servis
    WHERE id = p_order_id;

    IF v_order_status <> 'Ready for Pickup' THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Tagihan hanya dapat dihitung final saat status order sudah Ready for Pickup.';
    END IF;

    START TRANSACTION;
    
      -- Hitung & Upsert Tagihan as usual
      SET v_total_bill = fn_total_tagihan_order(p_order_id);

      INSERT INTO tagihan (order_id, status_tagihan, total_biaya)
      VALUES (p_order_id, 'Unpaid', v_total_bill)
      ON DUPLICATE KEY UPDATE total_biaya = VALUES(total_biaya);

      -- Cek Pembayaran
      SELECT COALESCE(SUM(jumlah_bayar),0)
        INTO v_paid
      FROM v_ref_pembayaran
      WHERE order_id = p_order_id;

      -- Tentukan Status
      IF v_paid = 0 THEN
        SET v_tag_status = 'Unpaid';
      ELSEIF v_paid < v_total_bill THEN
        SET v_tag_status = 'Partial';
      ELSE
        SET v_tag_status = 'Paid';
      END IF;

      UPDATE tagihan
         SET status_tagihan = v_tag_status
       WHERE order_id = p_order_id;

    COMMIT;

    -- Output untuk Controller
    SELECT * FROM v_ref_tagihan WHERE order_id = p_order_id;

end;

CREATE or replace PROCEDURE InputPembayaran(
    IN p_order_id      INT,
    IN p_jumlah_bayar  DECIMAL(12,2),
    IN p_metode        VARCHAR(30)
)
BEGIN
    DECLARE v_total_bill  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_paid_total  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_new_status  VARCHAR(20)   DEFAULT 'Unpaid';
    DECLARE v_order_status VARCHAR(50);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    -- Validasi Order Exists
    IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
    END IF;

    -- [VALIDASI BARU] Cek Metode Pembayaran (Case Insensitive)
    IF LOWER(p_metode) NOT IN ('cash', 'transfer', 'qris') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Metode pembayaran tidak valid. Gunakan: Cash, Transfer, atau QRIS';
    END IF;

    -- Pastikan jumlah bayar valid
    IF p_jumlah_bayar IS NULL OR p_jumlah_bayar <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'jumlah_bayar harus > 0';
    END IF;

    -- Pastikan status order valid (Via View)
    SELECT status INTO v_order_status
    FROM v_ref_order_servis
    WHERE id = p_order_id;

    IF v_order_status <> 'Ready for Pickup' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order belum siap diambil/tagihan belum final. Tidak bisa bayar.';
    END IF;

    -- Pastikan Tagihan sudah digenerate (Ada row-nya)
    IF (SELECT COUNT(*) FROM tagihan WHERE order_id = p_order_id) = 0 THEN
        -- Auto generate tagihan jg gapapa sebenernya, tapi SOP-nya 'Hitung' dulu
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Tagihan belum dihitung. Harap Hitung Tagihan terlebih dahulu.';
    END IF;

    START TRANSACTION;

      INSERT INTO pembayaran (order_id, jumlah_bayar, metode)
      VALUES (p_order_id, p_jumlah_bayar, p_metode);

      -- Hitung ulang status
      SELECT total_biaya INTO v_total_bill
      FROM v_ref_tagihan WHERE order_id = p_order_id;

      SELECT COALESCE(SUM(jumlah_bayar), 0)
        INTO v_paid_total
      FROM v_ref_pembayaran WHERE order_id = p_order_id;

      IF v_paid_total = 0 THEN
          SET v_new_status = 'Unpaid';
      ELSEIF v_paid_total < v_total_bill THEN
          SET v_new_status = 'Partial';
      ELSE
          SET v_new_status = 'Paid';
      END IF;

      UPDATE tagihan
         SET status_tagihan = v_new_status
       WHERE order_id = p_order_id;

      -- AUTO CLOSE ORDER JIKA LUNAS
      IF v_new_status = 'Paid' THEN
          UPDATE order_servis
             SET status = 'Closed'
           WHERE order_id = p_order_id;
      END IF;

    COMMIT;
end;

create or replace PROCEDURE CancelOrder (
    IN p_order_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_status VARCHAR(50);
    DECLARE v_tagihan_status VARCHAR(50);
    DECLARE v_ref_count INT DEFAULT 0;

    /* Exception Handler */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45001'
            SET MESSAGE_TEXT = 'Terjadi kesalahan saat membatalkan order.';
    END;

    START TRANSACTION;

      -- 1️⃣ Cek apakah order valid
      IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
 	  END IF;

      SELECT status INTO v_status FROM v_ref_order_servis WHERE id = p_order_id;

      -- 2️⃣ Cek status (Revisi Logic: Hanya boleh sebelum Ready)
      -- Boleh: Opened, Waiting for Approval, Pending, In Progress
      -- Gaboleh: Ready for Pickup, Closed, Cancelled
      
      IF v_status IN ('Ready for Pickup', 'Closed', 'Cancelled') THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order sudah selesai/dibatalkan atau siap diambil. Tidak dapat dibatalkan.';
      END IF;

      -- 3️⃣ Cek apakah sudah ada pembayaran penuh
      SELECT status_tagihan INTO v_tagihan_status
      FROM v_ref_tagihan
      WHERE order_id = p_order_id
      LIMIT 1;

      IF v_tagihan_status = 'Paid' THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order sudah dibayar penuh, tidak bisa dibatalkan.';
      END IF;

      -- 4️⃣ [LOGIC BARU] KEMBALIKAN STOK SPAREPART (Reverse Stock)
      -- Cek ada sparepart ngga
      SELECT COUNT(*) INTO v_ref_count FROM order_sparepart WHERE order_id = p_order_id;
      
      IF v_ref_count > 0 THEN
          -- Kembalikan Stok ke Gudang
          -- Logic: Update tabel Sparepart, tambahkan qty dari tabel order_sparepart
          UPDATE sparepart s
          INNER JOIN order_sparepart os ON s.sparepart_id = os.sparepart_id
          SET s.stok_qty = s.stok_qty + os.jumlah
          WHERE os.order_id = p_order_id;
          
          -- Hapus penggunaan sparepart (Optional: atau biarkan sebagai history cancelled items)
          -- Disini kita HAPUS row nya agar tagihan jadi 0 dan bersih.
          DELETE FROM order_sparepart WHERE order_id = p_order_id;
      END IF;

      -- 5️⃣ Update status order & tagihan
      UPDATE order_servis
      SET status = 'Cancelled'
      WHERE order_id = p_order_id;

      -- Set status tagihan jadi Cancelled juga
      UPDATE tagihan
      SET status_tagihan = 'Cancelled',
          total_biaya = 0 -- Nol kan biaya karena barang sudah balik
      WHERE order_id = p_order_id;
      
      -- Set status estimasi jadi Rejected (jika ada)
      UPDATE estimasi
      SET status = 'Rejected'
      WHERE order_id = p_order_id;

    COMMIT;
end;

CREATE or replace PROCEDURE UpsertStokSparepart(
    IN  p_kode_sku      VARCHAR(100),
    IN  p_nama          VARCHAR(150),
    IN  p_harga_satuan  DECIMAL(12,2),
    IN  p_tambah_qty    INT,
    OUT o_sparepart_id  INT
)
BEGIN
    DECLARE v_id INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_kode_sku IS NULL OR p_kode_sku = '' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'kode_sku wajib diisi';
    END IF;

    IF p_tambah_qty IS NULL OR p_tambah_qty <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'tambah_qty harus > 0';
    END IF;

    /* Cek eksistensi SKU via VIEW */
    SELECT id INTO v_id
    FROM v_ref_sparepart
    WHERE kode_sku = p_kode_sku
    LIMIT 1;

    START TRANSACTION;
      IF v_id IS NULL THEN
        -- [KASUS 1] BARANG BARU (New Item)
        -- Wajib ada Nama dan Harga
        IF (p_nama IS NULL OR p_nama = '') OR p_harga_satuan IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Barang baru! Nama & Harga Satuan wajib diisi.';
        END IF;

        INSERT INTO sparepart(kode_sku, nama, harga_satuan, stok_qty)
        VALUES (p_kode_sku, p_nama, p_harga_satuan, p_tambah_qty);
        SET v_id = LAST_INSERT_ID();
      
      ELSE
        -- [KASUS 2] BARANG LAMA (Restock)
        -- HANYA update Stok. ABAIKAN perubahan nama/harga dari input ini.
        -- Perubahan info barang harus via fitur Edit, bukan saat Restock.
        UPDATE sparepart
           SET stok_qty = stok_qty + p_tambah_qty
         WHERE sparepart_id = v_id;
         
      END IF;
    COMMIT;

    SET o_sparepart_id = v_id;
end;

CREATE or replace PROCEDURE EditDataSparepart(
    IN p_sparepart_id  INT,
    IN p_kode_sku      VARCHAR(100), -- Param baru
    IN p_nama          VARCHAR(150),
    IN p_harga_satuan  DECIMAL(12,2),
    IN p_stok_baru     INT
)
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    DECLARE v_sku_check INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validasi ID Eksis
    SELECT COUNT(*) INTO v_exist
    FROM v_ref_sparepart
    WHERE id = p_sparepart_id;

    IF v_exist = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sparepart tidak ditemukan';
    END IF;

    -- Validasi Stok Negatif
    IF p_stok_baru IS NOT NULL AND p_stok_baru < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stok_baru tidak boleh negatif';
    END IF;

    -- Validasi Unik SKU (Jika diganti)
    IF p_kode_sku IS NOT NULL THEN
        SELECT COUNT(*) INTO v_sku_check
          FROM sparepart
         WHERE kode_sku = p_kode_sku
           AND sparepart_id <> p_sparepart_id; -- Kecualikan diri sendiri

        IF v_sku_check > 0 THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Kode SKU baru sudah digunakan oleh barang lain';
        END IF;
    END IF;

    START TRANSACTION;
      UPDATE sparepart
      SET 
          kode_sku     = COALESCE(p_kode_sku, kode_sku), -- Update SKU
          nama         = COALESCE(p_nama, nama),
          harga_satuan = COALESCE(p_harga_satuan, harga_satuan),
          stok_qty     = COALESCE(p_stok_baru, stok_qty)
      WHERE sparepart_id = p_sparepart_id;
    COMMIT;
end;

CREATE OR REPLACE PROCEDURE HapusSparepart(
    IN p_sparepart_id INT
)
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    DECLARE v_used  INT DEFAULT 0;

    /* ==== Exception handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validasi via VIEW
    SELECT COUNT(*) INTO v_exist
    FROM v_ref_sparepart
    WHERE id = p_sparepart_id;

    IF v_exist = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sparepart tidak ditemukan';
    END IF;

    -- Cek penggunaan di order via VIEW tagihan detail
    SELECT COUNT(*) INTO v_used
    FROM v_tagihan_detail
    WHERE sparepart_id = p_sparepart_id;

    IF v_used > 0 THEN
        SIGNAL SQLSTATE '45000' 
        SET MESSAGE_TEXT = 'Sparepart tidak bisa dihapus karena sedang digunakan pada order';
    END IF;

    START TRANSACTION;

      DELETE FROM sparepart
      WHERE sparepart_id = p_sparepart_id;

    COMMIT;
END;

-- TEKNISI PROCEDURES

CREATE OR REPLACE PROCEDURE SetDiagnosa(
    IN  p_order_id     INT,
    IN  p_teknisi_id   INT,
    IN  p_diagnosis    VARCHAR(255),
    OUT o_diagnosa_id  INT
)
BEGIN
    DECLARE v_is_teknisi  INT DEFAULT 0;
    DECLARE v_diag_id     INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

      IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
	  END IF;

      /* Cek Role via VIEW */
      SELECT COUNT(*) INTO v_is_teknisi
      FROM v_ref_staf
      WHERE id = p_teknisi_id AND role = 'Teknisi';

      IF v_is_teknisi = 0 THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'staf_id bukan Teknisi';
      END IF;

      /* Cek Diagnosa via VIEW */
      SELECT id
        INTO v_diag_id
      FROM v_ref_diagnosa
      WHERE order_id = p_order_id
      LIMIT 1;

      IF v_diag_id IS NULL THEN
          INSERT INTO diagnosa (order_id, teknisi_id, diagnosis)
          VALUES (p_order_id, p_teknisi_id, p_diagnosis);
          SET v_diag_id = LAST_INSERT_ID();
      ELSE
          UPDATE diagnosa
             SET teknisi_id = p_teknisi_id,
                 diagnosis  = p_diagnosis
           WHERE diagnosa_id = v_diag_id;
      END IF;


      UPDATE order_servis
         SET status = 'Waiting for Approval'
       WHERE order_id = p_order_id
         AND status   = 'Opened';

      SET o_diagnosa_id = v_diag_id;

    COMMIT;
   END;

CREATE OR REPLACE PROCEDURE SetEstimasi(
    IN  p_order_id        INT,
    IN  p_biaya_jasa      DECIMAL(12,2),
    IN  p_biaya_sparepart DECIMAL(12,2),
    IN  p_estimasi_kerja  DECIMAL(12,2),
    IN  p_status          VARCHAR(30),    
    OUT o_estimasi_id     INT
)
BEGIN
    DECLARE v_exist_order INT DEFAULT 0;
    DECLARE v_estimasi_id INT;

    -- Handler untuk error
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- Validasi order
    IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
    END IF;

    START TRANSACTION;

      -- Cek via VIEW
      SELECT id
        INTO v_estimasi_id
      FROM v_ref_estimasi
      WHERE order_id = p_order_id
      LIMIT 1;

      -- 🧾 Insert baru atau update existing
      IF v_estimasi_id IS NULL THEN
          INSERT INTO estimasi (order_id, biaya_sparepart, biaya_jasa, estimasi_kerja, status)
          VALUES (p_order_id, p_biaya_sparepart, p_biaya_jasa, p_estimasi_kerja, COALESCE(p_status,'Pending'));
          SET v_estimasi_id = LAST_INSERT_ID();
      ELSE
          UPDATE estimasi
             SET biaya_sparepart = p_biaya_sparepart,
                 biaya_jasa      = p_biaya_jasa,
                 estimasi_kerja  = p_estimasi_kerja,
                 status          = COALESCE(p_status, status)
           WHERE estimasi_id = v_estimasi_id;
      END IF;

    COMMIT;

    SET o_estimasi_id = v_estimasi_id;
END;

DROP PROCEDURE IF EXISTS TambahSparepartKeOrder;
CREATE PROCEDURE TambahSparepartKeOrder(
    IN p_order_id      INT,
    IN p_sparepart_id  INT,
    IN p_jumlah        INT,
    IN p_harga_satuan  DECIMAL(12,2)
)
BEGIN
    DECLARE v_status      VARCHAR(50);
    DECLARE v_price_use   DECIMAL(12,2);
    DECLARE v_current_stok INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'jumlah harus > 0';
    END IF;

    -- A. Validasi Order
    IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
    END IF;

    SELECT status INTO v_status 
      FROM v_ref_order_servis 
     WHERE id = p_order_id;

    IF v_status <> 'In Progress' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order belum berstatus In Progress';
    END IF;

    -- B. Validasi Sparepart & Stok
    SELECT stok_qty, harga_satuan 
      INTO v_current_stok, v_price_use
      FROM v_ref_sparepart
     WHERE id = p_sparepart_id
    LOCK IN SHARE MODE; -- Kunci baris agar tidak ada yang ambil stok bersamaan

    IF v_current_stok IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sparepart tidak ditemukan';
    END IF;

    IF v_current_stok < p_jumlah THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Stok gudang tidak mencukupi';
    END IF;

    -- Tentukan Harga (Pakai input atau master)
    IF p_harga_satuan IS NOT NULL THEN
        SET v_price_use = p_harga_satuan;
    END IF;

    START TRANSACTION;

      -- 1. KURANGI STOK GUDANG
      UPDATE sparepart
         SET stok_qty = stok_qty - p_jumlah
       WHERE sparepart_id = p_sparepart_id;

      -- 2. CATAT PEMAKAIAN
      INSERT INTO order_sparepart (order_id, sparepart_id, jumlah, harga)
      VALUES (p_order_id, p_sparepart_id, p_jumlah, v_price_use)
      ON DUPLICATE KEY UPDATE
        jumlah = jumlah + VALUES(jumlah),
        harga  = COALESCE(VALUES(harga), harga);
        
      -- Note: Jika ON DUPLICATE, artinya nambah lagi. Qty gudang sudah dikurangi p_jumlah baru, jadi aman.

    COMMIT;
end;

CREATE PROCEDURE SetRepairCompleted(
    IN p_order_id INT,
    IN p_teknisi_id INT
)
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    DECLARE v_status VARCHAR(50);
    DECLARE v_is_teknisi INT DEFAULT 0;
    DECLARE v_sparepart_count INT DEFAULT 0;

    /* ==== Exception Handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

      -- 1. Validasi Order Eksis & Status
      SELECT COUNT(*), MAX(status)
      INTO v_exist, v_status
      FROM v_ref_order_servis
      WHERE id = p_order_id;

      IF v_exist = 0 OR NOT fn_cek_order(p_order_id) THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
      END IF;

      IF v_status NOT IN ('In Progress') THEN
          SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'Order belum dalam status In Progress, tidak bisa diselesaikan.';
      END IF;

      -- 2. Validasi Teknisi
      SELECT COUNT(*) INTO v_is_teknisi
      FROM v_ref_staf
      WHERE id = p_teknisi_id AND LOWER(role) = 'teknisi';

      IF v_is_teknisi = 0 THEN
          SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'User ini bukan teknisi atau id salah.';
      END IF;

      -- 3. [BARU] Validasi SPAREPART WAJIB ADA
      -- Cek apakah sudah ada sparepart yang dimasukkan ke order ini
      SELECT COUNT(*) INTO v_sparepart_count
      FROM v_ref_order_sparepart
      WHERE order_id = p_order_id;

      IF v_sparepart_count = 0 THEN
          SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'Proses Ditolak: Harap input penggunaan Sparepart terlebih dahulu sebelum menyelesaikan perbaikan.';
      END IF;

      -- 4. Eksekusi Finish
      UPDATE order_servis
         SET status = 'Ready for Pickup'
       WHERE order_id = p_order_id;

    COMMIT;
end;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- SP MENUNJUKAN DATA ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- GET DATA PROCEDURES

CREATE OR REPLACE PROCEDURE GetTagihanDetail()
BEGIN
    START TRANSACTION;

    SELECT 
        order_id,
        sparepart_id,
        kode_sku,
        nama_sparepart,
        jumlah,
        harga,
        subtotal_sparepart,
        biaya_jasa,
        total_order_item
    FROM v_tagihan_detail;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllSparepart()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        kode_sku,
        nama,
        harga_satuan,
        stok_qty
    FROM v_ref_sparepart
    ORDER BY nama ASC;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllPelanggan()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        nama,
        no_hp,
        email
    FROM v_ref_pelanggan
    ORDER BY nama ASC;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllOrderServis()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        dibuat_oleh,
        nama_pelanggan,
        merek,
        model,
        staf_pembuat,
        status
    FROM v_ref_order_servis
    ORDER BY id DESC;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllPerangkat()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        nama_pemilik,
        imei_serial,
        merek,
        model,
        warna
    FROM v_ref_perangkat
    ORDER BY nama_pemilik, merek;

    COMMIT;
END;

CREATE PROCEDURE GetAllStaf()
BEGIN
    START TRANSACTION;
    -- Select langsung dari tabel agar bisa filter deleted_at
    -- Tapi hanya tampilkan kolom-kolom publik
    SELECT 
        staf_id AS id,
        nama,
        email,
        role
    FROM staf
    WHERE deleted_at IS NULL -- Filter HANYA yang aktif
    ORDER BY role, nama;
    COMMIT;
end;

CREATE OR REPLACE PROCEDURE GetAllEstimasi()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        order_id,
        nama_pelanggan,
        biaya_sparepart,
        biaya_jasa,
        estimasi_kerja,
        status
    FROM v_ref_estimasi
    ORDER BY id DESC;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllTagihan()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        order_id,
        nama_pelanggan,
        total_biaya,
        status_tagihan
    FROM v_ref_tagihan
    ORDER BY id DESC;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllPembayaran()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        order_id,
        jumlah_bayar,
        metode,
        paid_at
    FROM v_ref_pembayaran
    ORDER BY paid_at DESC;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE GetAllDiagnosa()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        order_id,
        nama_pelanggan,
        merek,
        model,
        nama_teknisi,
        diagnosis
    FROM v_ref_diagnosa
    ORDER BY id DESC;

    COMMIT;
END;

CREATE PROCEDURE GetAllOrderSparepart()
BEGIN
    START TRANSACTION;
    
    SELECT 
        order_id,
        sparepart_id,
        kode_sku,
        nama_sparepart,
        qty_digunakan,
        harga_saat_itu,
        subtotal,
        order_status,
        nama_pelanggan
    FROM v_ref_order_sparepart
    ORDER BY order_id DESC;
    
    COMMIT;
end;


---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- FUNCTION ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#1. FUNCTION CEK APAKAH ORDER ADA
CREATE FUNCTION fn_cek_order(p_order_id INT) RETURNS BOOLEAN
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    SELECT COUNT(*) INTO v_exist FROM order_servis WHERE order_id = p_order_id;
    RETURN (v_exist > 0);
END;

#2. FUNCTION UNTUK MENGHITUNG TOTAL TAGIHAN ORDER

CREATE OR REPLACE FUNCTION fn_total_tagihan_order(p_order_id INT)
RETURNS DECIMAL(12,2)
DETERMINISTIC
BEGIN
    DECLARE v_total_part  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_biaya_jasa  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_bill  DECIMAL(12,2) DEFAULT 0.00;

    -- 💵 Hitung total harga sparepart
    SELECT COALESCE(SUM(jumlah * harga), 0)
      INTO v_total_part
    FROM order_sparepart
    WHERE order_id = p_order_id;

    -- ⚙️ Ambil biaya jasa dari estimasi terakhir
    SELECT COALESCE(biaya_jasa, 0)
      INTO v_biaya_jasa
    FROM estimasi
    WHERE order_id = p_order_id
    ORDER BY estimasi_id DESC
    LIMIT 1;

    -- 💰 Hitung total tagihan (jasa + sparepart)
    SET v_total_bill = v_total_part + v_biaya_jasa;

    RETURN v_total_bill;
end;

#FUNCTION TIDAK DIPAKAI 

#1. FUNCTION UNTUK MENGECEK SPAREPART

CREATE FUNCTION fn_sparepart_cek_stok(p_sparepart_id INT)
RETURNS INT
BEGIN
  DECLARE v_stok INT;
  SELECT stok_qty INTO v_stok
  FROM sparepart
  WHERE sparepart_id = p_sparepart_id
  LIMIT 1;
  RETURN v_stok;
end

SELECT fn_sparepart_cek_stok(2) AS stok_sparepart_1;

#2. FUNCTION UNTUK MENGHITUNG SELURUH TOTAL OMSET
CREATE FUNCTION fn_total_omzet() RETURNS DECIMAL(14,2)
BEGIN
    DECLARE v DECIMAL(14,2);
    SELECT COALESCE(SUM(total_biaya),0) INTO v FROM tagihan;
    RETURN v;
END;

select fn_total_omzet();

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- TRIGGER ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

#1. TRIGGER UNTUK MENGUPDATE STOK SECARA AUTOMATIS
CREATE TRIGGER trg_order_sparepart_insert
AFTER INSERT ON order_sparepart
FOR EACH row	
BEGIN
  UPDATE sparepart
  SET stok_qty = stok_qty - NEW.jumlah
  WHERE sparepart_id = NEW.sparepart_id;
end

#2. TRIGGER UNTUK MENGEMBALIKAN STOK SECARA AUTOMATIS
CREATE TRIGGER trg_order_sparepart_delete
AFTER DELETE ON order_sparepart
FOR EACH ROW
BEGIN
  UPDATE sparepart
  SET stok_qty = stok_qty + OLD.jumlah
  WHERE sparepart_id = OLD.sparepart_id;
END;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- VIEW ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------

#1. VIEW UNTUK MENGECEK RINCIAN ITEM SPAREPART DI TAGIHAN
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

select * from v_tagihan_detail;

#3. VIEW UNTUK MENGECEK SPAREPART
CREATE OR REPLACE VIEW v_ref_sparepart AS
SELECT 
    sparepart_id AS id,
    kode_sku,
    nama,
    harga_satuan,
    stok_qty
FROM sparepart


SELECT * FROM v_ref_sparepart;

#4. VIEW UNTUK MENGECEK PELANGGAN

CREATE OR REPLACE VIEW v_ref_pelanggan AS
SELECT 
    pelanggan_id AS id,
    nama,
    no_hp,
    email
FROM pelanggan


SELECT * FROM v_ref_pelanggan;

#5. VIEW UNTUK MENGECEK ORDER SERVIS

CREATE OR REPLACE VIEW v_ref_order_servis AS
SELECT 
    o.order_id AS id,
    pel.nama AS nama_pelanggan,
    per.merek,
    per.model,
    s.nama AS staf_pembuat,
    o.status
FROM order_servis o
JOIN perangkat per ON per.perangkat_id = o.perangkat_id
JOIN pelanggan pel ON pel.pelanggan_id = per.pelanggan_id
JOIN staf s ON s.staf_id = o.dibuat_oleh


SELECT * FROM v_ref_order_servis;

#6. VIEW UNTUK MENGECEK PERANGKAT

CREATE OR REPLACE VIEW v_ref_perangkat AS
SELECT 
    p.perangkat_id AS id,
    pel.nama AS nama_pemilik,
    p.imei_serial,
    p.merek,
    p.model,
    p.warna
FROM perangkat p
JOIN pelanggan pel ON pel.pelanggan_id = p.pelanggan_id


SELECT * FROM v_ref_order_servis;

#7. VIEW UNTUK MENGCEK STAF

CREATE OR REPLACE VIEW v_ref_staf AS
SELECT 
    staf_id AS id,
    nama,
    email,
    password,
    role
FROM staf;

SELECT * FROM v_ref_staf;

#8. VIEW UNTUK MENGECEK ESTIMASI

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
JOIN pelanggan pel ON pel.pelanggan_id = p.pelanggan_id


SELECT * FROM v_reF_estimasi;

#9. VIEW UNTUK MENGECEK TAGIHAN

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
JOIN pelanggan pel ON pel.pelanggan_id = p.pelanggan_id


SELECT * FROM v_ref_tagihan;

#10. VIEW UNTUK MENGECEK PEMBAYARAN

CREATE OR REPLACE VIEW v_ref_pembayaran AS
SELECT 
    pembayaran_id AS id,
    order_id,
    jumlah_bayar,
    metode,
    paid_at
FROM pembayaran


SELECT * FROM v_ref_pembayaran;

#11. VIEW UNTUK MENGECEK DIAGNOSIS

## VIEW TERBARU

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
JOIN staf s     ON s.staf_id = d.teknisi_id


SELECT * FROM v_ref_diagnosa;

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

CREATE OR REPLACE VIEW v_ref_order_sparepart AS
SELECT 
    os.order_id,
    os.sparepart_id,
    s.kode_sku,
    s.nama      AS nama_sparepart,
    os.jumlah   AS qty_digunakan,
    os.harga    AS harga_saat_itu,
    (os.jumlah * os.harga) AS subtotal,
    o.status    AS order_status,
    p.nama      AS nama_pelanggan
FROM order_sparepart os
JOIN sparepart s ON os.sparepart_id = s.sparepart_id
JOIN order_servis o ON os.order_id = o.order_id
JOIN perangkat pr ON o.perangkat_id = pr.perangkat_id
JOIN pelanggan p ON pr.pelanggan_id = p.pelanggan_id;

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														     # ----- GRANT ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
DROP USER IF EXISTS 'app' @'localhost';
CREATE USER IF NOT EXISTS 'app' @'localhost' IDENTIFIED BY '12345';

-- Auth & Staf Management
GRANT EXECUTE ON PROCEDURE LoginStaf TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE TambahStafBaru TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE EditStaf TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE HapusStaf TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE GetAllStaf TO 'app'@'localhost';

-- Master Data
GRANT EXECUTE ON PROCEDURE GetAllPelanggan TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE GetAllPerangkat TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE GetAllSparepart TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE UpsertStokSparepart TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE EditDataSparepart TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE HapusSparepart TO 'app'@'localhost';

-- Transaksi Order
GRANT EXECUTE ON PROCEDURE BukaOrderBaru TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE GetAllOrderServis TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE CancelOrder TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE SetRepairCompleted TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE GetAllOrderSparepart TO 'app'@'localhost';

-- Workflow: Diagnosa & Estimasi
GRANT EXECUTE ON PROCEDURE GetAllDiagnosa TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE SetDiagnosa TO 'app'@'localhost';

GRANT EXECUTE ON PROCEDURE GetAllEstimasi TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE SetEstimasi TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE ApproveEstimasi TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE TambahSparepartKeOrder TO 'app'@'localhost';

-- Finance: Tagihan & Pembayaran
GRANT EXECUTE ON PROCEDURE GetAllTagihan TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE GetTagihanDetail TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE HitungTagihanOrder TO 'app'@'localhost';

GRANT EXECUTE ON PROCEDURE GetAllPembayaran TO 'app'@'localhost';
GRANT EXECUTE ON PROCEDURE InputPembayaran TO 'app'@'localhost';

-- 3. Cek Grants
FLUSH PRIVILEGES;
SHOW GRANTS FOR 'app'@'localhost';
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- INDEX ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------
#1. TABEL STAF

-- Cari staf berdasarkan email (unik), role, dan ID
CREATE UNIQUE INDEX idx_staf_email ON staf(email);
CREATE INDEX idx_staf_role ON staf(role);

#2. TABEL PELANGGAN

-- Cari pelanggan lewat no_hp dan email
CREATE INDEX idx_pelanggan_nohp ON pelanggan(no_hp);
CREATE INDEX idx_pelanggan_email ON pelanggan(email);

#3. TABEL PERANGKAT

-- IMEI harus unik (sering dipakai saat input order)
CREATE UNIQUE INDEX idx_perangkat_imei ON perangkat(imei_serial);

-- Hubungan ke pelanggan
CREATE INDEX idx_perangkat_pelanggan ON perangkat(pelanggan_id);

#4. TABEL ORDER SERVIS

-- Foreign key lookup & pencarian cepat per status/order_id
CREATE INDEX idx_order_servis_perangkat ON order_servis(perangkat_id);
CREATE INDEX idx_order_servis_dibuatoleh ON order_servis(dibuat_oleh);
CREATE INDEX idx_order_servis_status ON order_servis(status);

#5. TABEL DIAGNOSA

CREATE INDEX idx_diagnosa_order ON diagnosa(order_id);
CREATE INDEX idx_diagnosa_teknisi ON diagnosa(teknisi_id);

#6. TABEL ESTIMASI

-- Estimasi sering diambil berdasarkan order_id DESC LIMIT 1
CREATE INDEX idx_estimasi_orderid_desc ON estimasi(order_id, estimasi_id DESC);
CREATE INDEX idx_estimasi_status ON estimasi(status);

#7. TABEL SPAREPART

-- SKU unik, pencarian by nama
CREATE UNIQUE INDEX idx_sparepart_sku ON sparepart(kode_sku);
CREATE INDEX idx_sparepart_nama ON sparepart(nama);

#8. TABEL ORDER SPAREPART

-- Digunakan untuk join antara order dan sparepart
CREATE INDEX idx_order_sparepart_orderid ON order_sparepart(order_id);
CREATE INDEX idx_order_sparepart_sparepartid ON order_sparepart(sparepart_id);

#9. TABEL ORDER TAGIHAN

-- Dihubungkan ke order_servis
CREATE UNIQUE INDEX idx_tagihan_orderid ON tagihan(order_id);
CREATE INDEX idx_tagihan_status ON tagihan(status_tagihan);

#10. TABEL PEMBAYARAN

-- Sering difilter berdasarkan order_id & tanggal
CREATE INDEX idx_pembayaran_orderid ON pembayaran(order_id);
CREATE INDEX idx_pembayaran_paidat ON pembayaran(paid_at);

---------------------------------------------------------------------------------------------------------------------------------------------------------------------
														# ----- SELESAI ------ #
---------------------------------------------------------------------------------------------------------------------------------------------------------------------


