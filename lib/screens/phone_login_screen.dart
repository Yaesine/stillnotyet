// lib/screens/phone_login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:country_code_picker/country_code_picker.dart';
import '../providers/app_auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/components/app_button.dart';

class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({Key? key}) : super(key: key);

  @override
  _PhoneLoginScreenState createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String? _verificationId;
  String _selectedCountryCode = '+971'; // Default to UAE
  bool _useWhatsApp = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Make sure to properly format the phone number
      final phoneText = _phoneController.text.trim();
      final cleanPhone = phoneText.replaceAll(RegExp(r'[^\d]'), '');

      // Properly format the phone number with country code
      // Ensure no spaces or special characters between country code and number
      final phoneNumber = _selectedCountryCode + cleanPhone;

      print('Attempting to send OTP to: $phoneNumber');

      // Get auth provider
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);

      // Send OTP via SMS or WhatsApp
      _verificationId = await authProvider.sendOtp(
          phoneNumber,
          useWhatsApp: _useWhatsApp
      );

      if (_verificationId != null) {
        setState(() {
          _isOtpSent = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  _useWhatsApp
                      ? 'OTP sent to your WhatsApp'
                      : 'OTP sent to your phone number'
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          // Show the specific error message from the provider
          final errorMsg = authProvider.errorMessage ?? 'Failed to send OTP. Please try again.';

          // Check if it's a rate limit error
          final isRateLimitError = errorMsg.contains('too many') ||
              errorMsg.contains('blocked') ||
              errorMsg.contains('unusual activity');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: isRateLimitError ? SnackBarAction(
                label: 'Try WhatsApp',
                onPressed: () {
                  setState(() {
                    _useWhatsApp = true;
                    _isLoading = false;
                  });
                },
              ) : null,
            ),
          );

          // If it's a rate limit error, show the WhatsApp option more prominently
          if (isRateLimitError) {
            setState(() {
              _showWhatsAppBanner = true;
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _showWhatsAppBanner = false;

  Widget _buildWhatsAppBanner() {
    if (!_showWhatsAppBanner) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'SMS Verification Unavailable',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Due to security limits, SMS verification is temporarily unavailable. Please use WhatsApp verification instead.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _useWhatsApp = true;
                _showWhatsAppBanner = false;
              });
            },
            icon: const Icon(Icons.message, color: Colors.white),
            label: const Text('Use WhatsApp Verification'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }




  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate() || _verificationId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authProvider = Provider.of<AppAuthProvider>(context, listen: false);
      bool success = await authProvider.verifyOtp(_verificationId!, _otpController.text.trim());

      if (success && mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              // Title
              Text(
                _isOtpSent ? 'Verify your number' : 'My mobile',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                _isOtpSent
                    ? 'Enter the code sent to $_selectedCountryCode ${_phoneController.text}'
                    : 'Please enter your valid phone number. We will send you a code to verify your account.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 32),

              // Input field
              if (!_isOtpSent)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country code selector
                    // In lib/screens/phone_login_screen.dart
// Find and replace the CountryCodePicker builder with this version

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CountryCodePicker(
                        onChanged: (CountryCode countryCode) {
                          setState(() {
                            _selectedCountryCode = countryCode.dialCode ?? '+1';
                          });
                        },
                        initialSelection: 'AE',
                        favorite: const ['AE', 'US', 'GB', 'IN', 'SA'],
                        showCountryOnly: false,
                        showOnlyCountryWhenClosed: false,
                        alignLeft: true,
                        padding: EdgeInsets.zero,
                        builder: (code) {
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 8),
                              Container(
                                width: 30,
                                height: 30,
                                child: (code != null && code.flagUri != null)
                                    ? Image.asset(
                                  code.flagUri!,
                                  package: 'country_code_picker',
                                  width: 30,
                                  height: 30,
                                )
                                    : Container(),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                code?.dialCode ?? '+1',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_drop_down),
                              const SizedBox(width: 8),
                            ],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Phone number input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.phone, color: AppColors.primary),
                        labelText: 'Phone Number',
                        hintText: 'Enter your phone number without country code',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length < 6) {
                          return 'Please enter a valid phone number';
                        }
                        return null;
                      },
                    ),

                    // WhatsApp option
                    if (!_isOtpSent) ...[
                      // WhatsApp option toggle
                      Row(
                        children: [
                          Checkbox(
                            value: _useWhatsApp,
                            activeColor: AppColors.primary,
                            onChanged: (value) {
                              setState(() {
                                _useWhatsApp = value ?? false;
                              });
                            },
                          ),
                          const Text(
                            'Send code via WhatsApp instead of SMS',
                            style: TextStyle(fontSize: 14),
                          ),
                        ],
                      ),

                      // Show WhatsApp banner if needed
                      _buildWhatsAppBanner(),
                    ]
                  ],
                )
              else
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: 'Enter 6-digit OTP',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                    counterText: '',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the OTP';
                    }
                    if (value.length != 6) {
                      return 'Please enter a valid 6-digit OTP';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 32),

              // Action button
              AppButton(
                text: _isOtpSent ? 'VERIFY' : 'CONTINUE',
                onPressed: _isOtpSent ? _verifyOtp : _sendOtp,
                isLoading: _isLoading,
                isFullWidth: true,
                size: AppButtonSize.large,
                type: AppButtonType.primary,
                icon: _isOtpSent ? Icons.verified_user : Icons.send,
              ),

              if (_isOtpSent) ...[
                const SizedBox(height: 24),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Didn't receive code? ",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _sendOtp,
                        child: const Text(
                          'Resend OTP',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Change phone number option
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                      setState(() {
                        _isOtpSent = false;
                        _verificationId = null;
                        _otpController.clear();
                      });
                    },
                    child: const Text(
                      'Change Phone Number',
                      style: TextStyle(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}