import express from "express";
import {
  getAllTagihan,
  getTagihanDetail,
  hitungTagihan,
  getAllPembayaran,
  inputPembayaran,
} from "../controllers/tagihanController.js";

const router = express.Router();

router.get("/", getAllTagihan);

router.get("/detail", getTagihanDetail);

router.post("/", hitungTagihan);

router.get("/pembayaran", getAllPembayaran);

router.post("/pembayaran", inputPembayaran);

export default router;
