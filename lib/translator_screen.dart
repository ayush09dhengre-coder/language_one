import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class TranslatorScreen extends StatefulWidget {
  const TranslatorScreen({super.key});

  @override
  State<TranslatorScreen> createState() => _TranslatorScreenState();
}

class _TranslatorScreenState extends State<TranslatorScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  String _translatedText = "";
  bool _isLoading = false;
  bool _isCopied = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _slideAnim;

  // Language list
  final List<Map<String, String>> _languages = [
    {"name": "English", "code": "en"},
    {"name": "Hindi", "code": "hi"},
    {"name": "Spanish", "code": "es"},
    {"name": "French", "code": "fr"},
    {"name": "German", "code": "de"},
    {"name": "Japanese", "code": "ja"},
    {"name": "Chinese", "code": "zh"},
    {"name": "Arabic", "code": "ar"},
    {"name": "Portuguese", "code": "pt"},
    {"name": "Russian", "code": "ru"},
    {"name": "Korean", "code": "ko"},
    {"name": "Italian", "code": "it"},
    {"name": "Turkish", "code": "tr"},
    {"name": "Dutch", "code": "nl"},
    {"name": "Gujarati", "code": "gu"},
    {"name": "Marathi", "code": "mr"},
    {"name": "Bengali", "code": "bn"},
    {"name": "Tamil", "code": "ta"},
    {"name": "Telugu", "code": "te"},
    {"name": "Urdu", "code": "ur"},
  ];

  String _fromLang = "en";
  String _toLang = "hi";

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _translate() async {
    if (_inputController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please enter text to translate"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _translatedText = "";
    });

    try {
      // Google Translate's public web endpoint — no API key needed,
      // and far more reliable/accurate than MyMemory's free tier
      // (which often returns garbled or HTML-entity-encoded text).
      // Note: this is an unofficial endpoint (used widely by free
      // translator apps), not an official Google Cloud API — it could
      // rate-limit under heavy use, but is solid for personal-project use.
      final url = Uri.parse(
        'https://translate.googleapis.com/translate_a/single'
            '?client=gtx&sl=$_fromLang&tl=$_toLang&dt=t'
            '&q=${Uri.encodeComponent(_inputController.text.trim())}',
      );
      final response = await http.get(url);
      final data = jsonDecode(response.body);

      // Response shape: [[[ "translated chunk", "original chunk", ...], ...], ...]
      // Long input gets split into multiple chunks — join them all.
      final translated = (data[0] as List)
          .map((chunk) => chunk[0] as String)
          .join();

      setState(() {
        _translatedText = translated.isEmpty ? "Translation failed" : translated;
        _isLoading = false;
      });
      _animController
        ..reset()
        ..forward();
    } catch (e) {
      setState(() {
        _translatedText = "Error: Check your internet connection";
        _isLoading = false;
      });
    }
  }

  void _swapLanguages() {
    setState(() {
      final temp = _fromLang;
      _fromLang = _toLang;
      _toLang = temp;
      // Also swap text
      final tempText = _inputController.text;
      _inputController.text = _translatedText;
      _translatedText = tempText;
    });
  }

  void _copyToClipboard() {
    if (_translatedText.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _translatedText));
    setState(() => _isCopied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isCopied = false);
    });
  }

  String _getLangName(String code) {
    return _languages.firstWhere(
          (l) => l['code'] == code,
      orElse: () => {"name": code},
    )['name']!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060D1A),
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100, right: -80,
            child: _blob(260, const Color(0xFF0D3B6E), 0.55),
          ),
          Positioned(
            bottom: -80, left: -60,
            child: _blob(220, const Color(0xFF0A4A35), 0.45),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),
                    const SizedBox(height: 28),

                    // Language Selector Row
                    _buildLanguageSelector(),
                    const SizedBox(height: 20),

                    // Input Card
                    _buildInputCard(),
                    const SizedBox(height: 16),

                    // Translate Button
                    _buildTranslateButton(),
                    const SizedBox(height: 20),

                    // Output Card
                    if (_translatedText.isNotEmpty || _isLoading)
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, _slideAnim.value),
                          child: Opacity(
                              opacity: _fadeAnim.value, child: child),
                        ),
                        child: _buildOutputCard(),
                      ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1E88E5).withOpacity(0.3)),
          ),
          child: const Icon(Icons.translate_rounded,
              color: Color(0xFF42A5F5), size: 26),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "LinguaX",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              "Translate across ${_languages.length} languages",
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLanguageSelector() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.09), width: 1.2),
          ),
          child: Row(
            children: [
              // From language
              Expanded(child: _langDropdown(_fromLang, (val) {
                setState(() => _fromLang = val!);
              })),

              // Swap button
              GestureDetector(
                onTap: _swapLanguages,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF00897B)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E88E5).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: Colors.white, size: 22),
                ),
              ),

              // To language
              Expanded(child: _langDropdown(_toLang, (val) {
                setState(() => _toLang = val!);
              })),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border:
        Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        dropdownColor: const Color(0xFF0E1E35),
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white38, size: 20),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        items: _languages.map((lang) {
          return DropdownMenuItem<String>(
            value: lang['code'],
            child: Text(
              lang['name']!,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInputCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withOpacity(0.09), width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                const EdgeInsets.only(left: 16, top: 12, right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.edit_outlined,
                        color: Colors.white24, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _getLangName(_fromLang),
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _inputController.clear(),
                      child: const Icon(Icons.close_rounded,
                          color: Colors.white24, size: 18),
                    ),
                  ],
                ),
              ),
              TextField(
                controller: _inputController,
                maxLines: 5,
                minLines: 3,
                style: const TextStyle(
                    color: Colors.white, fontSize: 17, height: 1.5),
                decoration: const InputDecoration(
                  hintText: "Enter text to translate...",
                  hintStyle:
                  TextStyle(color: Colors.white24, fontSize: 16),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslateButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _translate,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isLoading
                ? [const Color(0xFF1A3A6E), const Color(0xFF1A3A6E)]
                : [const Color(0xFF1565C0), const Color(0xFF00897B)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isLoading
              ? []
              : [
            BoxShadow(
              color: const Color(0xFF1E88E5).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
                color: Colors.white, strokeWidth: 2.5),
          )
              : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded,
                  color: Colors.white, size: 20),
              SizedBox(width: 10),
              Text(
                "Translate",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOutputCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF00897B).withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: const Color(0xFF00BFA5).withOpacity(0.2),
                width: 1.2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Output header
              Padding(
                padding: const EdgeInsets.only(
                    left: 16, top: 12, right: 16),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFF26A69A), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      _getLangName(_toLang),
                      style: const TextStyle(
                          color: Color(0xFF26A69A), fontSize: 13),
                    ),
                    const Spacer(),
                    // Copy button
                    GestureDetector(
                      onTap: _copyToClipboard,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _isCopied
                              ? const Color(0xFF00897B).withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _isCopied
                                ? const Color(0xFF00BFA5).withOpacity(0.4)
                                : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _isCopied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              color: _isCopied
                                  ? const Color(0xFF00BFA5)
                                  : Colors.white38,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isCopied ? "Copied!" : "Copy",
                              style: TextStyle(
                                color: _isCopied
                                    ? const Color(0xFF00BFA5)
                                    : Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Translated text
              Padding(
                padding: const EdgeInsets.all(16),
                child: _isLoading
                    ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF26A69A),
                    strokeWidth: 2,
                  ),
                )
                    : SelectableText(
                  _translatedText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    height: 1.6,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withOpacity(opacity), Colors.transparent],
        ),
      ),
    );
  }
}