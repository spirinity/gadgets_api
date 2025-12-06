import pool from "../../config/db.js";

export const getAllOrders = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllOrderServis()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all orders:", err);
    res.status(500).json({
      error: "Gagal mengambil data order",
      details: err.message,
    });
  }
};


export const getAllPelanggan = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllPelanggan()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all pelanggan:", err);
    res.status(500).json({
      error: "Gagal mengambil data pelanggan",
      details: err.message,
    });
  }
};


export const getAllPerangkat = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllPerangkat()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all perangkat:", err);
    res.status(500).json({
      error: "Gagal mengambil data perangkat",
      details: err.message,
    });
  }
};

export const bukaOrderBaru = async (req, res) => {
  try {
    const { nama, no_hp, email, imei, merek, model, warna, staf_pembuat } =
      req.body;

    // Validasi input
    if (!nama || !no_hp || !imei || !merek || !model || !staf_pembuat) {
      return res.status(400).json({
        error:
          "Nama, no_hp, imei, merek, model, dan staf_pembuat wajib diisi",
      });
    }

    // Panggil stored procedure
    const [rows] = await pool.query(
      "CALL BukaOrderBaru(?, ?, ?, ?, ?, ?, ?, ?, @order_id)",
      [
        nama,
        no_hp,
        email || null,
        imei,
        merek,
        model,
        warna || null,
        staf_pembuat,
      ]
    );

    // Ambil output order_id
    const [output] = await pool.query("SELECT @order_id as order_id");

    res.status(201).json({
      message: "Order berhasil dibuat",
      order_id: output[0].order_id,
    });
  } catch (err) {
    console.error("Error buka order baru:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal membuat order",
      details: err.message,
    });
  }
};

/**
 * Cancel Order
 * DELETE /api/orders/:id
 */
export const cancelOrder = async (req, res) => {
  try {
    const { id } = req.params;

    // Panggil stored procedure
    await pool.query("CALL CancelOrder(?)", [id]);

    res.json({
      message: "Order berhasil dibatalkan",
    });
  } catch (err) {
    console.error("Error cancel order:", err);

    if (err.sqlState === "45000" || err.sqlState === "45001") {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal membatalkan order",
      details: err.message,
    });
  }
};
