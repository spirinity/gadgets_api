import pool from "../../config/db.js";

/**
 * Get All Staf
 * GET /api/staf
 */
export const getAllStaf = async (req, res) => {
  try {
    const [rows] = await pool.query("CALL GetAllStaf()");
    res.status(200).json({
      message: "Data staf berhasil diambil",
      data: rows[0]
    });
  } catch (err) {
    console.error("Error get all staf:", err);
    res.status(500).json({ message: "Gagal mengambil data staf" });
  }
};

export const tambahStaf = async (req, res) => {
  try {
    const { nama, email, password, role } = req.body;

    if (!nama || !email || !password || !role) {
      return res.status(400).json({ message: "Nama, email, password, dan role wajib diisi" });
    }

    await pool.query("CALL TambahStafBaru(?, ?, ?, ?)", [
      nama,
      email,
      password,
      role,
    ]);

    res.status(201).json({ message: "Staf berhasil ditambahkan" });
  } catch (err) {
    console.error("Error tambah staf:", err);
    
    if (err.sqlState === '45000') {
      return res.status(400).json({ message: err.sqlMessage });
    }
    res.status(500).json({ message: "Gagal menambahkan staf" });
  }
};

// Edit Staf (Admin Only)
export const editStaf = async (req, res) => {
  try {
    const { id } = req.params;
    const { nama, email, password, role } = req.body;
    const adminId = req.user.id; // ID Admin yang sedang login

    // Proteksi: Admin tidak boleh mengubah role dirinya sendiri lewat endpoint ini
    if (parseInt(id) === adminId && role && role.toLowerCase() !== 'admin') {
       return res.status(403).json({ 
        message: "Demi keamanan, Anda tidak diperbolehkan menurunkan Role akun sendiri." 
      });
    }

    await pool.query("CALL EditStaf(?, ?, ?, ?, ?)", [
      id,
      nama || null,
      email || null,
      password || null,
      role || null,
    ]);

    res.status(200).json({ message: "Data staf berhasil diupdate" });
  } catch (err) {
    console.error("Error edit staf:", err);
    if (err.sqlState === '45000') {
      return res.status(400).json({ message: err.sqlMessage });
    }
    res.status(500).json({ message: "Gagal mengupdate staf" });
  }
};

export const hapusStaf = async (req, res) => {
  try {
    const { id } = req.params;
    const admin_id = req.user.id; // Ambil dari token login

    if (!admin_id) {
       return res.status(401).json({ message: "Unauthorized" });
    }

    await pool.query("CALL HapusStaf(?, ?)", [admin_id, id]);

    res.status(200).json({ message: "Staf berhasil dinonaktifkan (Soft Delete)" });
  } catch (err) {
    console.error("Error hapus staf:", err);
    
    if (err.sqlState === '45000') {
      return res.status(400).json({ message: err.sqlMessage });
    }
    res.status(500).json({ message: "Gagal menghapus staf" });
  }
};

export const hardDeleteStaf = async (req, res) => {
  try {
    const { id } = req.params;
    const admin_id = req.user.id; 

    await pool.query("CALL HardDeleteStaf(?, ?)", [admin_id, id]);

    res.status(200).json({ message: "Staf dan seluruh datanya telah dihapus secara PERMANEN." });
  } catch (err) {
    console.error("Error hard delete staf:", err);
    
    if (err.sqlState === '45000') {
      return res.status(400).json({ message: err.sqlMessage });
    }
    res.status(500).json({ message: "Gagal melakukan hard delete staf" });
  }
};

export const updateMyProfile = async (req, res) => {
    try {
      const myId = req.user.id; // Dari Token JWT
      const { nama, email, password } = req.body;
  
      // Panggil SP khusus UpdateSelfStaf
      // Role tidak dikirim, karena user biasa tidak boleh ganti role sendiri
      await pool.query("CALL UpdateSelfStaf(?, ?, ?, ?)", [
        myId,
        nama || null,
        email || null,
        password || null
      ]);
  
      res.status(200).json({ message: "Profil berhasil diperbarui" });
    } catch (err) {
      console.error("Error update profile:", err);
      if (err.sqlState === '45000') {
        return res.status(400).json({ message: err.sqlMessage });
      }
      res.status(500).json({ message: "Gagal memperbarui profil" });
    }
  };

  export const editStafByAdmin = async (req, res) => {
    try {
      const { id } = req.params; // ID Target yang mau diedit
      const { nama, email, password, role } = req.body;
      const adminId = req.user.id; // ID Admin yang sedang login
  
      // Proteksi: Admin tidak boleh mengubah role dirinya sendiri lewat endpoint ini
      // (Opsional, karena di SP EditStaf mungkin belum ada logic ini, tapi bagus ditaruh di controller)
      if (parseInt(id) === adminId && role && role.toLowerCase() !== 'admin') {
         return res.status(403).json({ 
          message: "Demi keamanan, Anda tidak diperbolehkan menurunkan Role akun sendiri." 
        });
      }
  
      await pool.query("CALL EditStaf(?, ?, ?, ?, ?)", [
        id,
        nama || null,
        email || null,
        password || null,
        role || null,
      ]);
  
      res.status(200).json({ message: "Data staf berhasil diupdate oleh Admin" });
    } catch (err) {
      console.error("Error edit staf by admin:", err);
      if (err.sqlState === '45000') {
        return res.status(400).json({ message: err.sqlMessage });
      }
      res.status(500).json({ message: "Gagal mengupdate staf" });
    }
  };
