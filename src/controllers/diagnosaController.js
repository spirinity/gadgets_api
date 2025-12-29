import pool from "../../config/db.js";


export const getAllDiagnosa = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllDiagnosa()");
    res.status(200).json({
      message: "Data diagnosa berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all diagnosa:", err);
    res.status(500).json({ message: "Gagal mengambil data diagnosa" });
  }
};

export const setDiagnosa = async (req, res) => {
  try {
    const { order_id, diagnosis } = req.body;
    // Teknisi ID diambil dari token login
    const teknisi_id = req.user.id;

    // Validasi input
    if (!order_id || !diagnosis) {
      return res.status(400).json({
        message: "Order ID dan diagnosis wajib diisi",
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
      data: {
        diagnosa_id: output[0].diagnosa_id
      }
    });
  } catch (err) {
    console.error("Error set diagnosa:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        message: err.sqlMessage,
      });
    }

    res.status(500).json({ message: "Gagal menyimpan diagnosa" });
  }
};

export const tambahSparepartKeOrder = async (req, res) => {
  try {
    const { order_id, sparepart_id, jumlah, harga_satuan } = req.body;

    // Validasi input
    if (!order_id || !sparepart_id || !jumlah) {
      return res.status(400).json({
        message: "Order ID, sparepart ID, dan jumlah wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL TambahSparepartKeOrder(?, ?, ?, ?)", [
      order_id,
      sparepart_id,
      jumlah,
      harga_satuan || null,
    ]);

    res.status(201).json({
      message: "Sparepart berhasil ditambahkan ke order",
    });
  } catch (err) {
    console.error("Error tambah sparepart ke order:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({ message: err.sqlMessage });
    }

    res.status(500).json({ message: "Gagal menambahkan sparepart ke order" });
  }
};
