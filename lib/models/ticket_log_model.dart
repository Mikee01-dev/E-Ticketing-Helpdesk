import 'package:flutter/material.dart';

class TicketLogModel {
  final String id;
  final String ticketId;
  final String? statusFrom;
  final String statusTo;
  final String changedBy;
  final String? changedByName;
  final String? note;
  final DateTime createdAt;

  TicketLogModel({
    required this.id,
    required this.ticketId,
    this.statusFrom,
    required this.statusTo,
    required this.changedBy,
    this.changedByName,
    this.note,
    required this.createdAt,
  });

  factory TicketLogModel.fromMap(Map<String, dynamic> map) {
    // Handle joined profile data (jika ada join)
    String? changedByName;
    if (map['profiles'] != null) {
      changedByName = map['profiles']['name'];
    }
    // Jika tidak ada join, tampilkan ID saja
    if (changedByName == null && map['changed_by'] != null) {
      changedByName = map['changed_by'];
    }

    return TicketLogModel(
      id: map['id'] ?? '',
      ticketId: map['ticket_id'] ?? '',
      statusFrom: map['status_from'],
      statusTo: map['status_to'] ?? '',
      changedBy: map['changed_by'] ?? '',
      changedByName: changedByName,
      note: map['note'],
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_id': ticketId,
      'status_from': statusFrom,
      'status_to': statusTo,
      'changed_by': changedBy,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get statusFromText {
    if (statusFrom == null) return 'Created';
    switch (statusFrom) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return statusFrom!;
    }
  }

  String get statusToText {
    switch (statusTo) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return statusTo;
    }
  }

  String get actionText {
    if (statusFrom == null) {
      return 'Tiket dibuat';
    }
    return 'Status berubah dari $statusFromText menjadi $statusToText';
  }

  IconData get actionIcon {
    if (statusTo == 'open') return Icons.add_circle_outline;
    if (statusTo == 'in_progress') return Icons.play_circle_outline;
    if (statusTo == 'resolved') return Icons.check_circle_outline;
    if (statusTo == 'closed') return Icons.cancel;
    return Icons.update;
  }

  Color get actionColor {
    if (statusTo == 'open') return Colors.orange;
    if (statusTo == 'in_progress') return Colors.blue;
    if (statusTo == 'resolved') return Colors.green;
    if (statusTo == 'closed') return Colors.grey;
    return Colors.grey;
  }
}