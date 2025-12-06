import express from "express";
import {
  getAllStaf,
  tambahStaf,
  editStaf,
  hapusStaf,
} from "../controllers/stafController.js";

const router = express.Router();

router.get("/", getAllStaf);

router.post("/", tambahStaf);

router.put("/:id", editStaf);

router.delete("/:id", hapusStaf);

export default router;
