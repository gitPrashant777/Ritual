import 'package:flutter/material.dart';
import '../../../../constants.dart';

class SignUpForm extends StatefulWidget {
  const SignUpForm({
    super.key,
    required this.formKey,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    required this.onNameChanged,
  });

  final GlobalKey<FormState> formKey;
  final Function(String) onEmailChanged;
  final Function(String) onPasswordChanged;
  final Function(String) onNameChanged;

  @override
  State<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<SignUpForm> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Full Name Field
          TextFormField(
            onChanged: widget.onNameChanged,
            onSaved: (name) {
              // Name saved
            },
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'FULL NAME',
              hintText: 'Enter your full name',
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              hintStyle: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white30 : Colors.black26,
                letterSpacing: 0.3,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : const Color(0xFF0F2E1A

),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Email Field
          TextFormField(
            onChanged: widget.onEmailChanged,
            onSaved: (email) {
              // Email saved
            },
            validator: emaildValidator.call,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'EMAIL',
              hintText: 'Enter your email',
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              hintStyle: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white30 : Colors.black26,
                letterSpacing: 0.3,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : const Color(0xFF0F2E1A

),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Password Field
          TextFormField(
            onChanged: widget.onPasswordChanged,
            onSaved: (pass) {
              // Password saved
            },
            validator: passwordValidator.call,
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'PASSWORD',
              hintText: 'Create a password',
              labelStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
              hintStyle: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white30 : Colors.black26,
                letterSpacing: 0.3,
              ),
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 20,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: isDark ? Colors.white38 : Colors.black38,
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
                tooltip: _isPasswordVisible ? 'Hide password' : 'Show password',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white12 : Colors.black12,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide(
                  color: isDark ? Colors.white : const Color(0xFF0F2E1A

),
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
