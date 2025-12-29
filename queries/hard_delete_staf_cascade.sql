USE gadgets;

DELIMITER $$

-- =========================================================
-- 1. TRIGGER: BEFORE DELETE STAF (CASCADING LOGIC)
-- =========================================================
-- Trigger ini otomatis berjalan SEBELUM staf dihapus.
-- Tujuannya menghapus semua jejak data staf tersebut di tabel lain
-- agar tidak kena Foreign Key Constraint Fails.
DROP TRIGGER IF EXISTS trg_staf_before_delete$$
CREATE TRIGGER trg_staf_before_delete
BEFORE DELETE ON staf
FOR EACH ROW
BEGIN
    -- A. Hapus record Diagnosa yang dikerjakan teknisi ini
    DELETE FROM diagnosa WHERE teknisi_id = OLD.staf_id;

    -- B. Hapus Order Servis yang dibuat oleh staf ini
    -- NOTE: Ini akan memicu CASCADE DELETE ke seluruh tabel transaksi:
    -- (Estimasi, Tagihan, Pembayaran, Order_Sparepart) akan ikut terhapus otomatis!
    
    DELETE FROM order_servis WHERE dibuat_oleh = OLD.staf_id;
    
    -- Efek Samping: Trigger 'trg_order_sparepart_delete' akan jalan,
    -- mengembalikan stok sparepart ke gudang seolah order tidak pernah ada.
END$$

-- =========================================================
-- 2. PROCEDURE: HardDeleteStaf (EKSEKUTOR)
-- =========================================================
DROP PROCEDURE IF EXISTS HardDeleteStaf$$
CREATE PROCEDURE HardDeleteStaf(
    IN p_admin_id INT, -- ID Admin yang melakukan eksekusi
    IN p_target_id INT -- ID Staf yang akan dimusnahkan
)
BEGIN
    DECLARE v_admin_role VARCHAR(50);
    DECLARE v_exist INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    -- 1. Validasi: Pengeksekusi harus Admin
    SELECT role INTO v_admin_role FROM v_ref_staf WHERE id = p_admin_id;
    
    IF LOWER(v_admin_role) <> 'admin' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Hanya Role Admin yang berhak melakukan Hard Delete.';
    END IF;

    -- 2. Validasi: Jangan bunuh diri
    IF p_admin_id = p_target_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Anda tidak dapat menghapus akun sendiri.';
    END IF;

    -- 3. Validasi: Target harus ada
    SELECT COUNT(*) INTO v_exist FROM v_ref_staf WHERE id = p_target_id;
    IF v_exist = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Data staf tidak ditemukan.';
    END IF;

    START TRANSACTION;
        -- DELETE fisik. 
        -- Trigger 'trg_staf_before_delete' akan otomatis menyala di sini
        -- dan membersihkan semua data terkait sebelum baris ini hilang.
        DELETE FROM staf WHERE staf_id = p_target_id;
    COMMIT;
END$$

DELIMITER ;

GRANT EXECUTE ON PROCEDURE HardDeleteStaf TO 'app'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Dangerous Procedure HardDeleteStaf & Cascading Trigger CREATED.' AS Status;
