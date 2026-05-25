import "package:flutter/material.dart";

class Segmented extends StatelessWidget {
  final List<String> items;
  final String value;
  final void Function(String v) onChanged;

  const Segmented({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((e) {
        final selected = e == value;
        return InkWell(
          onTap: () => onChanged(e),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF3A3750) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFF7D72FF) : const Color(0xFF3A3750),
              ),
            ),
            child: Text(
              e,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFFB9B7D0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
