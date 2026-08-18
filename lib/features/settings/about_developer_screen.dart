import 'package:flutter/material.dart';

class AboutDeveloperScreen extends StatelessWidget {
  const AboutDeveloperScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('About')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _ProductHero(),
                const SizedBox(height: 28),
                const _SectionHeading(
                  eyebrow: 'PROJECT CREDITS',
                  title: 'People and partners',
                  subtitle:
                      'Built through local creativity, education and collaboration.',
                ),
                const SizedBox(height: 14),
                const _BrandGrid(),
                const SizedBox(height: 28),
                const _SectionHeading(
                  eyebrow: 'OUR APPROACH',
                  title: 'Python, wherever you are',
                  subtitle:
                      'A focused mobile workspace designed for privacy and offline learning.',
                ),
                const SizedBox(height: 14),
                const _PrinciplesCard(),
                const SizedBox(height: 28),
                const _ProjectFooter(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _ProductHero extends StatelessWidget {
  const _ProductHero();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primaryContainer, colors.tertiaryContainer],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 86,
            height: 86,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Image.asset(
              'assets/images/python-snake-mascot.png',
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Python IDE',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Write. Run. Learn. Anywhere.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colors.onPrimaryContainer.withValues(alpha: 0.82),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ON-DEVICE • OFFLINE-FIRST',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        eyebrow,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 5),
      Text(
        subtitle,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.45),
      ),
    ],
  );
}

class _BrandGrid extends StatelessWidget {
  const _BrandGrid();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxWidth < 560;
      final tmk = _BrandCard(
        label: 'A PROJECT OF',
        name: 'TMK Group',
        localName: 'ထုင်ႉမၢဝ်းၶမ်း',
        asset: 'assets/images/tmk-group-logo.png',
        compact: compact,
      );
      final o2k = _BrandCard(
        label: 'IN COLLABORATION WITH',
        name: 'O2K School',
        localName: 'Oceans of Knowledge',
        asset: 'assets/images/o2k-school-logo.jpg',
        compact: compact,
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: tmk),
          SizedBox(width: compact ? 10 : 14),
          Expanded(child: o2k),
        ],
      );
    },
  );
}

class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.label,
    required this.name,
    required this.localName,
    required this.asset,
    required this.compact,
  });

  final String label;
  final String name;
  final String localName;
  final String asset;
  final bool compact;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    child: Padding(
      padding: EdgeInsets.all(compact ? 10 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: compact ? 32 : 28,
            child: Text(
              label,
              maxLines: 2,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: compact ? 8 : 10,
                fontWeight: FontWeight.w800,
                letterSpacing: compact ? 0.45 : 0.9,
                height: 1.3,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 12),
          Container(
            height: compact ? 108 : 142,
            width: double.infinity,
            padding: EdgeInsets.all(compact ? 6 : 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(compact ? 14 : 18),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Image.asset(asset, fit: BoxFit.contain),
          ),
          SizedBox(height: compact ? 10 : 14),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? Theme.of(context).textTheme.titleSmall
                        : Theme.of(context).textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            localName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: compact ? 10 : null,
              height: 1.25,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PrinciplesCard extends StatelessWidget {
  const _PrinciplesCard();

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Column(
        children: const [
          _PrincipleTile(
            icon: Icons.offline_bolt_outlined,
            title: 'Offline Python',
            subtitle: 'The core runtime is bundled with the app.',
          ),
          Divider(height: 1),
          _PrincipleTile(
            icon: Icons.lock_outline,
            title: 'Private by design',
            subtitle: 'Your code remains on your device unless you share it.',
          ),
          Divider(height: 1),
          _PrincipleTile(
            icon: Icons.phone_android_outlined,
            title: 'Made for mobile',
            subtitle: 'A focused editor for phones and tablets.',
          ),
        ],
      ),
    ),
  );
}

class _PrincipleTile extends StatelessWidget {
  const _PrincipleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: const EdgeInsets.symmetric(vertical: 5),
    leading: Container(
      width: 42,
      height: 42,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 21,
        color: Theme.of(context).colorScheme.onSecondaryContainer,
      ),
    ),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: Text(subtitle),
  );
}

class _ProjectFooter extends StatelessWidget {
  const _ProjectFooter();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        'Python IDE • Version 1.0.0',
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}
