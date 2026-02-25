import 'package:flutter/material.dart';
import '../../../../constants.dart';

class LogInForm extends StatefulWidget {
  const LogInForm({
    super.key,
    required this.formKey,
    required this.onEmailChanged,
    required this.onPasswordChanged,
    this.emailController,
    this.passwordController,
  });

  final GlobalKey<FormState> formKey;
  final Function(String) onEmailChanged;
  final Function(String) onPasswordChanged;
  final TextEditingController? emailController;
  final TextEditingController? passwordController;

  @override
  State<LogInForm> createState() => _LogInFormState();
}

class _LogInFormState extends State<LogInForm> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: widget.emailController,
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
            controller: widget.passwordController,
            onChanged: widget.onPasswordChanged,
            onSaved: (pass) {
              // Password saved
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Password is required';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
            obscureText: !_isPasswordVisible,
            textInputAction: TextInputAction.done,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 0.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: 'PASSWORD',
              hintText: 'Enter your password',
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
