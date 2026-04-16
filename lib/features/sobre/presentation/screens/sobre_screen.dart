import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_navbar.dart';
import '../../../../shared/widgets/sigmar_footer.dart';

void _abrir(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

// Coordenadas de Somos Luz y Vida — El Alto, La Paz, Bolivia
const _kMapSrc =
    'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d961.0!2d-68.2242291!3d-16.5184448!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x915edfe356c1f83f%3A0x51c5e49a949e6ad1!2sSomos+Luz+y+Vida!5e0!3m2!1ses!2sbo!4v1';

// Registro del iframe (web) — se llama una sola vez
bool _mapaRegistrado = false;
void _registrarMapa() {
  if (!kIsWeb || _mapaRegistrado) return;
  _mapaRegistrado = true;
  // ignore: undefined_prefixed_name
  ui_web.platformViewRegistry.registerViewFactory('mapa-luz-vida', (
    int viewId,
  ) {
    final iframe = html.IFrameElement()
      ..src = _kMapSrc
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allowFullscreen = true;
    return iframe;
  });
}

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    _registrarMapa();
    final movil = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          const SigmarNavbar(rutaActual: '/sobre'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const _HeroSobre(),
                  _SeccionHistoria(movil: movil),
                  _SeccionVisionMision(movil: movil),
                  const _SeccionLineasTiempo(),
                  _SeccionPastores(movil: movil),
                  _SeccionValores(movil: movil),
                  _SeccionUbicacion(movil: movil),
                  const SigmarFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero ─────────────────────────────────────────────────────────────────────

class _HeroSobre extends StatelessWidget {
  const _HeroSobre();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kGoldDark, kGold, kGoldLight],
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 3,
            width: 60,
            color: Colors.black.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            '¿QUIÉNES SOMOS?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'LUZ Y VIDA EN LAS NACIONES — SOMOS FAMILIA',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2A1A00),
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Historia ─────────────────────────────────────────────────────────────────

class _SeccionHistoria extends StatelessWidget {
  final bool movil;
  const _SeccionHistoria({required this.movil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBgMid,
      child: Column(
        children: [
          const _TituloSeccion('NUESTRA HISTORIA'),
          const SizedBox(height: 40),
          movil
              ? const Column(
                  children: [
                    _FotoIglesia(),
                    SizedBox(height: 32),
                    _TextoHistoria(),
                  ],
                )
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _FotoIglesia()),
                    SizedBox(width: 40),
                    Expanded(flex: 3, child: _TextoHistoria()),
                  ],
                ),
        ],
      ),
    );
  }
}

