import pool from "../../config/db.js";
import jwt from "jsonwebtoken";

const SECRET_KEY = process.env.JWT_SECRET || "gadget_service_super_rahasia";

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: "Email dan password wajib diisi" });
    }

    const [rows] = await pool.query("CALL LoginStaf(?, ?)", [email, password]);

    const result = rows[0][0]; 

    if (!result || result.status === "ERROR") {
      return res.status(401).json({ 
        message: result ? result.message : "Email atau password salah" 
      });
    }

    const payload = {
      id: result.staf_id,
      nama: result.nama,
      role: result.role,
      email: result.email,
    };

    const token = jwt.sign(payload, SECRET_KEY, { expiresIn: "24h" });

    return res.status(200).json({
      message: "Login berhasil",
      data: {
        token,
        user: payload,
      }
    });
  } catch (err) {
    console.error("Error login:", err);
    return res.status(500).json({ message: "Terjadi kesalahan saat login" });
  }
};
