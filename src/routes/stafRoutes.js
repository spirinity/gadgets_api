import express from "express";
import {
  getAllStaf,
  tambahStaf,
  editStaf,
  hapusStaf,
  hardDeleteStaf
} from "../controllers/stafController.js";
import { isAuthenticated, isAdmin } from "../middleware/auth.js";

const router = express.Router();

// Semua route staf hanya bisa diakses oleh Admin
router.get("/", isAuthenticated, isAdmin, getAllStaf);
router.post("/", isAuthenticated, isAdmin, tambahStaf);
router.patch("/:id", isAuthenticated, isAdmin, editStaf);
router.delete("/:id", isAuthenticated, isAdmin, hapusStaf);

router.delete("/hard/:id", isAuthenticated, isAdmin, hardDeleteStaf);

export default router;
