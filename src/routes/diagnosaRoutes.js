import express from "express";
import { getAllDiagnosa, setDiagnosa, tambahSparepartKeOrder } from "../controllers/diagnosaController.js";
import { isAuthenticated, isTeknisi } from "../middleware/auth.js";

const router = express.Router();

router.get("/", isAuthenticated, getAllDiagnosa);
router.post("/", isAuthenticated, isTeknisi, setDiagnosa);
// Tambah sparepart adalah bagian dari diagnosa/repair teknisi
router.post("/sparepart", isAuthenticated, isTeknisi, tambahSparepartKeOrder);

export default router;
    