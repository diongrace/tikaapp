/// Modele de ticket de support
class SupportTicket {
  final int id;
  final String subject;
  final String message;
  final String category;
  final String priority;
  final String status;
  final String? reference;
  final String? response;
  final String? respondedAt;
  final String createdAt;
  final String? updatedAt;

  SupportTicket({
    required this.id,
    required this.subject,
    required this.message,
    this.category = '',
    this.priority = 'normal',
    this.status = 'open',
    this.reference,
    this.response,
    this.respondedAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory SupportTicket.fromJson(Map<String, dynamic> json) {
    return SupportTicket(
      id: json['id'] ?? 0,
      subject: json['subject'] ?? json['title'] ?? '',
      message: json['message'] ?? json['description'] ?? json['content'] ?? '',
      category: json['category'] ?? json['type'] ?? '',
      priority: json['priority'] ?? 'normal',
      status: json['status'] ?? 'open',
      reference: json['reference'] ?? json['ticket_number'],
      response: json['response'] ?? json['reply'] ?? json['admin_response'],
      respondedAt: json['responded_at'] ?? json['replied_at'],
      createdAt: json['created_at'] ?? '',
      updatedAt: json['updated_at'],
    );
  }

  /// Label lisible du statut
  String get statusLabel {
    switch (status.toLowerCase()) {
      case 'open':
      case 'ouvert':
        return 'Ouvert';
      case 'in_progress':
      case 'en_cours':
        return 'En cours';
      case 'resolved':
      case 'resolu':
        return 'Resolu';
      case 'closed':
      case 'ferme':
        return 'Ferme';
      case 'pending':
      case 'en_attente':
        return 'En attente';
      default:
        return status;
    }
  }

  /// Couleur associee au statut (hex int)
  bool get isOpen => status.toLowerCase() == 'open' || status.toLowerCase() == 'ouvert';
  bool get isResolved => status.toLowerCase() == 'resolved' || status.toLowerCase() == 'resolu' || status.toLowerCase() == 'closed' || status.toLowerCase() == 'ferme';
  bool get isInProgress => status.toLowerCase() == 'in_progress' || status.toLowerCase() == 'en_cours';
}

/// Option de support (categorie, priorite, etc.)
class SupportOption {
  final List<String> categories;
  final List<String> priorities;
  final Map<String, String> categoryLabels;
  final Map<String, String> priorityLabels;

  SupportOption({
    required this.categories,
    required this.priorities,
    this.categoryLabels = const {},
    this.priorityLabels = const {},
  });

  factory SupportOption.fromJson(Map<String, dynamic> json) {
    final catResult = _parseOptions(json['categories'] ?? json['types'] ?? []);
    final prioResult = _parseOptions(json['priorities'] ?? ['normal', 'high', 'urgent']);

    return SupportOption(
      categories: catResult.$1,
      priorities: prioResult.$1,
      categoryLabels: catResult.$2,
      priorityLabels: prioResult.$2,
    );
  }

  /// Parse une liste d'options (string simple ou {value, label})
  static (List<String>, Map<String, String>) _parseOptions(dynamic value) {
    final values = <String>[];
    final labels = <String, String>{};

    if (value is List) {
      for (var e in value) {
        if (e is Map) {
          final v = e['value']?.toString() ?? '';
          final l = e['label']?.toString() ?? v;
          values.add(v);
          labels[v] = l;
        } else {
          final v = e.toString();
          values.add(v);
          labels[v] = v;
        }
      }
    } else if (value is Map) {
      for (var entry in value.entries) {
        final v = entry.key.toString();
        final l = entry.value.toString();
        values.add(v);
        labels[v] = l;
      }
    }

    return (values, labels);
  }

  String getCategoryLabel(String value) => categoryLabels[value] ?? value;
  String getPriorityLabel(String value) => priorityLabels[value] ?? value;
}
