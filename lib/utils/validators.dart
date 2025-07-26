class Validators {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    // Sanitize input - remove any non-numeric characters except decimal point
    final sanitized = value.replaceAll(RegExp(r'[^\d.]'), '');
    
    final amount = double.tryParse(sanitized);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    if (amount > 1000000000) { // 1 billion limit
      return 'Amount exceeds maximum limit';
    }
    
    // Check for reasonable decimal places (max 2)
    if (sanitized.contains('.') && sanitized.split('.')[1].length > 2) {
      return 'Maximum 2 decimal places allowed';
    }
    
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Description is required';
    }
    
    // Sanitize input - remove potentially harmful characters
    final sanitized = value.replaceAll(RegExp(r'[<>"\']'), '');
    
    if (sanitized.length < 3) {
      return 'Description must be at least 3 characters';
    }
    
    if (sanitized.length > 100) {
      return 'Description must be less than 100 characters';
    }
    
    // Check for suspicious patterns
    if (RegExp(r'(script|javascript|eval|function)', caseSensitive: false).hasMatch(sanitized)) {
      return 'Invalid characters in description';
    }
    
    return null;
  }

  static String? validateCategory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please select a category';
    }
    
    return null;
  }
  
  static String? validateBudgetName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Budget name is required';
    }
    
    if (value.length < 2) {
      return 'Budget name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Budget name must be less than 50 characters';
    }
    
    return null;
  }
  
  static String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\']'), '') // Remove HTML/script chars
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();
  }
}