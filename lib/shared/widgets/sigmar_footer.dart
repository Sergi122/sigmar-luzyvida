import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';

void _abrir(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class SigmarFooter extends StatelessWidget {
  const SigmarFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return Container(
      color: const Color(0xFF111111),
      child: Column(
        children: [
          Container(height: 5, color: kGold),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 48,
              horizontal: movil ? 20 : 40,
            ),
            child: movil
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LogoFooter(),
                      const SizedBox(height: 32),
                      _ContactoFooter(),
                      const SizedBox(height: 32),
                      _HorariosFooter(),
                      const SizedBox(height: 32),
                      _RedesFooter(),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _LogoFooter()),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _ContactoFooter()),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _HorariosFooter()),
                      const SizedBox(width: 40),
                      Expanded(flex: 2, child: _RedesFooter()),
                    ],
                  ),
          ),
          Container(height: 1, color: kDivider),
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: 20,
              horizontal: movil ? 20 : 40,
            ),
            child: movil
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Derechos Reservados | somosluzyvida.net®',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kGrey, fontSize: 11),
                      ),
                      Text(
                        'El Alto - La Paz - Bolivia',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: kGrey, fontSize: 11),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'SIGMAR v1.0',
                        style: TextStyle(color: kGrey, fontSize: 11),
                      ),
                    ],
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Derechos Reservados | somosluzyvida.net® | El Alto - La Paz - Bolivia',
                        style: TextStyle(color: kGrey, fontSize: 11),
                      ),
                      Text(
                        'SIGMAR v1.0',
                        style: TextStyle(color: kGrey, fontSize: 11),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LogoFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // ✅ Logo real
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.jpg',
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(colors: [kGold, kGoldDark]),
                  ),
                  child: const Center(
                    child: Text(
                      'LV',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LUZ Y VIDA',
                  style: TextStyle(
                    color: kGold,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  'Somos Familia',
                  style: TextStyle(color: kGrey, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Una iglesia cristiana comprometida\ncon el amor de Dios y la familia.',
          style: TextStyle(color: kGrey, fontSize: 13, height: 1.6),
        ),
      ],
    );
  }
}

class _ContactoFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTACTO',
          style: TextStyle(
            color: kGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        // ✅ Ubicacion abre Google Maps
        _FooterItem(
          Icons.location_on_outlined,
          'El Alto, La Paz, Bolivia',
          url: 'https://maps.app.goo.gl/a9MojcjXDnCtAN2d6',
        ),
        _FooterItem(
          Icons.email_outlined,
          'contacto@somosluzyvida.net',
          url: 'mailto:contacto@somosluzyvida.net',
        ),
        _FooterItem(Icons.phone_outlined, '+591 (Bolivia)'),
        _FooterItem(
          Icons.language_outlined,
          'somosluzyvida.net',
          url: 'https://somosluzyvida.net',
        ),
      ],
    );
  }
}

class _HorariosFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HORARIOS',
          style: TextStyle(
            color: kGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        _FooterItem(Icons.access_time_outlined, 'Domingo 9:00 AM'),
        _FooterItem(Icons.access_time_outlined, 'Domingo 5:00 PM'),
        _FooterItem(Icons.access_time_outlined, 'Miercoles 5:00 AM'),
        const SizedBox(height: 8),
        // ✅ Boton ubicacion abre Maps
        GestureDetector(
          onTap: () => _abrir('https://maps.app.goo.gl/a9MojcjXDnCtAN2d6'),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: kGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: kGold.withOpacity(0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: kGold, size: 13),
                  SizedBox(width: 6),
                  Text(
                    '¡Todos son bienvenidos!',
                    style: TextStyle(color: kGold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RedesFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SÍGUENOS',
          style: TextStyle(
            color: kGold,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 16),
        // ✅ Links reales
        _RedBtn(
          Icons.facebook,
          'Facebook',
          const Color(0xFF1877F2),
          'https://www.facebook.com/luzyvidasomosfamilia',
        ),
        const SizedBox(height: 8),
        _RedBtn(
          Icons.camera_alt_rounded,
          'Instagram',
          const Color(0xFFE1306C),
          'https://www.instagram.com/luzyvidasomosfamilia',
        ),
        const SizedBox(height: 8),
        _RedBtn(
          Icons.play_circle_filled,
          'YouTube',
          const Color(0xFFFF0000),
          'https://www.youtube.com/@LuzyVidaSomosFamilia',
        ),
      ],
    );
  }
}

class _FooterItem extends StatelessWidget {
  final IconData icon;
  final String texto;
  final String? url;
  const _FooterItem(this.icon, this.texto, {this.url});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTap: url != null ? () => _abrir(url!) : null,
      child: MouseRegion(
        cursor: url != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: Row(
          children: [
            Icon(icon, color: kGold, size: 15),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: url != null ? kGoldLight : kGrey,
                  fontSize: 12,
                  height: 1.4,
                  decoration: url != null ? TextDecoration.underline : null,
                  decorationColor: kGoldLight,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _RedBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String url;
  const _RedBtn(this.icon, this.label, this.color, this.url);
  @override
  State<_RedBtn> createState() => _RedBtnState();
}

class _RedBtnState extends State<_RedBtn> {
  bool _h = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _h = true),
    onExit: (_) => setState(() => _h = false),
    child: GestureDetector(
      onTap: () => _abrir(widget.url),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _h ? widget.color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: _h ? widget.color : kDivider),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: _h ? widget.color : kGrey, size: 16),
            const SizedBox(width: 8),
            Text(
              widget.label,
              style: TextStyle(color: _h ? widget.color : kGrey, fontSize: 12),
            ),
          ],
        ),
      ),
    ),
  );
}
