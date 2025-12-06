import express from "express";
import { getAllDiagnosa, setDiagnosa } from "../controllers/diagnosaController.js";

const router = express.Router();

router.get("/", getAllDiagnosa);

router.post("/", setDiagnosa);

export default router;
    