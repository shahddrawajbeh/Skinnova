const express = require("express");
const router = express.Router();
const Medication = require("../models/Medication");

router.get("/condition/:condition", async (req, res) => {
  try {
    const condition = req.params.condition;

    const medications = await Medication.find({
      isActive: true,
      treats: { $regex: new RegExp(`^${condition}$`, "i") },
    }).sort({ name: 1 });

    res.json(medications);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get("/:id", async (req, res) => {
  try {
    const medication = await Medication.findById(req.params.id);

    if (!medication) {
      return res.status(404).json({ message: "Medication not found" });
    }

    res.json(medication);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

module.exports = router;