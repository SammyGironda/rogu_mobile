import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/participa_repository.dart';
import '../../../core/theme/app_theme.dart';

class InviteParticipantsScreen extends StatefulWidget {
  final int idReserva;
  final String? cancha;
  final String? sede;

  const InviteParticipantsScreen({
    super.key,
    required this.idReserva,
    this.cancha,
    this.sede,
  });

  @override
  State<InviteParticipantsScreen> createState() =>
      _InviteParticipantsScreenState();
}

class _InviteParticipantsScreenState extends State<InviteParticipantsScreen> {
  final _repo = ParticipaRepository();
  late Future<Map<String, dynamic>> _future;
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _future = _repo.getParticipantes(widget.idReserva);
  }

  void _refresh() {
    setState(() {
      _future = _repo.getParticipantes(widget.idReserva);
    });
  }

  Future<void> _invite() async {
    final correo = _emailCtrl.text.trim();
    if (correo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await _repo.invitar(
        idReserva: widget.idReserva,
        correo: correo,
        nombres: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitaci\u00f3n enviada')),
        );
        _emailCtrl.clear();
        _nameCtrl.clear();
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invitar personas'),
        backgroundColor: AppColors.primary600,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('No se pudieron cargar los participantes\n${snapshot.error ?? ''}'),
              ),
            );
          }
          final data = snapshot.data!;
          final cupos = data['cupos'] as Map<String, dynamic>? ?? {};
          final participantes = (data['participantes'] as List? ?? [])
              .cast<Map<String, dynamic>>();

          return RefreshIndicator(
            onRefresh: () async {
              _refresh();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Header(
                  cuposTotales: cupos['total'] ?? 0,
                  cuposOcupados: cupos['ocupados'] ?? 0,
                  cancha: widget.cancha,
                  sede: widget.sede,
                ),
                const SizedBox(height: 12),
                _InviteCard(
                  emailController: _emailCtrl,
                  nameController: _nameCtrl,
                  sending: _sending,
                  onSend: _invite,
                ),
                const SizedBox(height: 12),
                ...participantes.map((p) => _ParticipantTile(participante: p)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final int cuposTotales;
  final int cuposOcupados;
  final String? cancha;
  final String? sede;
  const _Header({
    required this.cuposTotales,
    required this.cuposOcupados,
    this.cancha,
    this.sede,
  });

  @override
  Widget build(BuildContext context) {
    final disponibles = cuposTotales - cuposOcupados;
    return Card(
      color: AppColors.neutral900,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              cancha ?? 'Cancha',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (sede != null)
              Text(
                sede!,
                style: const TextStyle(color: Colors.white70),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Chip(label: 'Cupos: $cuposTotales'),
                const SizedBox(width: 8),
                _Chip(label: 'Usados: $cuposOcupados'),
                const SizedBox(width: 8),
                _Chip(label: 'Disponibles: $disponibles'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController nameController;
  final VoidCallback onSend;
  final bool sending;

  const _InviteCard({
    required this.emailController,
    required this.nameController,
    required this.onSend,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invitar por correo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo electr\u00f3nico',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre (opcional)',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: sending ? null : onSend,
              icon: const Icon(Icons.send),
              label: Text(sending ? 'Enviando...' : 'Enviar invitaci\u00f3n'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final Map<String, dynamic> participante;
  const _ParticipantTile({required this.participante});

  @override
  Widget build(BuildContext context) {
    final tipo = (participante['tipoAsistente'] ?? '').toString();
    final checkIn = participante['checkInEn']?.toString();
    final confirmado = participante['confirmado'] == true;
    final nombre = participante['nombre']?.toString() ?? 'Invitado';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _colorForTipo(tipo),
          child: Icon(
            confirmado ? Icons.check : Icons.schedule,
            color: Colors.white,
          ),
        ),
        title: Text(nombre),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tipo: $tipo'),
            if (checkIn != null && checkIn.isNotEmpty)
              Text('Ingreso: ${_fmtDate(checkIn)}'),
          ],
        ),
      ),
    );
  }

  Color _colorForTipo(String tipo) {
    switch (tipo) {
      case 'titular':
        return Colors.indigo;
      case 'invitado_registrado':
        return Colors.green;
      case 'invitado_no_registrado':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd/MM HH:mm').format(dt.toLocal());
    } catch (_) {
      return raw;
    }
  }
}
