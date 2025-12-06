import pool from "../../config/db.js";


export const getAllEstimasi = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllEstimasi()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all estimasi:", err);
    res.status(500).json({
      error: "Gagal mengambil data estimasi",
      details: err.message,
    });
  }
};


export const setEstimasi = async (req, res) => {
  try {
    const { order_id, biaya_jasa, biaya_sparepart, estimasi_kerja, status } =
      req.body;

    // Validasi input
    if (!order_id || biaya_jasa === undefined || biaya_sparepart === undefined || estimasi_kerja === undefined) {
      return res.status(400).json({
        error: "order_id, biaya_jasa, biaya_sparepart, dan estimasi_kerja wajib diisi",
      });
    }

    // Panggil stored procedure
    const [rows] = await pool.query(
      "CALL SetEstimasi(?, ?, ?, ?, ?, @estimasi_id)",
      [order_id, biaya_jasa, biaya_sparepart, estimasi_kerja, status || "Pending"]
    );

    // Ambil output estimasi_id
    const [output] = await pool.query("SELECT @estimasi_id as estimasi_id");

    res.status(201).json({
      message: "Estimasi berhasil disimpan",
      estimasi_id: output[0].estimasi_id,
    });
  } catch (err) {
    console.error("Error set estimasi:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menyimpan estimasi",
      details: err.message,
    });
  }
};

export const approveEstimasi = async (req, res) => {
  try {
    const { order_id, staf_id, keputusan } = req.body;

    // Validasi input
    if (!order_id || !staf_id || !keputusan) {
      return res.status(400).json({
        error: "order_id, staf_id, dan keputusan wajib diisi",
      });
    }

    // Validasi keputusan
    if (!["approve", "reject"].includes(keputusan.toLowerCase())) {
      return res.status(400).json({
        error: "Keputusan harus 'approve' atau 'reject'",
      });
    }

    // Panggil stored procedure
    const [rows] = await pool.query(
      "CALL ApproveEstimasi(?, ?, ?, @estimasi_id)",
      [order_id, staf_id, keputusan]
    );

    // Ambil output estimasi_id
    const [output] = await pool.query("SELECT @estimasi_id as estimasi_id");

    res.json({
      message: `Estimasi berhasil ${keputusan === "approve" ? "disetujui" : "ditolak"}`,
      estimasi_id: output[0].estimasi_id,
    });
  } catch (err) {
    console.error("Error approve estimasi:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal memproses estimasi",
      details: err.message,
    });
  }
};


export const tambahSparepartKeOrder = async (req, res) => {
  try {
    const { order_id, sparepart_id, jumlah, harga_satuan } = req.body;

    // Validasi input
    if (!order_id || !sparepart_id || !jumlah) {
      return res.status(400).json({
        error: "order_id, sparepart_id, dan jumlah wajib diisi",
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
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menambahkan sparepart ke order",
      details: err.message,
    });
  }
};

/**
 * Set Repair Completed
 * PUT /api/estimasi/complete
 * Body: { order_id, teknisi_id }
 */
export const setRepairCompleted = async (req, res) => {
  try {
    const { order_id, teknisi_id } = req.body;

    // Validasi input
    if (!order_id || !teknisi_id) {
      return res.status(400).json({
        error: "order_id dan teknisi_id wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL SetRepairCompleted(?, ?)", [order_id, teknisi_id]);

    res.json({
      message: "Perbaikan berhasil diselesaikan, order siap diambil",
    });
  } catch (err) {
    console.error("Error set repair completed:", err);

    if (err.sqlState === "45000" || err.sqlState === "45001") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menyelesaikan perbaikan",
      details: err.message,
    });
  }
};
