import express from "express";
import {
  getAllSparepart,
  upsertSparepart,
  editSparepart,
  hapusSparepart,
  getStokMenipis,
} from "../controllers/sparepartController.js";

const router = express.Router();

router.get("/", getAllSparepart);

router.get("/stok-menipis", getStokMenipis);

router.post("/", upsertSparepart);

router.put("/:id", editSparepart);

router.delete("/:id", hapusSparepart);

export default router;