class _FotoIglesia extends StatelessWidget {
  const _FotoIglesia();
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/equipo_pastoral.png',
        fit: BoxFit.cover,
        height: 320,
        width: double.infinity,
        errorBuilder: (_, _, _) => Container(
          height: 320,
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGold.withValues(alpha: 0.3)),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.church, color: kGold, size: 64),
                SizedBox(height: 12),
                Text(
                  'Iglesia Luz y Vida',
                  style: TextStyle(color: kGrey, fontSize: 14),
                ),
                Text(
                  'El Alto, Bolivia',
                  style: TextStyle(color: kGold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TextoHistoria extends StatelessWidget {
  const _TextoHistoria();
  @override
  Widget build(BuildContext context) {
    const parrafos = [
      'La Congregación Cristiana "Luz y Vida en las Naciones" fue fundada oficialmente el 13 de diciembre de 1987 en la ciudad de El Alto, departamento de La Paz, Bolivia. Sus fundadores, el Pastor Rogelio Calle Chavez y el líder John Felix Apaza Apasa, junto a sus respectivas familias, iniciaron las primeras reuniones en el domicilio de la hermana Catalina Apasa Apasa.',
      'Desde sus inicios, la congregación se estableció con el propósito de predicar el evangelio de Jesucristo y formar una comunidad basada en principios bíblicos. A lo largo de los años, la iglesia ha desarrollado un enfoque ministerial centrado en la extensión del Reino de Dios, promoviendo la enseñanza de la Palabra bajo fundamentos de fe, confraternidad cristiana y crecimiento espiritual.',
      'Como estrategia de crecimiento y organización, la iglesia adopta el modelo celular conocido como "Modelo de los 12", estructurado en cuatro etapas: ganar, consolidar, discipular y enviar. Bajo el lema "Luz y Vida, Somos Familia", la congregación enfatiza la familia como base esencial de su estructura espiritual y organizativa.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Una Historia de Fe y Amor',
          style: TextStyle(
            color: kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 50, height: 3, color: kGold),
        const SizedBox(height: 20),
        ...parrafos.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              t,
              style: const TextStyle(color: kGrey, fontSize: 14, height: 1.75),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Visión y Misión ──────────────────────────────────────────────────────────

class _SeccionVisionMision extends StatelessWidget {
  final bool movil;
  const _SeccionVisionMision({required this.movil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBg,
      child: Column(
        children: [
          const _TituloSeccion('VISIÓN Y MISIÓN'),
          const SizedBox(height: 40),
          movil
              ? const Column(
                  children: [
                    _VMCard(
                      'VISIÓN',
                      Icons.visibility_outlined,
                      'Expandir el reino de Dios desde la ciudad de El Alto, por toda Bolivia y hasta lo último de la tierra.',
                    ),
                    SizedBox(height: 20),
                    _VMCard(
                      'MISIÓN',
                      Icons.flag_outlined,
                      'Somos una Iglesia de la Gran Comisión impulsada por el Espíritu Santo a rescatar vidas para enseñar la Palabra de Dios con el fin de desarrollar el carácter de Cristo, en sujeción, fidelidad y servicio a la Iglesia en las naciones.',
                    ),
                  ],
                )
              : const Row(
                  children: [
                    Expanded(
                      child: _VMCard(
                        'VISIÓN',
                        Icons.visibility_outlined,
                        'Expandir el reino de Dios desde la ciudad de El Alto, por toda Bolivia y hasta lo último de la tierra.',
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: _VMCard(
                        'MISIÓN',
                        Icons.flag_outlined,
                        'Somos una Iglesia de la Gran Comisión impulsada por el Espíritu Santo a rescatar vidas para enseñar la Palabra de Dios con el fin de desarrollar el carácter de Cristo, en sujeción, fidelidad y servicio a la Iglesia en las naciones.',
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}

class _VMCard extends StatelessWidget {
  final String titulo, desc;
  final IconData icono;
  const _VMCard(this.titulo, this.icono, this.desc);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kGold.withValues(alpha: 0.35)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, color: kGold, size: 26),
            const SizedBox(width: 12),
            Text(
              titulo,
              style: const TextStyle(
                color: kGold,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(width: 40, height: 2, color: kGold),
        const SizedBox(height: 14),
        Text(
          desc,
          style: const TextStyle(color: kGrey, fontSize: 14, height: 1.7),
        ),
      ],
    ),
  );
}

// ─── Línea de tiempo ──────────────────────────────────────────────────────────

class _SeccionLineasTiempo extends StatelessWidget {
  const _SeccionLineasTiempo();
  @override
  Widget build(BuildContext context) {
    const hitos = [
      _Hito(
        '1987',
        'Fundación',
        'El Pastor Rogelio Calle Chavez y John Felix Apaza Apasa fundan la iglesia el 13 de diciembre en El Alto, Bolivia.',
      ),
      _Hito(
        '1990',
        'Crecimiento',
        'La congregación crece y se establece formalmente en El Alto, La Paz.',
      ),
      _Hito(
        '2000',
        'Expansión',
        'Se multiplican los grupos celulares bajo el Modelo de los 12.',
      ),
      _Hito(
        '2010',
        'Consolidación',
        'La iglesia consolida sus ministerios de jóvenes, matrimonios y niños.',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBgMid,
      child: Column(
        children: [
          const _TituloSeccion('NUESTRA LÍNEA DE TIEMPO'),
          const SizedBox(height: 40),
          ...hitos.map((h) => _HitoItem(h)),
        ],
      ),
    );
  }
}

class _Hito {
  final String anio, titulo, desc;
  const _Hito(this.anio, this.titulo, this.desc);
}

class _HitoItem extends StatelessWidget {
  final _Hito h;
  const _HitoItem(this.h);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withValues(alpha: 0.1),
                border: Border.all(color: kGold, width: 2),
              ),
              child: Center(
                child: Text(
                  h.anio,
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Container(width: 2, height: 36, color: kDivider),
          ],
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h.titulo,
                  style: const TextStyle(
                    color: kWhite,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  h.desc,
                  style: const TextStyle(
                    color: kGrey,
                    fontSize: 13,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ─── Pastores ─────────────────────────────────────────────────────────────────

class _PastorInfo {
  final String nombre, rol, desc, foto;
  const _PastorInfo(this.nombre, this.rol, this.desc, this.foto);
}

class _SeccionPastores extends StatelessWidget {
  final bool movil;
  const _SeccionPastores({required this.movil});

  @override
  Widget build(BuildContext context) {
    const pastores = [
      _PastorInfo(
        'Pastor Rogelio Calle Chavez',
        'Pastor Fundador',
        'Co-fundador de la iglesia Luz y Vida. Desde 1987 guiando la congregación con amor, sabiduría y visión del Reino de Dios.',
        'assets/images/pastor_rogelio.jpg',
      ),
      _PastorInfo(
        'John Felix Apaza Apasa',
        'Co-Fundador',
        'Uno de los pilares desde los inicios el 13 de diciembre de 1987, predicando el evangelio en El Alto y formando discípulos.',
        'assets/images/pastor_john.jpg',
      ),
      _PastorInfo(
        'Equipo Pastoral',
        'Líderes y Guías',
        'Un equipo comprometido con el discipulado bajo el Modelo de los 12: ganar, consolidar, discipular y enviar.',
        'assets/images/equipo_pastoral.png',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBg,
      child: Column(
        children: [
          const _TituloSeccion('NUESTRO LIDERAZGO'),
          const SizedBox(height: 40),
          movil
              ? Column(
                  children: pastores
                      .map(
                        (p) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PastorCard(p),
                        ),
                      )
                      .toList(),
                )
              : Row(
                  children: pastores
                      .map(
                        (p) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: _PastorCard(p),
                          ),
                        ),
                      )
                      .toList(),
                ),
        ],
      ),
    );
  }
}

class _PastorCard extends StatelessWidget {
  final _PastorInfo info;
  const _PastorCard(this.info);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kDivider),
    ),
    child: Column(
      children: [
        ClipOval(
          child: Image.asset(
            info.foto,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withValues(alpha: 0.1),
                border: Border.all(
                  color: kGold.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  info.nombre[0],
                  style: const TextStyle(
                    color: kGold,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          info.nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kWhite,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          info.rol,
          style: const TextStyle(color: kGold, fontSize: 11, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        Text(
          info.desc,
          textAlign: TextAlign.center,
          style: const TextStyle(color: kGrey, fontSize: 13, height: 1.6),
        ),
      ],
    ),
  );
}

// ─── Valores ──────────────────────────────────────────────────────────────────

class _SeccionValores extends StatelessWidget {
  final bool movil;
  const _SeccionValores({required this.movil});

  @override
  Widget build(BuildContext context) {
    const vals = [
      _ValInfo(
        'Fe',
        Icons.stars_rounded,
        'Creemos en Dios y en Su Palabra como guía absoluta de nuestra vida.',
      ),
      _ValInfo(
        'Familia',
        Icons.people_rounded,
        'La familia es el núcleo de la iglesia y la base de la sociedad.',
      ),
      _ValInfo(
        'Servicio',
        Icons.volunteer_activism,
        'Servimos a Dios sirviendo a los demás con amor y dedicación.',
      ),
      _ValInfo(
        'Amor',
        Icons.favorite_rounded,
        'El amor de Dios transforma, sana toda herida y une a la familia.',
      ),
      _ValInfo(
        'Unidad',
        Icons.handshake_rounded,
        'Unidos en Cristo, fuertes como comunidad y como familia de Dios.',
      ),
      _ValInfo(
        'Discipulado',
        Icons.menu_book_rounded,
        'Crecer en la Palabra de Dios para transformar vidas y naciones.',
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBgMid,
      child: Column(
        children: [
          const _TituloSeccion('NUESTROS VALORES'),
          const SizedBox(height: 40),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: vals
                .map(
                  (v) => SizedBox(
                    width: movil ? double.infinity : 300,
                    child: _ValCard(v),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ValInfo {
  final String nombre, desc;
  final IconData icono;
  const _ValInfo(this.nombre, this.icono, this.desc);
}

class _ValCard extends StatelessWidget {
  final _ValInfo v;
  const _ValCard(this.v);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: kBg,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kDivider),
    ),
    child: Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(v.icono, color: kGold, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                v.nombre,
                style: const TextStyle(
                  color: kWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                v.desc,
                style: const TextStyle(
                  color: kGrey,
                  fontSize: 12,
                  height: 1.55,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

// ─── Ubicación ────────────────────────────────────────────────────────────────

class _SeccionUbicacion extends StatelessWidget {
  final bool movil;
  const _SeccionUbicacion({required this.movil});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBg,
      child: Column(
        children: [
          const _TituloSeccion('ENCUÉNTRANOS'),
          const SizedBox(height: 40),
          movil
              ? const Column(
                  children: [
                    _InfoContacto(),
                    SizedBox(height: 28),
                    _MapaWidget(),
                  ],
                )
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _InfoContacto()),
                    SizedBox(width: 40),
                    Expanded(child: _MapaWidget()),
                  ],
                ),
        ],
      ),
    );
  }
}

class _InfoContacto extends StatelessWidget {
  const _InfoContacto();
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información de Contacto',
          style: TextStyle(
            color: kGold,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Container(width: 50, height: 3, color: kGold),
        const SizedBox(height: 20),
        _ContactoItem(
          Icons.location_on_outlined,
          'El Alto, La Paz, Bolivia',
          'https://maps.app.goo.gl/a9MojcjXDnCtAN2d6',
        ),
        const _ContactoItem(
          Icons.access_time_outlined,
          'Domingo 9:00 AM y 6:00 PM',
          null,
        ),
        const _ContactoItem(
          Icons.access_time_outlined,
          'Miércoles — Estudio Bíblico',
          null,
        ),
        _ContactoItem(
          Icons.facebook,
          'facebook.com/luzyvidasomosfamilia',
          'https://www.facebook.com/luzyvidasomosfamilia',
        ),
        _ContactoItem(
          Icons.camera_alt_rounded,
          '@luzyvidasomosfamilia',
          'https://www.instagram.com/luzyvidasomosfamilia',
        ),
        _ContactoItem(
          Icons.play_circle_filled,
          '@LuzyVidaSomosFamilia',
          'https://www.youtube.com/@LuzyVidaSomosFamilia',
        ),
        _ContactoItem(
          Icons.language_outlined,
          'somosluzyvida.net',
          'https://somosluzyvida.net',
        ),
      ],
    );
  }
}

class _ContactoItem extends StatelessWidget {
  final IconData icon;
  final String texto;
  final String? url;
  const _ContactoItem(this.icon, this.texto, this.url);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: GestureDetector(
      onTap: url != null ? () => _abrir(url!) : null,
      child: MouseRegion(
        cursor: url != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: Row(
          children: [
            Icon(icon, color: kGold, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: TextStyle(
                  color: url != null ? kGoldLight : kGrey,
                  fontSize: 14,
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

// ─── Mapa con iframe real (web) o fallback (móvil/desktop nativo) ─────────────

class _MapaWidget extends StatelessWidget {
  const _MapaWidget();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // En nativo el tap abre Maps; en web el iframe es interactivo solo
      onTap: kIsWeb
          ? null
          : () => _abrir('https://maps.app.goo.gl/Ak5iU2Ca3M7LjrnGA'),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGold.withValues(alpha: 0.3)),
        ),
        clipBehavior: Clip.antiAlias,
        child: kIsWeb ? _MapaIframe() : _MapaFallback(),
      ),
    );
  }
}

/// Web — iframe real de Google Maps
class _MapaIframe extends StatelessWidget {
  _MapaIframe();

  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'mapa-luz-vida');
  }
}

/// Nativo (Android / Linux desktop) — diseño visual con botón para abrir Maps
class _MapaFallback extends StatelessWidget {
  const _MapaFallback();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Fondo
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a2a1a), Color(0xFF0d1a0d)],
            ),
          ),
        ),
        // Cuadrícula
        CustomPaint(painter: _GridPainter()),
        // Contenido
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: kGold.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: const Icon(Icons.location_on, color: kGold, size: 38),
              ),
              const SizedBox(height: 14),
              const Text(
                'Iglesia Luz y Vida',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'El Alto, La Paz, Bolivia',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () =>
                    _abrir('https://maps.app.goo.gl/Ak5iU2Ca3M7LjrnGA'),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: kGold,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.map_outlined, color: Colors.black, size: 15),
                      SizedBox(width: 6),
                      Text(
                        'VER EN GOOGLE MAPS',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.green.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Título de sección ────────────────────────────────────────────────────────

class _TituloSeccion extends StatelessWidget {
  final String texto;
  const _TituloSeccion(this.texto);
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        texto,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: kWhite,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 2,
        ),
      ),
      const SizedBox(height: 10),
      Container(width: 60, height: 3, color: kGold),
    ],
  );
}
