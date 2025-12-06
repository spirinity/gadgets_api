import pool from "../../config/db.js";

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validasi input
    if (!email || !password) {
      return res.status(400).json({
        error: "Email dan password wajib diisi",
      });
    }

    const [rows] = await pool.query("CALL LoginStaf(?, ?)", [email, password]);

    const result = rows[0][0]; 

    // Cek apakah login berhasil
    if (result.status === "ERROR") {
      return res.status(401).json({
        error: result.message,
      });
    }

    // Login berhasil
    res.json({
      message: "Login berhasil",
      user: {
        staf_id: result.staf_id,
        nama: result.nama,
        role: result.role,
        email: result.email,
      },
    });
  } catch (err) {
    console.error("Error login:", err);
    res.status(500).json({
      error: "Terjadi kesalahan saat login",
      details: err.message,
    });
  }
};
