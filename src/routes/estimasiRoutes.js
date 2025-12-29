import express from "express";
import {
  getAllEstimasi,
  setEstimasi,
  approveEstimasi,
  setRepairCompleted,
} from "../controllers/estimasiController.js";
import { isAuthenticated, isTeknisi, isKasir } from "../middleware/auth.js";

const router = express.Router();

router.get("/", isAuthenticated, getAllEstimasi);

router.post("/", isAuthenticated, isTeknisi, setEstimasi);

router.post("/approve", isAuthenticated, isKasir, approveEstimasi);

router.put("/complete", isAuthenticated, isTeknisi, setRepairCompleted);

export default router;
