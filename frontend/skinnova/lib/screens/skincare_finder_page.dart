import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SkincareFinderPage extends StatefulWidget {
  const SkincareFinderPage({super.key});

  @override
  State<SkincareFinderPage> createState() => _SkincareFinderPageState();
}

class _SkincareFinderPageState extends State<SkincareFinderPage> {
  static const Color whiteSmoke = Color(0xFFF7F4F3);
  static const Color wine = Color(0xFF5B2333);
  static const Color pageBg = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color softBorder = Color(0xFFF7F4F3);
  static const Color chipBg = Color(0xFFF7F4F3);
  static const Color textDark = Color(0xFF2A2A2A);
  static const Color mutedText = Color(0xFF5B2333);

  final List<String> routineSteps = [
    'Cleanser',
    'Oil Cleanser',
    'Toner',
    'Serum',
    'Moisturizer',
    'Sunscreen',
    'Eye Cream',
  ];

  final List<String> skinTypes = [
    'Dry',
    'Normal',
    'Combination',
    'Oily',
    'Sensitive',
  ];

  final List<String> concerns = [
    "Acne & Blemishes",
    "Blackheads",
    "Dark Spots",
    "Dryness",
    "Oiliness",
    "Redness",
    "Dullness",
    "Uneven Texture",
    "Visible Pores",
    "Dark Circles",
    "Puffiness",
    "Fine Lines & Wrinkles",
    "Loss of Firmness",
    "Sensitive Skin",
    "Dehydration",
  ];

  final Set<String> selectedSteps = {};
  final Set<String> selectedSkinTypes = {};
  final Set<String> selectedConcerns = {};

  void _toggleSelection(Set<String> selectedSet, String value) {
    setState(() {
      if (selectedSet.contains(value)) {
        selectedSet.remove(value);
      } else {
        selectedSet.add(value);
      }
    });
  }

  void _resetFilters() {
    setState(() {
      selectedSteps.clear();
      selectedSkinTypes.clear();
      selectedConcerns.clear();
    });
  }

  int get totalSelections =>
      selectedSteps.length + selectedSkinTypes.length + selectedConcerns.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: Row(
                children: [
                  _iconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'Skincare Finder',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.marcellus(
                            fontSize: 29,
                            color: wine,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Find products that match your skin needs',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: mutedText,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: _resetFilters,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: whiteSmoke,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: softBorder),
                      ),
                      child: Text(
                        'Reset',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: wine,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroCard(),
                    const SizedBox(height: 18),
                    _sectionContainer(
                      title: 'Routine Step',
                      subtitle: 'Choose the type of product you want',
                      child: _chipWrap(
                        items: routineSteps,
                        selectedItems: selectedSteps,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionContainer(
                      title: 'Skin Type',
                      subtitle: 'Pick the skin type you want products for',
                      child: _chipWrap(
                        items: skinTypes,
                        selectedItems: selectedSkinTypes,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _sectionContainer(
                      title: 'Skin Concern',
                      subtitle: 'Select the concerns you want to target',
                      child: _chipWrap(
                        items: concerns,
                        selectedItems: selectedConcerns,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: pageBg,
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'steps': selectedSteps.toList(),
                  'skinTypes': selectedSkinTypes.toList(),
                  'concerns': selectedConcerns.toList(),
                });
              },
              style: ElevatedButton.styleFrom(
                elevation: 0,
                backgroundColor: totalSelections == 0 ? whiteSmoke : wine,
                foregroundColor: totalSelections == 0 ? wine : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
              ),
              child: Text(
                totalSelections == 0
                    ? 'Show Products'
                    : 'Show Products ($totalSelections)',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: whiteSmoke,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: wine,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.search_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Build your match',
                  style: GoogleFonts.marcellus(
                    fontSize: 21,
                    color: wine,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a routine step, your skin type, and the concern you want to focus on. We’ll use that to show the most suitable products.',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    height: 1.5,
                    color: textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: whiteSmoke,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: softBorder),
        ),
        child: Icon(
          icon,
          size: 18,
          color: wine,
        ),
      ),
    );
  }

  Widget _sectionContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: softBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: wine.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.marcellus(
              fontSize: 23,
              color: wine,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _chipWrap({
    required List<String> items,
    required Set<String> selectedItems,
  }) {
    return Wrap(
      spacing: 10,
      runSpacing: 12,
      children: items.map((item) {
        final isSelected = selectedItems.contains(item);

        return GestureDetector(
          onTap: () => _toggleSelection(selectedItems, item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? wine : chipBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isSelected ? wine : softBorder,
                width: 1,
              ),
            ),
            child: Text(
              item,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : textDark,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
