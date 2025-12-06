import pool from "../../config/db.js";


export const getAllSparepart = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllSparepart()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all sparepart:", err);
    res.status(500).json({
      error: "Gagal mengambil data sparepart",
      details: err.message,
    });
  }
};


export const upsertSparepart = async (req, res) => {
  try {
    const { kode_sku, nama, harga_satuan, tambah_qty } = req.body;

    // Validasi input
    if (!kode_sku || !tambah_qty) {
      return res.status(400).json({
        error: "kode_sku dan tambah_qty wajib diisi",
      });
    }

  
    const [rows] = await pool.query(
      "CALL UpsertStokSparepart(?, ?, ?, ?, @sparepart_id)",
      [kode_sku, nama || null, harga_satuan || null, tambah_qty]
    );


    const [output] = await pool.query("SELECT @sparepart_id as sparepart_id");

    res.status(201).json({
      message: "Sparepart berhasil ditambahkan/diupdate",
      sparepart_id: output[0].sparepart_id,
    });
  } catch (err) {
    console.error("Error upsert sparepart:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menambahkan/mengupdate sparepart",
      details: err.message,
    });
  }
};

export const editSparepart = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, harga_satuan, stok_baru } = req.body;

    // Panggil stored procedure
    await pool.query("CALL EditDataSparepart(?, ?, ?, ?)", [
      id,
      nama || null,
      harga_satuan || null,
      stok_baru || null,
    ]);

    res.json({
      message: "Sparepart berhasil diupdate",
    });
  } catch (err) {
    console.error("Error edit sparepart:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal mengupdate sparepart",
      details: err.message,
    });
  }
};


export const hapusSparepart = async (req, res) => {
  try {
    const { id } = req.params;

    // Panggil stored procedure
    await pool.query("CALL HapusSparepart(?)", [id]);

    res.json({
      message: "Sparepart berhasil dihapus",
    });
  } catch (err) {
    console.error("Error hapus sparepart:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menghapus sparepart",
      details: err.message,
    });
  }
};


export const getStokMenipis = async (req, res) => {
  try {
    // Query dari VIEW v_sparepart_stok_min (stok <= 3)
    const [rows] = await pool.query("SELECT * FROM v_sparepart_stok_min");
    res.json(rows);
  } catch (err) {
    console.error("Error get stok menipis:", err);
    res.status(500).json({
      error: "Gagal mengambil data sparepart stok menipis",
      details: err.message,
    });
  }
};
