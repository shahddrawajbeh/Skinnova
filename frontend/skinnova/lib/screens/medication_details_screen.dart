import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../medication_model.dart';

class MedicationDetailsScreen extends StatelessWidget {
  final MedicationModel medication;

  const MedicationDetailsScreen({
    super.key,
    required this.medication,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                color: Colors.grey,
                onPressed: () => Navigator.pop(context),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              medication.name,
              style: GoogleFonts.poppins(
                fontSize: 25,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF202124),
              ),
            ),
            const SizedBox(height: 28),
            _sectionTitle("Sold as"),
            const SizedBox(height: 12),
            Text(
              medication.soldAs.isEmpty
                  ? "Not specified"
                  : medication.soldAs.join(", "),
              style: _bodyStyle(),
            ),
            const SizedBox(height: 28),
            _sectionTitle("Treats"),
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: medication.treats.map((item) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFFEDEDED),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    item,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xFF202124),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            _sectionTitle("Description"),
            const SizedBox(height: 12),
            Text(
              medication.description,
              style: _bodyStyle(),
            ),
            const SizedBox(height: 28),
            _sectionTitle("Medical Description"),
            const SizedBox(height: 12),
            Text(
              medication.medicalDescription,
              style: _bodyStyle(),
            ),
            const SizedBox(height: 28),
            _sectionTitle("References"),
            const SizedBox(height: 12),
            ...List.generate(medication.references.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  "${index + 1}. ${medication.references[index]}",
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xFF5B2333),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            Text(
              "Disclaimer: This information is intended to provide a general description of how the medication works. It is not medical advice. If you are considering using this medication, please consult a qualified healthcare professional in your country.",
              style: GoogleFonts.poppins(
                fontSize: 9,
                height: 1.5,
                fontStyle: FontStyle.italic,
                color: const Color(0xFF202124),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: const Color(0xFF202124),
      ),
    );
  }

  TextStyle _bodyStyle() {
    return GoogleFonts.poppins(
      fontSize: 16,
      height: 1.5,
      color: const Color(0xFF202124),
    );
  }
}
