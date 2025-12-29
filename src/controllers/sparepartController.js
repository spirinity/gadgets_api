import pool from "../../config/db.js";


// === GET DATA ===

export const getAllSparepart = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllSparepart()");
    res.status(200).json({
      message: "Data sparepart berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all sparepart:", err);
    res.status(500).json({ message: "Gagal mengambil data sparepart" });
  }
};

export const getAllOrderSparepart = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllOrderSparepart()");
    res.status(200).json({
      message: "Data riwayat penggunaan sparepart berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all order sparepart:", err);
    res.status(500).json({ message: "Gagal mengambil data riwayat sparepart" });
  }
};


export const upsertSparepart = async (req, res) => {
  try {
    const { kode_sku, nama, harga_satuan, tambah_qty } = req.body;

    // Validasi input
    if (!kode_sku || !tambah_qty) {
      return res.status(400).json({
        message: "kode_sku dan tambah_qty wajib diisi",
      });
    }

    const [rows] = await pool.query(
      "CALL UpsertStokSparepart(?, ?, ?, ?, @sparepart_id)",
      [kode_sku, nama || null, harga_satuan || null, tambah_qty]
    );

    const [output] = await pool.query("SELECT @sparepart_id as sparepart_id");

    res.status(201).json({
      message: "Sparepart berhasil ditambahkan/diupdate",
      data: {
         sparepart_id: output[0].sparepart_id
      }
    });
  } catch (err) {
    console.error("Error upsert sparepart:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        message: err.sqlMessage,
      });
    }

    res.status(500).json({ message: "Gagal menambahkan/mengupdate sparepart" });
  }
};

export const editSparepart = async (req, res) => {
  try {
    const { id } = req.params;
    const { kode_sku, nama, harga_satuan, stok_baru } = req.body;

    // Panggil stored procedure
    await pool.query("CALL EditDataSparepart(?, ?, ?, ?, ?)", [
      id,
      kode_sku || null,
      nama || null,
      harga_satuan || null,
      stok_baru || null,
    ]);

    res.status(200).json({ message: "Sparepart berhasil diupdate" });
  } catch (err) {
    console.error("Error edit sparepart:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({ message: err.sqlMessage });
    }

    res.status(500).json({ message: "Gagal mengupdate sparepart" });
  }
};






