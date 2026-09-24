import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? maxLength;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool readOnly;

  const AppTextField({
    super.key,
    this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.maxLength,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
  });

  const AppTextField.email({
    super.key,
    this.controller,
    this.labelText = 'Email',
    this.hintText = 'Enter your email',
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
  }) : obscureText = false,
       keyboardType = TextInputType.emailAddress,
       textInputAction = TextInputAction.next,
       inputFormatters = null,
       maxLines = 1,
       maxLength = null,
       prefixIcon = const Icon(Icons.email_outlined),
       suffixIcon = null;

  const AppTextField.password({
    super.key,
    this.controller,
    this.labelText = 'Password',
    this.hintText = 'Enter your password',
    this.errorText,
    this.enabled = true,
    this.onChanged,
    this.onEditingComplete,
    this.onSubmitted,
    this.validator,
    this.focusNode,
    this.autofocus = false,
    this.readOnly = false,
  }) : obscureText = true,
       keyboardType = TextInputType.visiblePassword,
       textInputAction = TextInputAction.done,
       inputFormatters = null,
       maxLines = 1,
       maxLength = null,
       prefixIcon = const Icon(Icons.lock_outlined),
       suffixIcon = null;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscureText,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      autofocus: widget.autofocus,
      onChanged: widget.onChanged,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        errorText: widget.errorText,
        prefixIcon: widget.prefixIcon,
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : widget.suffixIcon,
      ),
    );
  }
}
