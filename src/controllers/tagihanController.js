import pool from "../../config/db.js";

export const getAllTagihan = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllTagihan()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all tagihan:", err);
    res.status(500).json({
      error: "Gagal mengambil data tagihan",
      details: err.message,
    });
  }
};


export const getTagihanDetail = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetTagihanDetail()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get tagihan detail:", err);
    res.status(500).json({
      error: "Gagal mengambil detail tagihan",
      details: err.message,
    });
  }
};


export const hitungTagihan = async (req, res) => {
  try {
    const { order_id } = req.body;

    // Validasi input
    if (!order_id) {
      return res.status(400).json({
        error: "order_id wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL HitungTagihanOrder(?)", [order_id]);

    res.status(201).json({
      message: "Tagihan berhasil dihitung",
    });
  } catch (err) {
    console.error("Error hitung tagihan:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menghitung tagihan",
      details: err.message,
    });
  }
};

/**
 * Get All Pembayaran
 * GET /api/pembayaran
 */
export const getAllPembayaran = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllPembayaran()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all pembayaran:", err);
    res.status(500).json({
      error: "Gagal mengambil data pembayaran",
      details: err.message,
    });
  }
};


export const inputPembayaran = async (req, res) => {
  try {
    const { order_id, jumlah_bayar, metode } = req.body;

    // Validasi input
    if (!order_id || !jumlah_bayar || !metode) {
      return res.status(400).json({
        error: "order_id, jumlah_bayar, dan metode wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL InputPembayaran(?, ?, ?)", [
      order_id,
      jumlah_bayar,
      metode,
    ]);

    res.status(201).json({
      message: "Pembayaran berhasil dicatat",
    });
  } catch (err) {
    console.error("Error input pembayaran:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal mencatat pembayaran",
      details: err.message,
    });
  }
};
