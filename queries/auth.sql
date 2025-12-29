-- 1. Create User Khusus Aplikasi
DROP USER IF EXISTS 'app' @'localhost';
CREATE USER IF NOT EXISTS 'app' @'localhost' IDENTIFIED BY '12345';
FLUSH PRIVILEGES;

-- 2. Grant Permission (Hanya EXECUTE Procedure)

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
SHOW GRANTS FOR 'app'@'localhost';
