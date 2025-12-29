import jwt from "jsonwebtoken";

const SECRET_KEY = process.env.JWT_SECRET || "gadget_service_super_rahasia";

export const isAuthenticated = (req, res, next) => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1]; 

  if (!token) {
    return res.status(401).json({ error: "Akses ditolak. Token tidak ditemukan." });
  }

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) {
      return res.status(403).json({ error: "Token tidak valid atau kadaluarsa." });
    }
    req.user = user;
    next();
  });
};
  
export const isAdmin = (req, res, next) => {
  if (req.user && req.user.role.toLowerCase() === "admin") {
    return next();
  }
  return res.status(403).json({ message: "Forbidden. Hanya Admin yang dapat mengakses" });
};

export const isKasir = (req, res, next) => {
  if (req.user && req.user.role.toLowerCase() === "kasir") {
    return next();
  }
  return res.status(403).json({ message: "Forbidden. Hanya Kasir yang dapat mengakses" });
};

export const isTeknisi = (req, res, next) => {
  if (req.user && req.user.role.toLowerCase() === "teknisi") {
    return next();
  }
  return res.status(403).json({ message: "Forbidden. Hanya Teknisi yang dapat mengakses" });
};
