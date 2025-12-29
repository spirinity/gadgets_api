import express from "express";
import {
  getAllTagihan,
  getTagihanDetail,
  hitungTagihan,
  getAllPembayaran,
  inputPembayaran,
} from "../controllers/tagihanController.js";
import { isAuthenticated, isKasir } from "../middleware/auth.js";

const router = express.Router();

router.get("/", isAuthenticated, isKasir, getAllTagihan);
router.get("/detail", isAuthenticated, isKasir, getTagihanDetail);
router.post("/", isAuthenticated, isKasir, hitungTagihan);
router.get("/pembayaran", isAuthenticated, isKasir, getAllPembayaran);
router.post("/pembayaran", isAuthenticated, isKasir, inputPembayaran);

export default router;
