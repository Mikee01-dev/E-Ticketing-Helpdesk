import 'package:flutter/material.dart';

class TicketModel {
  final String id;
  final String ticketNumber;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String? category;
  final String userId;
  final String? assignedTo;
  final String? assignedToName;
  final String? imageUrl;
  final String? userName;
  final DateTime createdAt;
  final DateTime updatedAt;

  TicketModel({
    required this.id,
    required this.ticketNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    this.category,
    required this.userId,
    this.assignedTo,
    this.assignedToName,
    this.imageUrl,
    this.userName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketModel.fromMap(Map<String, dynamic> map) {
    // Handle joined profile data (user)
    String? userName;
    if (map['profiles'] != null) {
      userName = map['profiles']['name'];
    } else if (map['profiles!tickets_user_id_fkey'] != null) {
      userName = map['profiles!tickets_user_id_fkey']['name'];
    }
    
    // Handle assigned_to profile data
    String? assignedToName;
    if (map['assigned_to_profile'] != null) {
      assignedToName = map['assigned_to_profile']['name'];
    }

    return TicketModel(
      id: map['id'] ?? '',
      ticketNumber: map['ticket_number'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'open',
      priority: map['priority'] ?? 'medium',
      category: map['category'],
      userId: map['user_id'] ?? '',
      assignedTo: map['assigned_to'],
      assignedToName: assignedToName,
      imageUrl: map['image_url'],
      userName: userName,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ticket_number': ticketNumber,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'user_id': userId,
      'assigned_to': assignedTo,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  String get statusText {
    switch (status) {
      case 'open': return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved': return 'Resolved';
      case 'closed': return 'Closed';
      default: return status;
    }
  }

  String get priorityText {
    switch (priority) {
      case 'low': return 'Low';
      case 'medium': return 'Medium';
      case 'high': return 'High';
      case 'urgent': return 'Urgent';
      default: return priority;
    }
  }

  Color get statusColor {
    switch (status) {
      case 'open': return Colors.orange;
      case 'in_progress': return Colors.blue;
      case 'resolved': return Colors.green;
      case 'closed': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color get priorityColor {
    switch (priority) {
      case 'low': return Colors.green;
      case 'medium': return Colors.orange;
      case 'high': return Colors.red;
      case 'urgent': return Colors.purple;
      default: return Colors.grey;
    }
  }

  bool get isOpen => status == 'open';
  bool get isInProgress => status == 'in_progress';
  bool get isResolved => status == 'resolved';
  bool get isClosed => status == 'closed';
  
  // Apakah tiket sudah diassign?
  bool get isAssigned => assignedTo != null;
}