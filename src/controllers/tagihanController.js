import pool from "../../config/db.js";

// === TAGIHAN (BILLING) ===

export const getAllTagihan = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllTagihan()");
    res.status(200).json({
      message: "Data tagihan berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all tagihan:", err);
    res.status(500).json({ message: "Gagal mengambil data tagihan" });
  }
};

export const getTagihanDetail = async (req, res) => {
  try {
    const { order_id } = req.body; 

    if (!order_id) {
      return res.status(400).json({ message: "Order ID wajib diisi" });
    }

    const [rows] = await pool.query("CALL GetTagihanDetail(?)", [order_id]);
    res.status(200).json({
      message: "Detail tagihan berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get tagihan detail:", err);
    res.status(500).json({ message: "Gagal mengambil detail tagihan" });
  }
};

export const hitungTagihan = async (req, res) => {
  try {
    const { order_id } = req.body;

    if (!order_id) {
      return res.status(400).json({ message: "Order ID wajib diisi" });
    }

    const [rows] = await pool.query("CALL HitungTagihanOrder(?)", [order_id]);
    res.status(200).json({
      message: "Total tagihan berhasil dihitung",
      data: rows[0][0]
    });
  } catch (err) {
    console.error("Error hitung tagihan:", err);
    if (err.sqlState === "45000") {
      return res.status(400).json({ message: err.sqlMessage });
    }
    res.status(500).json({ message: "Gagal menghitung tagihan" });
  }
};

// === PEMBAYARAN (PAYMENT) ===

export const getAllPembayaran = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllPembayaran()");
    res.status(200).json({
      message: "Data pembayaran berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all pembayaran:", err);
    res.status(500).json({ message: "Gagal mengambil data pembayaran" });
  }
};

export const inputPembayaran = async (req, res) => {
  try {
    const { order_id, jumlah_bayar, metode } = req.body;
 

    // Validasi input
    if (!order_id || !jumlah_bayar || !metode) {
      return res.status(400).json({
        message: "Order ID, jumlah bayar, dan metode pembayaran wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL InputPembayaran(?, ?, ?)", [
      order_id,
      jumlah_bayar,
      metode,
    ]);

    res.status(201).json({ message: "Pembayaran berhasil diinput" });
  } catch (err) {
    console.error("Error input pembayaran:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({ message: err.sqlMessage });
    }

    res.status(500).json({ message: "Gagal menginput pembayaran" });
  }
};
