import pool from "../../config/db.js";

export const getAllOrders = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllOrderServis()");
    res.status(200).json({
      message: "Data order berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all orders:", err);
    res.status(500).json({ message: "Gagal mengambil data order" });
  }
};


export const getAllPelanggan = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllPelanggan()");
    res.status(200).json({
      message: "Data pelanggan berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all pelanggan:", err);
    res.status(500).json({ message: "Gagal mengambil data pelanggan" });
  }
};


export const getAllPerangkat = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllPerangkat()");
    res.status(200).json({
      message: "Data perangkat berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all perangkat:", err);
    res.status(500).json({ message: "Gagal mengambil data perangkat" });
  }
};

export const bukaOrderBaru = async (req, res) => {
  try {
    // Ambil data dari body, staf_pembuat tidak perlu di-input user
    const { nama, no_hp, email, imei, merek, model, warna } = req.body;
    
    // Ambil ID staf dari Token JWT (req.user.id)
    const staf_pembuat = req.user.id;

    // Validasi input (tanpa cek staf_pembuat karena pasti ada dari token)
    if (!nama || !no_hp || !imei || !merek || !model) {
      return res.status(400).json({
        message: "Nama, no_hp, imei, merek, dan model wajib diisi",
      });
    }
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
      data: {
        order_id: output[0].order_id,
        input_by: staf_pembuat
      }
    });
  } catch (err) {
    console.error("Error buka order baru:", err);

    if (err.sqlState === "45000") {
      return res.status(400).json({
        message: err.sqlMessage,
      });
    }

    res.status(500).json({ message: "Gagal membuat order" });
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
        message: err.sqlMessage,
      });
    }

    res.status(500).json({
      message: "Gagal membatalkan order",
      details: err.message,
    });
  }
};
