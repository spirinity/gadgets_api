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

    /* ==== Exception Handler ==== */
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

CREATE OR REPLACE PROCEDURE HapusStaf(
    IN p_admin_id INT,
    IN p_target_id INT
)
BEGIN
    DECLARE v_admin_role VARCHAR(50);
    DECLARE v_exist INT DEFAULT 0;

    /* ==== Exception Handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    /* ==== Cek apakah admin valid via VIEW ==== */
    SELECT role INTO v_admin_role
    FROM v_ref_staf
    WHERE id = p_admin_id;

    IF v_admin_role IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Admin tidak ditemukan';
    END IF;

    IF LOWER(v_admin_role) <> 'admin' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Hanya admin yang dapat menghapus staf';
    END IF;

    /* ==== Cek target staf ada via VIEW ==== */
    SELECT COUNT(*) INTO v_exist
    FROM v_ref_staf
    WHERE id = p_target_id;

    IF v_exist = 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Staf yang akan dihapus tidak ditemukan';
    END IF;

    /* ==== Eksekusi penghapusan ==== */
    START TRANSACTION;

      DELETE FROM staf
      WHERE staf_id = p_target_id;

    COMMIT;
END;

-- KASIR PROCEDURES

CREATE OR REPLACE PROCEDURE BukaOrderBaru (
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
    DECLARE v_imei_exist INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

      /* Validasi IMEI via VIEW */
      SELECT COUNT(*) INTO v_imei_exist FROM v_ref_perangkat WHERE imei_serial = p_imei;
      
      IF v_imei_exist > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'IMEI/Serial sudah terdaftar';
      END IF;

      /* Cek Pelanggan via VIEW */
      SELECT id
        INTO v_pelanggan_id
      FROM v_ref_pelanggan
      WHERE no_hp = p_no_hp
      LIMIT 1;

      /* Jika tidak ada di view, insert ke TABEL */
      IF v_pelanggan_id IS NULL THEN
        INSERT INTO pelanggan (nama, no_hp, email)
        VALUES (p_nama, p_no_hp, p_email);
        SET v_pelanggan_id = LAST_INSERT_ID();
      END IF;
      
      INSERT INTO perangkat (pelanggan_id, imei_serial, merek, model, warna)
      VALUES (v_pelanggan_id, p_imei, p_merek, p_model, p_warna);
      SET v_perangkat_id = LAST_INSERT_ID();

      INSERT INTO order_servis (perangkat_id, dibuat_oleh, status)
      VALUES (v_perangkat_id, p_staf_pembuat, 'Opened');
      SET o_order_id = LAST_INSERT_ID();

    COMMIT;
END;

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

CREATE OR REPLACE PROCEDURE HitungTagihanOrder(
    IN p_order_id INT
)
BEGIN
    DECLARE v_order_exist INT DEFAULT 0;
    DECLARE v_total_part  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_biaya_jasa  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_total_bill  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_paid        DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_tag_status  VARCHAR(20)   DEFAULT 'Unpaid';

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
    
      SET v_total_bill = fn_total_tagihan_order(p_order_id);

      -- 🧾 Buat atau perbarui tagihan
      INSERT INTO tagihan (order_id, status_tagihan, total_biaya)
      VALUES (p_order_id, 'Unpaid', v_total_bill)
      ON DUPLICATE KEY UPDATE total_biaya = VALUES(total_biaya);

      -- 🪙 Cek pembayaran via VIEW
      SELECT COALESCE(SUM(jumlah_bayar),0)
        INTO v_paid
      FROM v_ref_pembayaran
      WHERE order_id = p_order_id;

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
END;

CREATE OR REPLACE PROCEDURE InputPembayaran(
    IN p_order_id      INT,
    IN p_jumlah_bayar  DECIMAL(12,2),
    IN p_metode        VARCHAR(30)
)
BEGIN
    DECLARE v_has_order   INT DEFAULT 0;
    DECLARE v_has_tagihan INT DEFAULT 0;
    DECLARE v_total_bill  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_paid_total  DECIMAL(12,2) DEFAULT 0.00;
    DECLARE v_new_status  VARCHAR(20)   DEFAULT 'Unpaid';
    DECLARE v_order_status VARCHAR(50);

    /* ==== Exception Handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL; 
    END;

    -- 1️⃣ Validasi order via VIEW
    SELECT COUNT(*), MAX(status)
    INTO v_has_order, v_order_status
    FROM v_ref_order_servis
    WHERE id = p_order_id;

    IF NOT fn_cek_order(p_order_id) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
	END IF;

    -- 2️⃣ Pastikan jumlah bayar valid
    IF p_jumlah_bayar IS NULL OR p_jumlah_bayar <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'jumlah_bayar harus > 0';
    END IF;

    -- 3️⃣ Pastikan status order adalah "Ready for Pickup"
    IF v_order_status <> 'Ready for Pickup' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Order belum siap diambil. Hanya order dengan status Ready for Pickup yang dapat dibayar.';
    END IF;

    -- 4️⃣ Pastikan ada tagihan via VIEW
    SELECT COUNT(*) INTO v_has_tagihan
    FROM v_ref_tagihan
    WHERE order_id = p_order_id;

    IF v_has_tagihan = 0 THEN
        INSERT INTO tagihan (order_id, status_tagihan, total_biaya)
        VALUES (p_order_id, 'Unpaid', 0.00);
    END IF;

    START TRANSACTION;

      -- 5️⃣ Catat pembayaran
      INSERT INTO pembayaran (order_id, jumlah_bayar, metode)
      VALUES (p_order_id, p_jumlah_bayar, p_metode);

      -- 6️⃣ Hitung ulang total tagihan dan total bayar via VIEW
      SELECT total_biaya INTO v_total_bill
      FROM v_ref_tagihan
      WHERE order_id = p_order_id; -- Note: FOR UPDATE only works on Tables, so removed for View select

      SELECT COALESCE(SUM(jumlah_bayar), 0)
        INTO v_paid_total
      FROM v_ref_pembayaran
      WHERE order_id = p_order_id;

      -- 7️⃣ Tentukan status tagihan baru
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

      -- 8️⃣ Jika sudah Paid, ubah status order menjadi Closed
      IF v_new_status = 'Paid' THEN
          UPDATE order_servis
             SET status = 'Closed'
           WHERE order_id = p_order_id;
      END IF;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE CancelOrder (
    IN p_order_id INT
)
BEGIN
    DECLARE v_exists INT DEFAULT 0;
    DECLARE v_status VARCHAR(50);
    DECLARE v_tagihan_status VARCHAR(50);

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

      -- 2️⃣ Cek status
      IF v_status IN ('Closed', 'Cancelled') THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order sudah tidak dapat dibatalkan.';
      END IF;

      -- 3️⃣ Cek apakah sudah ada pembayaran penuh via VIEW
      SELECT status_tagihan INTO v_tagihan_status
      FROM v_ref_tagihan
      WHERE order_id = p_order_id
      LIMIT 1;

      IF v_tagihan_status = 'Paid' THEN
          SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order sudah dibayar penuh, tidak bisa dibatalkan.';
      END IF;

      -- 4️⃣ Update status order & tagihan
      UPDATE order_servis
      SET status = 'Cancelled'
      WHERE order_id = p_order_id;

      UPDATE tagihan
      SET status_tagihan = 'Cancelled'
      WHERE order_id = p_order_id;

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE UpsertStokSparepart(
    IN  p_kode_sku      VARCHAR(100),
    IN  p_nama          VARCHAR(150),
    IN  p_harga_satuan  DECIMAL(12,2),
    IN  p_tambah_qty    INT,
    OUT o_sparepart_id  INT
)
BEGIN
    DECLARE v_id INT;

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
        -- INSERT baru
        IF (p_nama IS NULL OR p_nama = '') OR p_harga_satuan IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'nama & harga_satuan wajib untuk SKU baru';
        END IF;

        INSERT INTO sparepart(kode_sku, nama, harga_satuan, stok_qty)
        VALUES (p_kode_sku, p_nama, p_harga_satuan, p_tambah_qty);
        SET v_id = LAST_INSERT_ID();
      ELSE
        -- UPDATE stok
        UPDATE sparepart
           SET stok_qty     = stok_qty + p_tambah_qty,
               nama         = COALESCE(p_nama, nama),
               harga_satuan = COALESCE(p_harga_satuan, harga_satuan)
         WHERE sparepart_id = v_id;
      END IF;
    COMMIT;

    SET o_sparepart_id = v_id;
END;

CREATE OR REPLACE PROCEDURE EditDataSparepart(
    IN p_sparepart_id  INT,
    IN p_nama          VARCHAR(150),
    IN p_harga_satuan  DECIMAL(12,2),
    IN p_stok_baru     INT
)
BEGIN
    DECLARE v_exist INT DEFAULT 0;

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

    IF p_stok_baru IS NOT NULL AND p_stok_baru < 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'stok_baru tidak boleh negatif';
    END IF;

    START TRANSACTION;

      UPDATE sparepart
      SET 
          nama         = COALESCE(p_nama, nama),
          harga_satuan = COALESCE(p_harga_satuan, harga_satuan),
          stok_qty     = COALESCE(p_stok_baru, stok_qty)
      WHERE sparepart_id = p_sparepart_id;

    COMMIT;
END;

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

CREATE OR REPLACE PROCEDURE TambahSparepartKeOrder(
    IN p_order_id      INT,
    IN p_sparepart_id  INT,
    IN p_jumlah        INT,
    IN p_harga_satuan  DECIMAL(12,2)
)
BEGIN
    DECLARE v_order_exist INT DEFAULT 0;
    DECLARE v_part_exist  INT DEFAULT 0;
    DECLARE v_status      VARCHAR(50);
    DECLARE v_price_use   DECIMAL(12,2);

    /* ==== Exception handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_jumlah IS NULL OR p_jumlah <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'jumlah harus > 0';
    END IF;

    /* Cek order via VIEW */
    SELECT COUNT(*), MAX(status)
    INTO v_order_exist, v_status
    FROM v_ref_order_servis
    WHERE id = p_order_id;

    IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
    END IF;

    IF v_status <> 'In Progress' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order belum berstatus In Progress';
    END IF;

    /* Cek sparepart via VIEW */
    SELECT COUNT(*) INTO v_part_exist
    FROM v_ref_sparepart
    WHERE id = p_sparepart_id;

    IF v_part_exist = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Sparepart tidak ditemukan';
    END IF;

    -- Ambil harga via VIEW
    IF p_harga_satuan IS NULL THEN
        SELECT harga_satuan INTO v_price_use
        FROM v_ref_sparepart WHERE id = p_sparepart_id;
    ELSE
        SET v_price_use = p_harga_satuan;
    END IF;

    START TRANSACTION;

      INSERT INTO order_sparepart (order_id, sparepart_id, jumlah, harga)
      VALUES (p_order_id, p_sparepart_id, p_jumlah, v_price_use)
      ON DUPLICATE KEY UPDATE
        jumlah = jumlah + VALUES(jumlah),
        harga  = COALESCE(VALUES(harga), harga);

    COMMIT;
END;

CREATE OR REPLACE PROCEDURE SetRepairCompleted(
    IN p_order_id INT,
    IN p_teknisi_id INT
)
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    DECLARE v_status VARCHAR(50);
    DECLARE v_is_teknisi INT DEFAULT 0;

    /* ==== Exception Handler ==== */
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45001'
            SET MESSAGE_TEXT = 'Terjadi kesalahan saat menandai perbaikan selesai.';
    END;

    START TRANSACTION;

      -- Cek order via VIEW
      SELECT COUNT(*), MAX(status)
      INTO v_exist, v_status
      FROM v_ref_order_servis
      WHERE id = p_order_id;

    IF NOT fn_cek_order(p_order_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Order tidak ditemukan';
	END IF;

      IF v_status NOT IN ('In Progress') THEN
          SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'Order belum dalam status In Progress, tidak bisa diselesaikan.';
      END IF;

      -- Cek teknisi via VIEW
      SELECT COUNT(*) INTO v_is_teknisi
      FROM v_ref_staf
      WHERE id = p_teknisi_id AND LOWER(role) = 'teknisi';

      IF v_is_teknisi = 0 THEN
          SIGNAL SQLSTATE '45000'
              SET MESSAGE_TEXT = 'User ini bukan teknisi.';
      END IF;

      UPDATE order_servis
         SET status = 'Ready for Pickup'
       WHERE order_id = p_order_id;

    COMMIT;
END;

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

CREATE OR REPLACE PROCEDURE GetAllStaf()
BEGIN
    START TRANSACTION;

    SELECT 
        id,
        nama,
        email,
        role
    FROM v_ref_staf
    ORDER BY role, nama;

    COMMIT;
END;

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
