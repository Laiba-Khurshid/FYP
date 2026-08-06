import 'app_constants.dart';

/// expected by [TextFormField.validator].
class Validators {
  Validators._();

  static final RegExp _emailRegex = RegExp(
    r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$',
  );

  // College/institutional email pattern can be tightened later once the
  // official domain is confirmed by the department.
  static final RegExp _nameRegex = RegExp(r'^[a-zA-Z\s\.]+$');

  /// Validates a required, non-empty text field.
  static String? validateRequired(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates an email address.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a password against minimum security requirements.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Password must be at least ${AppConstants.minPasswordLength} characters';
    }
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  /// Validates that [confirmValue] matches [originalValue].
  static String? validateConfirmPassword(String? confirmValue, String? originalValue) {
    if (confirmValue == null || confirmValue.isEmpty) {
      return 'Please confirm your password';
    }
    if (confirmValue != originalValue) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validates a person's full name.
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length > AppConstants.maxNameLength) {
      return 'Name is too long';
    }
    if (!_nameRegex.hasMatch(value.trim())) {
      return 'Name must contain letters only';
    }
    return null;
  }

  /// Validates a Pakistani mobile phone number (e.g. 03XXXXXXXXX).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^03\d{9}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number (e.g. 03XXXXXXXXX)';
    }
    return null;
  }

  /// Validates a free-text description field (e.g. complaint description).
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    if (value.trim().length > AppConstants.maxDescriptionLength) {
      return 'Description must be under ${AppConstants.maxDescriptionLength} characters';
    }
    return null;
  }

  /// Validates a lab number/name field against the department's 10 labs.
  static String? validateLabSelection(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a lab';
    }
    return null;
  }

  /// Generic numeric validator, useful for asset quantity fields.
  static String? validatePositiveNumber(String? value, {String fieldName = 'Value'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    final parsed = num.tryParse(value.trim());
    if (parsed == null) {
      return '$fieldName must be a valid number';
    }
    if (parsed <= 0) {
      return '$fieldName must be greater than zero';
    }
    return null;
  }

  // ================================================================
  // NEW METHODS FOR ASSET SCREEN (ADDED)
  // ================================================================

  /// Validates asset name field.
  static String? validateAssetName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an asset name';
    }
    if (value.trim().length < 2) {
      return 'Asset name must be at least 2 characters';
    }
    if (value.trim().length > 100) {
      return 'Asset name is too long (max 100 characters)';
    }
    return null;
  }

  /// Validates quantity field for assets.
  static String? validateQuantity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a quantity';
    }
    final int? quantity = int.tryParse(value.trim());
    if (quantity == null || quantity < 1) {
      return 'Quantity must be a positive number';
    }
    if (quantity > 10000) {
      return 'Quantity cannot exceed 10,000';
    }
    return null;
  }
}