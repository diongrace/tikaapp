import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../services/support_service.dart';
import '../../../services/models/support_model.dart';

/// Ecran de detail d'un ticket de support
class SupportTicketDetailScreen extends StatefulWidget {
  final int ticketId;

  const SupportTicketDetailScreen({super.key, required this.ticketId});

  @override
  State<SupportTicketDetailScreen> createState() => _SupportTicketDetailScreenState();
}

class _SupportTicketDetailScreenState extends State<SupportTicketDetailScreen> {
  SupportTicket? _ticket;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTicket();
  }

  Future<void> _loadTicket() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final ticket = await SupportService.getTicketDetail(widget.ticketId);
      if (mounted) setState(() { _ticket = ticket; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  // Couleurs du gradient selon le statut
  List<Color> _getGradientColors(SupportTicket ticket) {
    if (ticket.isResolved) return [const Color(0xFF4CAF50), const Color(0xFF388E3C)];
    if (ticket.isInProgress) return [const Color(0xFF2196F3), const Color(0xFF1565C0)];
    return [const Color(0xFFFBBF24), const Color(0xFFEA580C)]; // Open = orange/amber
  }

  Color _getStatusColor(SupportTicket ticket) {
    if (ticket.isResolved) return const Color(0xFF4CAF50);
    if (ticket.isInProgress) return const Color(0xFF2196F3);
    return const Color(0xFFF59E0B);
  }

  String _getTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'bug': return 'Bug';
      case 'question': return 'Question';
      case 'suggestion': return 'Suggestion';
      case 'other': return 'Autre';
      default: return type.isNotEmpty ? type : 'Général';
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri uri = Uri.parse('https://wa.me/2250700000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8936A8)))
          : _error != null
              ? _buildErrorState()
              : _ticket == null
                  ? _buildNotFoundState()
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final ticket = _ticket!;
    final gradientColors = _getGradientColors(ticket);

    return Column(
      children: [
        // Header gradient avec titre + statut/date
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                // Barre titre
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                      Expanded(
                        child: Text(
                          ticket.reference != null
                              ? 'Demande #${ticket.reference}'
                              : 'Demande #${ticket.id}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.openSans(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),

                // Carte statut + date dans le header
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statut',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  ticket.statusLabel,
                                  style: GoogleFonts.openSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Envoyée le',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(ticket.createdAt),
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Contenu scrollable
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Bannière succès verte
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Votre demande a été envoyée. Nous vous répondrons rapidement.',
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: const Color(0xFF15803D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Carte "Ma demande"
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // En-tête section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, color: Colors.grey.shade500, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Ma demande',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const Spacer(),
                            // Badge type (question, bug, etc.)
                            if (ticket.category.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8936A8).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.help_outline, size: 13, color: Color(0xFF8936A8)),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTypeLabel(ticket.category),
                                      style: GoogleFonts.openSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF8936A8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      const Divider(height: 1),

                      // Sujet + message
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              ticket.subject,
                              style: GoogleFonts.openSans(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ticket.message,
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Carte réponse ou attente
                if (ticket.response != null)
                  _buildResponseCard(ticket)
                else
                  _buildWaitingCard(),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),

        // Boutons bas de page
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
          child: Row(
            children: [
              // Bouton Retour
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back, size: 18, color: Colors.black87),
                        const SizedBox(width: 8),
                        Text(
                          'Retour',
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton WhatsApp
              Expanded(
                child: GestureDetector(
                  onTap: _openWhatsApp,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble, size: 18, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'WhatsApp',
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Icône horloge dans cercle violet
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF8936A8).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.access_time, color: Color(0xFF8936A8), size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            'En attente de réponse',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notre équipe traite votre demande. Vous serez notifié dès qu\'une réponse sera disponible.',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          // Points animés
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.3 + i * 0.2),
                shape: BoxShape.circle,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(SupportTicket ticket) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                const Icon(Icons.support_agent, color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Réponse du support',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.response!,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
                if (ticket.respondedAt != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Répondu le ${_formatDate(ticket.respondedAt!)}',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Erreur de chargement',
                style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(_error ?? '',
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey.shade600)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadTicket,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8936A8), foregroundColor: Colors.white),
              child: Text('Réessayer', style: GoogleFonts.openSans()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('Ticket introuvable',
              style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
