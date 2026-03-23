import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_navbar.dart';
import '../../../../shared/widgets/sigmar_footer.dart';

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

// ── Hero ──────────────────────────────────────────────
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
            '¿QUIERES SABER POR QUÉ ESTAMOS AQUÍ PARA TÍ?',
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

// ── Historia ──────────────────────────────────────────
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
        'assets/images/hero1.png',
        fit: BoxFit.cover,
        height: 320,
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
      'Luz y Vida Somos Familia existe porque Dios tiene un Amor Grande para ti, '
          'para nuestra ciudad de El Alto, para Bolivia y para las naciones. Somos '
          'fruto de ese amor de Dios que un día llegó a nuestras vidas para darnos '
          'esperanza y una vida nueva.',

      'Dios en su bondad y soberanía levantó a 2 jóvenes poniendo en sus corazones '
          'el servirle, siendo usados con poder para llevar su amor hacia aquellas '
          'personas que necesitaban un nuevo comienzo con Dios.',

      'Es así que queremos contarte cómo fue ese proceso y cómo Dios guió y levantó '
          'más personas que llenos del amor de Dios hoy queremos compartirte lo que Dios '
          'hizo en nuestras vidas y también lo puede hacer contigo.',

      'Era la segunda semana de diciembre 1987, en donde dos amigos en Cristo, '
          'John Apaza y Rogelio Calle, junto a algunos niños, decidieron con la ayuda '
          'de Dios salir a la Plaza La Paz y predicar el evangelio de Jesucristo, '
          'tomando en sus manos una guitarra, un bombo pequeño y bastantes folletos '
          'que llevaban escrita la Palabra de Dios, pero sobre todo bastante decisión '
          'de ser usados por nuestro Señor.',
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

// ── Visión y Misión ───────────────────────────────────
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
                      'Ver familias transformadas, matrimonios estables y jóvenes con '
                          'propósito, formando una comunidad de creyentes maduros que impacten '
                          'El Alto, Bolivia y las naciones con el amor de Dios.',
                    ),
                    const SizedBox(height: 20),
                    _VMCard(
                      'MISIÓN',
                      Icons.flag_outlined,
                      'Proclamar el amor de Dios a través del evangelio de Jesucristo, '
                          'discipulando a cada persona para que crezca en fe, carácter y '
                          'servicio, fortaleciendo la familia como base de la sociedad y la iglesia.',
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: _VMCard(
                        'VISIÓN',
                        Icons.visibility_outlined,
                        'Ver familias transformadas, matrimonios estables y jóvenes con '
                            'propósito, formando una comunidad de creyentes maduros que impacten '
                            'El Alto, Bolivia y las naciones con el amor de Dios.',
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _VMCard(
                        'MISIÓN',
                        Icons.flag_outlined,
                        'Proclamar el amor de Dios a través del evangelio de Jesucristo, '
                            'discipulando a cada persona para que crezca en fe, carácter y '
                            'servicio, fortaleciendo la familia como base de la sociedad y la iglesia.',
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

// ── Línea de tiempo ───────────────────────────────────
class _SeccionLineasTiempo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const hitos = [
      _Hito(
        '1987',
        'Fundación',
        'John Apaza y Rogelio Calle comienzan a predicar en la Plaza La Paz, El Alto.',
      ),
      _Hito(
        '1990',
        'Crecimiento',
        'La congregación crece y se establece formalmente en El Alto, La Paz.',
      ),
      _Hito(
        '2000',
        'Expansión',
        'Se multiplican los grupos celulares y ministerios dentro de la iglesia.',
      ),
      _Hito(
        '2010',
        'Consolidación',
        'La iglesia consolida sus ministerios de jóvenes, matrimonios y niños.',
      ),
      _Hito(
        '2024',
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
class _SeccionPastores extends StatelessWidget {
  final bool movil;
  const _SeccionPastores({required this.movil});

  @override
  Widget build(BuildContext context) {
    const pastores = [
      _PastorInfo(
        'John Apaza',
        'Pastor Principal',
        'Fundador de la iglesia Luz y Vida. Con más de 37 años guiando la congregación con amor, sabiduría y visión de Dios.',
      ),
      _PastorInfo(
        'Rogelio Calle',
        'Co-Fundador',
        'Uno de los pilares desde los inicios en 1987, predicando el evangelio en El Alto y formando discípulos.',
      ),
      _PastorInfo(
        'Equipo Pastoral',
        'Líderes y Guías',
        'Un equipo comprometido con el discipulado, la adoración y el crecimiento espiritual de cada miembro de la familia.',
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

class _PastorInfo {
  final String nombre, rol, desc;
  const _PastorInfo(this.nombre, this.rol, this.desc);
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
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kGold.withOpacity(0.1),
            border: Border.all(color: kGold.withOpacity(0.5), width: 2),
          ),
          child: const Icon(Icons.person, color: kGold, size: 36),
        ),
        const SizedBox(height: 14),
        Text(
          info.nombre,
          style: const TextStyle(
            color: kWhite,
            fontSize: 16,
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

// ── Ubicación y contacto ──────────────────────────────
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
                    _MapaWidget(),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: _InfoContacto()),
                    const SizedBox(width: 40),
                    Expanded(child: _MapaWidget()),
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
        ...[
              [Icons.location_on_outlined, 'El Alto, La Paz, Bolivia'],
              [Icons.access_time_outlined, 'Domingo 9:00 AM y 6:00 PM'],
              [
                Icons.access_time_outlined,
                'Miércoles 7:00 PM — Estudio Bíblico',
              ],
              [Icons.facebook, 'facebook.com/luzyvidasomosfamilia'],
              [Icons.camera_alt_rounded, '@luzyvidasomosfamilia'],
              [Icons.language_outlined, 'somosluzyvida.net'],
            ]
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  children: [
                    Icon(item[0] as IconData, color: kGold, size: 18),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item[1] as String,
                        style: const TextStyle(
                          color: kGrey,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
    );
  }
}

class _MapaWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 260,
    decoration: BoxDecoration(
      color: kBgCard,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: kGold.withOpacity(0.3)),
    ),
    child: const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on, color: kGold, size: 52),
          SizedBox(height: 12),
          Text(
            'El Alto, La Paz',
            style: TextStyle(
              color: kWhite,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text('Bolivia', style: TextStyle(color: kGrey, fontSize: 13)),
          SizedBox(height: 8),
          Text(
            'Iglesia Luz y Vida — Somos Familia',
            style: TextStyle(color: kGold, fontSize: 12),
          ),
        ],
      ),
    ),
  );
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
