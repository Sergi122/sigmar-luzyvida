import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_navbar.dart';
import '../../../../shared/widgets/sigmar_footer.dart';

void _abrir(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri))
    await launchUrl(uri, mode: LaunchMode.externalApplication);
}

class SobreScreen extends StatelessWidget {
  const SobreScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                  _HeroSobre(),
                  _SeccionHistoria(movil: movil),
                  _SeccionVisionMision(movil: movil),
                  _SeccionLineasTiempo(),
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

class _HeroSobre extends StatelessWidget {
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
          Container(height: 3, width: 60, color: Colors.black.withOpacity(0.3)),
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
          _TituloSeccion('NUESTRA HISTORIA'),
          const SizedBox(height: 40),
          movil
              ? Column(
                  children: [
                    _FotoIglesia(),
                    const SizedBox(height: 32),
                    _TextoHistoria(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _FotoIglesia()),
                    const SizedBox(width: 40),
                    Expanded(flex: 3, child: _TextoHistoria()),
                  ],
                ),
        ],
      ),
    );
  }
}

class _FotoIglesia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.asset(
        'assets/images/equipo_pastoral.png', // ✅ foto real
        fit: BoxFit.cover,
        height: 320,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          height: 320,
          decoration: BoxDecoration(
            color: kBgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kGold.withOpacity(0.3)),
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
          _TituloSeccion('VISIÓN Y MISIÓN'),
          const SizedBox(height: 40),
          movil
              ? Column(
                  children: [
                    _VMCard(
                      'VISIÓN',
                      Icons.visibility_outlined,
                      'Expandir el reino de Dios desde la ciudad de El Alto, por toda Bolivia y hasta lo último de la tierra.',
                    ),
                    const SizedBox(height: 20),
                    _VMCard(
                      'MISIÓN',
                      Icons.flag_outlined,
                      'Somos una Iglesia de la Gran Comisión impulsada por el Espíritu Santo a rescatar vidas para enseñar la Palabra de Dios con el fin de desarrollar el carácter de Cristo, en sujeción, fidelidad y servicio a la Iglesia en las naciones.',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _VMCard(
                        'VISIÓN',
                        Icons.visibility_outlined,
                        'Expandir el reino de Dios desde la ciudad de El Alto, por toda Bolivia y hasta lo último de la tierra.',
                      ),
                    ),
                    const SizedBox(width: 24),
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
      border: Border.all(color: kGold.withOpacity(0.35)),
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

class _SeccionLineasTiempo extends StatelessWidget {
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
      _Hito(
        '2025',
        'SIGMAR',
        'Implementación del sistema digital de gestión de miembros y grupos.',
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
      color: kBgMid,
      child: Column(
        children: [
          _TituloSeccion('NUESTRA LÍNEA DE TIEMPO'),
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
                color: kGold.withOpacity(0.1),
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

// ── Pastores ──────────────────────────────────────────
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
        'assets/images/pastor_rogelio.jpg', // ← agrega la foto cuando la tengas
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
          _TituloSeccion('NUESTRO LIDERAZGO'),
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
        // ✅ Foto circular real
        ClipOval(
          child: Image.asset(
            info.foto,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kGold.withOpacity(0.1),
                border: Border.all(color: kGold.withOpacity(0.5), width: 2),
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

// ── Valores ───────────────────────────────────────────
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
          _TituloSeccion('NUESTROS VALORES'),
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
            color: kGold.withOpacity(0.1),
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

// ── Ubicación ─────────────────────────────────────────
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
          _TituloSeccion('ENCUÉNTRANOS'),
          const SizedBox(height: 40),
          movil
              ? Column(
                  children: [
                    _InfoContacto(),
                    const SizedBox(height: 28),
                    const _MapaWidget(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _InfoContacto()),
                    const SizedBox(width: 40),
                    const Expanded(child: _MapaWidget()),
                  ],
                ),
        ],
      ),
    );
  }
}

class _InfoContacto extends StatelessWidget {
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
        _ContactoItem(
          Icons.access_time_outlined,
          'Domingo 9:00 AM y 6:00 PM',
          null,
        ),
        _ContactoItem(
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

// ✅ Mapa embebido multiplataforma
class _MapaWidget extends StatelessWidget {
  const _MapaWidget();

  Future<void> _abrirMapa(BuildContext context) async {
    final url = Uri.parse(
      'https://www.google.com/maps?q=-16.524,-68.173&z=15',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se pudo abrir el mapa'),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _abrirMapa(context),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: kGold.withOpacity(0.3)),
        ),
        child: Stack(
          children: [
            // Imagen estática del mapa (placeholder)
            Container(
              decoration: BoxDecoration(
                color: kBgCard,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 48,
                      color: kGold.withOpacity(0.6),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'La Paz, Bolivia',
                      style: TextStyle(
                        color: kWhite.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Overlay con botón
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.open_in_new,
                    color: kWhite,
                    size: 32,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widget auxiliar ───────────────────────────────────
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
