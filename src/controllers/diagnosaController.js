import pool from "../../config/db.js";


export const getAllDiagnosa = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllDiagnosa()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all diagnosa:", err);
    res.status(500).json({
      error: "Gagal mengambil data diagnosa",
      details: err.message,
    });
  }
};

export const setDiagnosa = async (req, res) => {
  try {
    const { order_id, teknisi_id, diagnosis } = req.body;

    // Validasi input
    if (!order_id || !teknisi_id || !diagnosis) {
      return res.status(400).json({
        error: "order_id, teknisi_id, dan diagnosis wajib diisi",
      });
    }

    // Panggil stored procedure
    const [rows] = await pool.query(
      "CALL SetDiagnosa(?, ?, ?, @diagnosa_id)",
      [order_id, teknisi_id, diagnosis]
    );

    // Ambil output diagnosa_id
    const [output] = await pool.query("SELECT @diagnosa_id as diagnosa_id");

    res.status(201).json({
      message: "Diagnosa berhasil disimpan",
      diagnosa_id: output[0].diagnosa_id,
    });
  } catch (err) {
    console.error("Error set diagnosa:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menyimpan diagnosa",
      details: err.message,
    });
  }
};
