import express from "express";
import {
  getAllOrders,
  getAllPelanggan,
  getAllPerangkat,
  bukaOrderBaru,
  cancelOrder,
} from "../controllers/orderController.js";

const router = express.Router();

router.get("/", getAllOrders);

router.get("/pelanggan", getAllPelanggan);

router.get("/perangkat", getAllPerangkat);

router.post("/", bukaOrderBaru);

router.delete("/:id", cancelOrder);

export default router;
