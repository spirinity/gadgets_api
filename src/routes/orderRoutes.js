import express from "express";
import {
  getAllOrders,
  getAllPelanggan,
  getAllPerangkat,
  bukaOrderBaru,
  cancelOrder,
} from "../controllers/orderController.js";
import { isAuthenticated, isKasir } from "../middleware/auth.js";

const router = express.Router();

// Viewing allowed for all
router.get("/", isAuthenticated, getAllOrders);
router.get("/pelanggan", isAuthenticated, getAllPelanggan);
router.get("/perangkat", isAuthenticated, getAllPerangkat);

// Order creation and cancellation only for Kasir
router.post("/", isAuthenticated, isKasir, bukaOrderBaru);
router.put("/:id", isAuthenticated, isKasir, cancelOrder);

export default router;
