import express from "express";
import {
  getAllEstimasi,
  setEstimasi,
  approveEstimasi,
  tambahSparepartKeOrder,
  setRepairCompleted,
} from "../controllers/estimasiController.js";

const router = express.Router();

/**
 * GET /api/estimasi
 * Mengambil semua estimasi
 */
router.get("/", getAllEstimasi);

/**
 * POST /api/estimasi
 * Set estimasi untuk order
 * Body: { order_id, biaya_jasa, biaya_sparepart, estimasi_kerja, status }
 */
router.post("/", setEstimasi);

/**
 * POST /api/estimasi/approve
 * Approve atau reject estimasi
 * Body: { order_id, staf_id, keputusan }
 */
router.post("/approve", approveEstimasi);

/**
 * POST /api/estimasi/sparepart
 * Tambah sparepart ke order (saat perbaikan)
 * Body: { order_id, sparepart_id, jumlah, harga_satuan }
 */
router.post("/sparepart", tambahSparepartKeOrder);

/**
 * PUT /api/estimasi/complete
 * Tandai perbaikan selesai
 * Body: { order_id, teknisi_id }
 */
router.put("/complete", setRepairCompleted);

export default router;
