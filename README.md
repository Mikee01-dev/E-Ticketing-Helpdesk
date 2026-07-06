# 🎫 E-Ticketing Helpdesk

Aplikasi Mobile untuk manajemen tiket keluhan IT berbasis Flutter dengan backend Supabase.

## 📱 Tentang Aplikasi

E-Ticketing Helpdesk adalah sistem manajemen tiket keluhan yang memungkinkan pengguna untuk melaporkan masalah, dan tim helpdesk/admin untuk mengelola serta menyelesaikan tiket tersebut. Aplikasi ini dibangun menggunakan **Flutter** untuk frontend dan **Supabase** sebagai backend.

### ✨ Fitur Utama

| Role | Fitur |
|------|-------|
| **User** | Login, Register, Reset Password (OTP), Buat Tiket + Upload Gambar, Lihat Tiket, Detail Tiket, Komentar, Notifikasi, Statistik, Edit Profile, Dark Mode |
| **Helpdesk** | Login, Lihat Tiket Ditugaskan, Update Status, Komentar, Notifikasi, Statistik, Profile, Ganti Password |
| **Admin** | Login, Lihat Semua Tiket, Assign Tiket, Update Status, Hapus Tiket, Filter by Helpdesk, Kelola User (Ubah Role, Aktif/Nonaktif), Profile |

## 🛠️ Teknologi

| Komponen | Teknologi |
|----------|-----------|
| **Frontend** | Flutter 3.41.0 (Dart) |
| **State Management** | GetX |
| **Backend** | Supabase (PostgreSQL) |
| **Authentication** | Supabase Auth (JWT) |
| **Storage** | Supabase Storage |
| **Realtime** | Supabase Realtime |

## 📂 Struktur Folder

```
lib/
├── main.dart
├── bindings/          # GetX Dependency Injection
├── config/            # Konfigurasi (Supabase, Theme, Routes)
├── controllers/       # GetX Controllers
├── models/            # Data Models
├── screens/           # UI Screens
├── widgets/           # Reusable Widgets
└── utils/             # Helper Functions
```

## 🗄️ Database

Database menggunakan PostgreSQL di Supabase dengan tabel:

| Tabel | Deskripsi |
|-------|-----------|
| `profiles` | Data user (nama, role, avatar, phone) |
| `tickets` | Data tiket (judul, status, priority, kategori) |
| `comments` | Komentar pada tiket |
| `ticket_logs` | Riwayat perubahan status tiket |
| `notifications` | Notifikasi user |

### Trigger Database

- `set_ticket_number` - Auto generate nomor tiket (TCK-XXXXX)
- `log_ticket_status_change` - Auto insert ke riwayat saat status berubah
- `handle_new_user` - Auto create profile saat register


## 🔗 Link Penting

- [Flutter Documentation](https://docs.flutter.dev)
- [Supabase Documentation](https://supabase.com/docs)
- [GetX Documentation](https://pub.dev/packages/get)

## 👨‍💻 Pengembang

| Nama | NIM |
|------|-----|
| [Michael Putra Pratama Otemusu] | [434241029] |

## 📄 Lisensi

Copyright © 2026 - All Rights Reserved

---

## 🚀 Getting Started with Flutter

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
