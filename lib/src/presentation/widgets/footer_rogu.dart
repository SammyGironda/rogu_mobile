import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
// Removed unused import

class ROGUFooter extends StatelessWidget {
  const ROGUFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Expanded(flex: 2, child: _BrandColumn()),
                SizedBox(width: 24),
                // remove const for non-const child
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                const Spacer(flex: 2),
                Expanded(flex: 1, child: _ContactColumn()),
              ],
            ),
          ),
          const Divider(color: AppColors.neutral700, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 12,
              children: [
                Text(
                  '© ${DateTime.now().year} ROGU. Todos los derechos reservados.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.neutral300,
                  ),
                ),
                Wrap(
                  spacing: 16,
                  children: [
                    _LegalLink('Privacidad'),
                    _LegalLink('Términos'),
                    _LegalLink('Cookies'),
                    _LegalLink('Accesibilidad'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Eliminamos columnas no requeridas

class _BrandColumn extends StatelessWidget {
  const _BrandColumn();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF06B6D4),
                    Color(0xFF0EA5E9),
                    Color(0xFF6366F1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.sports_soccer, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Text(
              'ROGÜ',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Plataforma para gestión de reservas y espacios deportivos. Encuentra canchas por sede, deporte y disponibilidad con una experiencia ágil.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.neutral300,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: const [
            _Badge(text: 'Reservas ágiles'),
            _Badge(text: 'Pagos seguros'),
            _Badge(text: 'Multidisciplinas'),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _ContactColumn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contacto',
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _ContactItem(icon: Icons.email, text: 'info@rogu.app'),
          _ContactItem(icon: Icons.phone, text: '+591 700 12345'),
          _ContactItem(icon: Icons.location_on, text: 'La Paz, Bolivia'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            children: const [
              _SocialIcon(icon: Icons.facebook),
              _SocialIcon(icon: Icons.sports_basketball),
              _SocialIcon(icon: Icons.camera_alt),
              _SocialIcon(icon: Icons.link),
            ],
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactItem({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary300),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.neutral300),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  const _SocialIcon({required this.icon});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

Widget _LegalLink(String text) => GestureDetector(
  onTap: () {},
  child: Text(
    text,
    style: const TextStyle(color: AppColors.neutral300, fontSize: 12),
  ),
);
