import express from "express";
import {
  getAllSparepart,
  getAllOrderSparepart,
  upsertSparepart,
  editSparepart,
} from "../controllers/sparepartController.js";
import { isAuthenticated, isKasir } from "../middleware/auth.js";

const router = express.Router();

// Viewing allowed for all authenticated staff
router.get("/", isAuthenticated, getAllSparepart);
router.get("/orders", isAuthenticated, getAllOrderSparepart); // Riwayat Penggunaan

// Modification only for Admin
router.post("/", isAuthenticated, isKasir, upsertSparepart);
router.put("/:id", isAuthenticated, isKasir, editSparepart);

export default router;
