import pool from "../../config/db.js";


export const getAllEstimasi = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllEstimasi()");
    res.status(200).json({
      message: "Data estimasi berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all estimasi:", err);
    res.status(500).json({ message: "Gagal mengambil data estimasi" });
  }
};


export const setEstimasi = async (req, res) => {
  try {
    const { order_id, biaya_jasa, biaya_sparepart, estimasi_kerja, status } =
      req.body;

    // Validasi input
    if (!order_id || biaya_jasa === undefined || biaya_sparepart === undefined || estimasi_kerja === undefined) {
      return res.status(400).json({
        message: "Order ID, biaya_jasa, biaya_sparepart, dan estimasi_kerja wajib diisi",
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
      data: {
        estimasi_id: output[0].estimasi_id
      }
    });
  } catch (err) {
    console.error("Error set estimasi:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({ message: err.sqlMessage });
    }

    res.status(500).json({ message: "Gagal menyimpan estimasi" });
  }
};

export const approveEstimasi = async (req, res) => {
  try {
    const { order_id, keputusan } = req.body;
    // Staf ID (Kasir/Admin) diambil dari token
    const staf_id = req.user.id;

    // Validasi input
    if (!order_id || !keputusan) {
      return res.status(400).json({
        message: "Order ID dan keputusan wajib diisi",
      });
    }

    // Validasi keputusan
    if (!["approve", "reject"].includes(keputusan.toLowerCase())) {
      return res.status(400).json({
        message: "Keputusan harus 'approve' atau 'reject'",
      });
    }

    // Panggil stored procedure
    const [rows] = await pool.query(
      "CALL ApproveEstimasi(?, ?, ?, @estimasi_id)",
      [order_id, staf_id, keputusan]
    );

    // Ambil output estimasi_id
    const [output] = await pool.query("SELECT @estimasi_id as estimasi_id");

    res.status(200).json({
      message: `Estimasi berhasil ${keputusan.toLowerCase() === "approve" ? "disetujui" : "ditolak"}`,
      data: {
        estimasi_id: output[0].estimasi_id
      }
    });
  } catch (err) {
    console.error("Error approve estimasi:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({ message: err.sqlMessage });
    }

    res.status(500).json({ message: "Gagal memproses estimasi" });
  }
};


/**
 * Set Repair Completed
 * PUT /api/estimasi/complete
 * Body: { order_id, teknisi_id }
 */
export const setRepairCompleted = async (req, res) => {
  try {
    const { order_id } = req.body;
    // Teknisi ID diambil dari token
    const teknisi_id = req.user.id;

    // Validasi input
    if (!order_id) {
      return res.status(400).json({
        message: "Order ID wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL SetRepairCompleted(?, ?)", [order_id, teknisi_id]);

    res.status(200).json({ message: "Perbaikan berhasil diselesaikan, order siap diambil" });
  } catch (err) {
    console.error("Error set repair completed:", err);

    if (err.sqlState === "45000" || err.sqlState === "45001") {
      return res.status(400).json({ message: err.sqlMessage });
    }

    res.status(500).json({ message: "Gagal menyelesaikan perbaikan" });
  }
};
