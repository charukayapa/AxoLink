import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../theme.dart';

enum PinMode { create, verify, change }

const _pinKey = 'user_pin';
const _storage = FlutterSecureStorage();

class PinScreen extends StatefulWidget {
  final PinMode mode;
  final VoidCallback onSuccess;
  final VoidCallback? onCancel;

  const PinScreen({super.key, required this.mode, required this.onSuccess, this.onCancel});

  /// Check if a PIN exists in secure storage
  static Future<bool> hasPin() async {
    if (kIsWeb) return false;
    final pin = await _storage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _pin = '';
  String _newPin = '';
  String _error = '';
  // step: 0 = verify current, 1 = enter new, 2 = confirm new
  late int _step;

  @override
  void initState() {
    super.initState();
    _step = widget.mode == PinMode.create ? 1 : 0;
  }

  void _onKeyPress(String digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin += digit;
      _error = '';
    });
    if (_pin.length == 4) {
      _processPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = '';
    });
  }

  Future<void> _processPin() async {
    await Future.delayed(const Duration(milliseconds: 120));

    try {
      if (widget.mode == PinMode.verify) {
        final stored = await _storage.read(key: _pinKey);
        if (_pin == stored) {
          widget.onSuccess();
        } else {
          setState(() { _error = 'Incorrect PIN. Please try again.'; _pin = ''; });
        }
      } else if (widget.mode == PinMode.change) {
        if (_step == 0) {
          final stored = await _storage.read(key: _pinKey);
          if (_pin == stored) {
            setState(() { _pin = ''; _error = ''; _step = 1; });
          } else {
            setState(() { _error = 'Incorrect current PIN.'; _pin = ''; });
          }
        } else if (_step == 1) {
          setState(() { _newPin = _pin; _pin = ''; _step = 2; });
        } else if (_step == 2) {
          if (_pin == _newPin) {
            await _storage.write(key: _pinKey, value: _pin);
            widget.onSuccess();
          } else {
            setState(() { _error = 'PINs do not match. Try again.'; _pin = ''; _newPin = ''; _step = 1; });
          }
        }
      } else if (widget.mode == PinMode.create) {
        if (_step == 1) {
          setState(() { _newPin = _pin; _pin = ''; _step = 2; });
        } else if (_step == 2) {
          if (_pin == _newPin) {
            await _storage.write(key: _pinKey, value: _pin);
            widget.onSuccess();
          } else {
            setState(() { _error = 'PINs do not match. Try again.'; _pin = ''; _newPin = ''; _step = 1; });
          }
        }
      }
    } catch (e) {
      setState(() { _error = 'Storage error: $e'; _pin = ''; });
    }
  }

  String get _title {
    if (widget.mode == PinMode.verify) return 'Enter PIN';
    if (widget.mode == PinMode.change && _step == 0) return 'Enter Current PIN';
    if (_step == 1) return 'Create 4-Digit PIN';
    return 'Confirm New PIN';
  }

  String get _subtitle {
    if (widget.mode == PinMode.verify) return 'Please enter your AxoLink PIN to continue.';
    if (widget.mode == PinMode.change && _step == 0) return 'Verify your identity to change the PIN.';
    if (_step == 1) return 'This PIN will be required to access the app.';
    return 'Enter the same PIN again to confirm.';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textMain)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(_subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14, color: AppColors.textSub)),
              ),
              const SizedBox(height: 40),

              // Dots
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) => Container(
                width: 14, height: 14,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _pin.length > i ? AppColors.accent : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(7),
                ),
              ))),
              const SizedBox(height: 20),

              // Error
              SizedBox(height: 20, child: _error.isNotEmpty
                ? Text(_error, style: const TextStyle(color: AppColors.danger, fontSize: 13))
                : null),
              const SizedBox(height: 20),

              // Numpad
              SizedBox(
                width: 280,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  children: [
                    for (int n = 1; n <= 9; n++) _keyButton(n.toString()),
                    _keyButton('', disabled: true),
                    _keyButton('0'),
                    _keyButton('⌫', isBackspace: true),
                  ],
                ),
              ),

              if (widget.onCancel != null) ...[
                const SizedBox(height: 40),
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSub, fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _keyButton(String label, {bool disabled = false, bool isBackspace = false}) {
    return SizedBox(
      width: 86,
      height: 86,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Material(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(40),
          child: InkWell(
            borderRadius: BorderRadius.circular(40),
            onTap: disabled ? null : () => isBackspace ? _onBackspace() : _onKeyPress(label),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: isBackspace ? 24 : 28,
                  color: disabled ? Colors.transparent : AppColors.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
