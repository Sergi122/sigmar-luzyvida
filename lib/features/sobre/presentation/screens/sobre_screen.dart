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

const _kMapSrc =
    'https://www.google.com/maps/embed?pb=!1m18!1m12!1m3!1d961.0!2d-68.2242291!3d-16.5184448!2m3!1f0!2f0!3f0!3m2!1i1024!2i768!4f13.1!3m3!1m2!1s0x915edfe356c1f83f%3A0x51c5e49a949e6ad1!2sSomos+Luz+y+Vida!5e0!3m2!1ses!2sbo!4v1';

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
        errorBuilder: (_, __, ___) => Container(
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
      'Luz y Vida Somos Familia existe porque Dios tiene un Amor Grande para ti, para nuestra ciudad de El Alto, para Bolivia y para las naciones. Somos fruto de ese amor de Dios que un día llegó a nuestras vidas para darnos esperanza y una vida nueva.',

      'En la segunda semana de diciembre de 1987, dos amigos en Cristo — John Apaza y Rogelio Calle — junto a algunos niños, decidieron salir a la Plaza La Paz a predicar el evangelio de Jesucristo. Con una guitarra, un bombo pequeño, un pandero y folletos con la Palabra de Dios, empezaron a predicar con gran decisión de ser usados por el Señor.',

      'En esa primera salida se convirtieron personas que jamás habían escuchado del amor de Dios. Por la tarde visitaron a un enfermo y comenzaron a invitar a las reuniones que se realizaban en una pequeña habitación de 4×4 en la casa de la Hermana Catalina Apaza, invitando también a los estudiantes del colegio Ballivián que quedaba al frente.',

      'Así pasó el tiempo y nuestro Amado Padre Celestial fue añadiendo a la iglesia naciente niños y adolescentes que, sin dinero pero con gran amor a Dios y fe en Jesucristo, proclamaban salvación para sus familias y amigos. El Señor había dado Su promesa: "Este puñado tan pequeño se multiplicará por mil... Yo soy el Señor, yo haré que se realice pronto, a su debido tiempo." Isaías 60:22.',

      'En 1996, el Señor derramó un avivamiento especial sobre aquella pequeña iglesia. Cada mañana, de lunes a viernes en las madrugadas, se reunían a orar e interceder por la salvación de los perdidos y por la ciudad de El Alto. La pasión por evangelizar se manifestó con teatros, mimos, payasos, grupos de coreografía "Nacidos para amar", saliendo a calles y plazas donde Dios abría puertas.',

      'La iglesia también impulsó la obra misionera apoyando a misioneros en diferentes países. La Hermana Judith levantó una obra en la República Checa, cumpliendo así la visión "Luz y Vida en las Naciones". A lo largo de los años hemos pasado por alegrías y victorias, dificultades y tristezas, pero entendemos que nada nos separará del amor de Dios.',

      'El crecimiento nos llevó de la habitación de 4×4 al pasaje Libertad en la zona 16 de Julio, luego a la calle Nery, a la sede de comerciantes en el callejón J. J. Pérez, por una Wally y la Capilla del Seminario Teológico, hasta llegar al Auditorio del CIAB que el Señor preparó para nosotros. Sin embargo, el anhelo es la pronta construcción de la GRAN CASA para la FAMILIA LUZ Y VIDA — un templo para las naciones.',

      'Hoy levantamos ministerios de servicio: Ujieres, Maestros, Alabanza, Sonido, Decoraciones, Sacramentos, Finanzas, Misiones, Coreografía, Danza, Manos Abiertas, Audiovisual, y los GruposVIDA — nuestras células de crecimiento. En nuestros corazones late alcanzar a nuestra generación, ganar a toda Bolivia y compartir el evangelio porque con Dios siempre hay un nuevo comienzo para todos. ¡Somos una gran familia para las familias!',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Una Historia de Fe, Amor y Transformación',
          style: TextStyle(
            color: kGold,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(width: 50, height: 3, color: kGold),
        const SizedBox(height: 20),
        // Versículo destacado
        Container(
          padding: const EdgeInsets.all(18),
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: kGold, width: 4)),
            color: kGold.withValues(alpha: 0.06),
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: const Text(
            '"Este puñado tan pequeño se multiplicará por mil; este pequeño número será una gran nación. Yo soy el Señor, yo haré que se realice pronto, a su debido tiempo." — Isaías 60:22',
            style: TextStyle(
              color: kGoldLight,
              fontSize: 13,
              fontStyle: FontStyle.italic,
              height: 1.7,
            ),
          ),
        ),
        ...parrafos.map(
          (t) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              t,
              style: const TextStyle(color: kGrey, fontSize: 14, height: 1.8),
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
        'John Apaza y Rogelio Calle salen a predicar el evangelio a la Plaza La Paz el 13 de diciembre. Las primeras reuniones se realizan en la casa de la Hna. Catalina Apaza.',
      ),
      _Hito(
        '1990',
        'Crecimiento',
        'La congregación crece con niños, adolescentes y jóvenes que proclaman salvación con gran fe y amor a Dios.',
      ),
      _Hito(
        '1996',
        'Avivamiento',
        'El Señor derrama un avivamiento especial. La iglesia se reúne madrugadas de lunes a viernes en oración e intercesión. Teatros, mimos, coreografías salen a las calles.',
      ),
      _Hito(
        '2000',
        'Expansión',
        'Se multiplican los GruposVIDA (células) bajo el Modelo de los 12: ganar, consolidar, discipular y enviar. Apoyo a obras misioneras en el exterior.',
      ),
      _Hito(
        '2010',
        'Consolidación',
        'La iglesia consolida sus ministerios: Jóvenes, Matrimonios, Adultos, Niños, Alabanza, Misiones, Manos Abiertas y más.',
      ),
      _Hito(
        'HOY',
        'Seguimos Avanzando',
        'Con la promesa de Isaías 60:22 en el corazón, la familia Luz y Vida avanza hacia la construcción de su Gran Casa y la expansión en las naciones.',
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
            errorBuilder: (_, __, ___) => Container(
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

        // ── Horarios ──
        _ContactoItem(
          Icons.location_on_outlined,
          'El Alto, La Paz, Bolivia',
          'https://maps.app.goo.gl/a9MojcjXDnCtAN2d6',
        ),

        // Domingo
        const _HorarioItem(
          icon: Icons.calendar_today_outlined,
          dia: 'Domingo',
          horas: '9:00 AM  •  5:00 PM',
          detalle: 'Culto General',
        ),

        // Miércoles — dos turnos
        const _HorarioItem(
          icon: Icons.calendar_today_outlined,
          dia: 'Miércoles',
          horas: '5:30 AM  •  7:00 PM',
          detalle: 'Oración e Intercesión',
        ),

        const SizedBox(height: 8),
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

// Widget de horario con dos líneas (día + horas)
class _HorarioItem extends StatelessWidget {
  final IconData icon;
  final String dia, horas, detalle;
  const _HorarioItem({
    required this.icon,
    required this.dia,
    required this.horas,
    required this.detalle,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: kGold, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dia,
                    style: const TextStyle(
                      color: kWhite,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: kGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: kGold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      detalle,
                      style: const TextStyle(
                        color: kGold,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                horas,
                style: const TextStyle(color: kGrey, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
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

// ─── Mapa ─────────────────────────────────────────────────────────────────────

class _MapaWidget extends StatelessWidget {
  const _MapaWidget();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        child: kIsWeb ? _MapaIframe() : const _MapaFallback(),
      ),
    );
  }
}

class _MapaIframe extends StatelessWidget {
  _MapaIframe();
  @override
  Widget build(BuildContext context) {
    return const HtmlElementView(viewType: 'mapa-luz-vida');
  }
}

class _MapaFallback extends StatelessWidget {
  const _MapaFallback();
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1a2a1a), Color(0xFF0d1a0d)],
            ),
          ),
        ),
        CustomPaint(painter: _GridPainter()),
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

// ─── Título sección ───────────────────────────────────────────────────────────

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
