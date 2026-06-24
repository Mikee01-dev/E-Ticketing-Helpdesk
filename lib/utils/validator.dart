class Validator {
  // Validasi email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email tidak boleh kosong';
    }
    
    final emailRegex = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email tidak valid';
    }
    
    return null;
  }

  // Validasi password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password tidak boleh kosong';
    }
    
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    
    return null;
  }

  // Validasi konfirmasi password
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password tidak boleh kosong';
    }
    
    if (value != password) {
      return 'Password tidak cocok';
    }
    
    return null;
  }

  // Validasi nama
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nama tidak boleh kosong';
    }
    
    if (value.length < 3) {
      return 'Nama minimal 3 karakter';
    }
    
    return null;
  }

  // Validasi judul tiket
  static String? validateTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Judul tiket tidak boleh kosong';
    }
    
    if (value.length < 5) {
      return 'Judul minimal 5 karakter';
    }
    
    if (value.length > 100) {
      return 'Judul maksimal 100 karakter';
    }
    
    return null;
  }

  // Validasi deskripsi
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Deskripsi tidak boleh kosong';
    }
    
    if (value.length < 10) {
      return 'Deskripsi minimal 10 karakter';
    }
    
    if (value.length > 1000) {
      return 'Deskripsi maksimal 1000 karakter';
    }
    
    return null;
  }

  // Validasi komentar
  static String? validateComment(String? value) {
    if (value == null || value.isEmpty) {
      return 'Komentar tidak boleh kosong';
    }
    
    if (value.length > 500) {
      return 'Komentar maksimal 500 karakter';
    }
    
    return null;
  }

  // Validasi nomor telepon
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optional
    }
    
    final phoneRegex = RegExp(r'^[0-9]{10,13}$');
    
    if (!phoneRegex.hasMatch(value)) {
      return 'Nomor telepon tidak valid (10-13 digit)';
    }
    
    return null;
  }
}