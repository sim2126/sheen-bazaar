import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import 'search_results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final q = _ctrl.text.trim();
    if (q.isEmpty) return;
    Navigator.push(context, fadeSlideRoute(SearchResultsScreen(query: q)));
  }

  void _fillAndSubmit(String suggestion) {
    _ctrl.text = suggestion;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.walnut,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.walnutDeep,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What are you\nlooking for?',
                style: AppTextStyles.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Search by product name or description.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.stone,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 28),

              // ── Search bar ───────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      onSubmitted: (_) => _submit(),
                      style: const TextStyle(
                        color: AppColors.cream,
                        fontSize: 16,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g. Pashmina shawl, copper bowl…',
                        prefixIcon: Icon(
                          Icons.search,
                          color: AppColors.terracotta,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: AppColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: AppColors.cream,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // ── Suggestions ──────────────────────────────────────────────
              Text('Try searching for…', style: AppTextStyles.caption),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip('Pashmina shawl', _fillAndSubmit),
                  _Chip('Papier Mache box', _fillAndSubmit),
                  _Chip('Walnut wood carving', _fillAndSubmit),
                  _Chip('Copper bowl', _fillAndSubmit),
                  _Chip('Silk carpet', _fillAndSubmit),
                  _Chip('Silver jewellery', _fillAndSubmit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final void Function(String) onTap;
  const _Chip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.stoneLight),
        ),
      ),
    );
  }
}
