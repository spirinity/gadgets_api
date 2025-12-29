CREATE TRIGGER trg_order_sparepart_insert
AFTER INSERT ON order_sparepart
FOR EACH row	
BEGIN
  UPDATE sparepart
  SET stok_qty = stok_qty - NEW.jumlah
  WHERE sparepart_id = NEW.sparepart_id;
end;

CREATE TRIGGER trg_order_sparepart_delete
AFTER DELETE ON order_sparepart
FOR EACH ROW
BEGIN
  UPDATE sparepart
  SET stok_qty = stok_qty + OLD.jumlah
  WHERE sparepart_id = OLD.sparepart_id;
END;
