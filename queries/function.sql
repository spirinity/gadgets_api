CREATE FUNCTION fn_cek_order(p_order_id INT) RETURNS BOOLEAN
BEGIN
    DECLARE v_exist INT DEFAULT 0;
    SELECT COUNT(*) INTO v_exist FROM order_servis WHERE order_id = p_order_id;
    RETURN (v_exist > 0);
END;

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

CREATE FUNCTION fn_sparepart_cek_stok(p_sparepart_id INT)
RETURNS INT
BEGIN
  DECLARE v_stok INT;
  SELECT stok_qty INTO v_stok
  FROM sparepart
  WHERE sparepart_id = p_sparepart_id
  LIMIT 1;
  RETURN v_stok;
end;

CREATE FUNCTION fn_total_omzet() RETURNS DECIMAL(14,2)
BEGIN
    DECLARE v DECIMAL(14,2);
    SELECT COALESCE(SUM(total_biaya),0) INTO v FROM tagihan;
    RETURN v;
END;
