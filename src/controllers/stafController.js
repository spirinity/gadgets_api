import pool from "../../config/db.js";

/**
 * Get All Staf
 * GET /api/staf
 */
export const getAllStaf = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllStaf()");
    res.json(rows[0]);
  } catch (err) {
    console.error("Error get all staf:", err);
    res.status(500).json({
      error: "Gagal mengambil data staf",
      details: err.message,
    });
  }
};


export const tambahStaf = async (req, res) => {
  try {
    const { nama, email, password, role } = req.body;

    // Validasi input
    if (!nama || !email || !password || !role) {
      return res.status(400).json({
        error: "Nama, email, password, dan role wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL TambahStafBaru(?, ?, ?, ?)", [
      nama,
      email,
      password,
      role,
    ]);

    res.status(201).json({
      message: "Staf berhasil ditambahkan",
    });
  } catch (err) {
    console.error("Error tambah staf:", err);
    
    // Handle error dari stored procedure
    if (err.sqlState === '45000') {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menambahkan staf",
      details: err.message,
    });
  }
};

export const editStaf = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, email, password, role } = req.body;

    // Panggil stored procedure
    await pool.query("CALL EditStaf(?, ?, ?, ?, ?)", [
      id,
      nama || null,
      email || null,
      password || null,
      role || null,
    ]);

    res.json({
      message: "Staf berhasil diupdate",
    });
  } catch (err) {
    console.error("Error edit staf:", err);
    
    if (err.sqlState === '45000') {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal mengupdate staf",
      details: err.message,
    });
  }
};

export const hapusStaf = async (req, res) => {
  try {
    const { id } = req.params;
    const { admin_id } = req.body;

    if (!admin_id) {
      return res.status(400).json({
        error: "admin_id wajib diisi",
      });
    }

    // Panggil stored procedure
    await pool.query("CALL HapusStaf(?, ?)", [admin_id, id]);

    res.json({
      message: "Staf berhasil dihapus",
    });
  } catch (err) {
    console.error("Error hapus staf:", err);
    
    if (err.sqlState === '45000') {
      return res.status(400).json({
        error: err.sqlMessage,
      });
    }

    res.status(500).json({
      error: "Gagal menghapus staf",
      details: err.message,
    });
  }
};
