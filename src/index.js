import express from "express";
import dotenv from "dotenv";
import pool from "../config/db.js";
import authRoutes from "./routes/authRoutes.js";
import stafRoutes from "./routes/stafRoutes.js";
import sparepartRoutes from "./routes/sparepartRoutes.js";
import orderRoutes from "./routes/orderRoutes.js";
import diagnosaRoutes from "./routes/diagnosaRoutes.js";
import estimasiRoutes from "./routes/estimasiRoutes.js";
import tagihanRoutes from "./routes/tagihanRoutes.js";

dotenv.config();

const app = express();
app.use(express.json());

app.get("/", (req, res) => {
  res.json({
    message: "Welcome to Gadgets API",
    endpoints: {
      auth: "/api/auth/login",
      staf: "/api/staf",
      sparepart: "/api/sparepart",
      orders: "/api/orders",
      diagnosa: "/api/diagnosa",
      estimasi: "/api/estimasi",
      tagihan: "/api/tagihan",
      pembayaran: "/api/tagihan/pembayaran",
    },
  });
});


app.use("/api/auth", authRoutes); 
app.use("/api/staf", stafRoutes);
app.use("/api/sparepart", sparepartRoutes);
app.use("/api/orders", orderRoutes);
app.use("/api/diagnosa", diagnosaRoutes);
app.use("/api/estimasi", estimasiRoutes);
app.use("/api/tagihan", tagihanRoutes);


const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`Server running on http://localhost:${PORT}`)
);
