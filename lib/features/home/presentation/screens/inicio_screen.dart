import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/sigmar_navbar.dart';
import '../../../../shared/widgets/sigmar_footer.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final movil = MediaQuery.of(context).size.width < 800;
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          const SigmarNavbar(rutaActual: '/'),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _HeroMensajes(movil: movil),
                  _BannerVersiculo(),
                  _MinisterioSection(
                    titulo: 'Matrimonios – Familias',
                    descripcion:
                        'SLV Un lugar donde Aprendemos principios bíblicos que nos dan la '
                        'sabiduría para vivir una vida de acuerdo al propósito de Dios, y así '
                        'crecemos y nos transformamos en matrimonios estables llenos de amor, '
                        'fortalecidos en unidad guiando nuestra familia aún en medio de pruebas '
                        'pero con Dios siempre venciendo y alcanzando victorias para nuestro '
                        'hogar, nuestras relaciones, nuestras finanzas, nuestra salud avanza '
                        'de la mano de Dios.',
                    imagenes: const [
                      'assets/images/Familia1.png',
                      'assets/images/Familia2.png',
                      'assets/images/Familia3.png',
                      'assets/images/Familia4.png',
                      'assets/images/Familia5.png',
                    ],
                    invertido: false,
                    movil: movil,
                  ),
                  _SeparadorOndas(),
                  _MinisterioSection(
                    titulo: 'Jóvenes',
                    descripcion:
                        'SLV Un lugar donde como jóvenes de mucho entusiasmo nos desarrollamos '
                        'mientras crecemos por medio del aprendizaje de la Palabra de Dios, que '
                        'nos dirige en tomar decisiones que necesitamos. Aquí también cultivamos '
                        'lindas amistades y apoyo entre nosotros, así desarrollamos nuestro '
                        'liderazgo para alcanzar nuestras metas en cada área de nuestras vidas.',
                    imagenes: const [
                      'assets/images/Jove1.png',
                      'assets/images/Jove2.png',
                      'assets/images/Jove3.png',
                      'assets/images/Jove4.png',
                    ],
                    invertido: true,
                    movil: movil,
                  ),
                  _SeparadorOndas(),
                  _MinisterioSection(
                    titulo: 'Adultos',
                    descripcion:
                        'SLV Un lugar donde nuestros padres y abuelos encuentran fortaleza, '
                        'compañerismo, apoyo, oración unos por otros. Además siguen aprendiendo '
                        'bajo la guía de la Palabra de Dios sirviendo a la iglesia sin desmayar, '
                        'y siendo buenos consejeros para nuestros jóvenes.',
                    imagenes: const [
                      'assets/images/adul1.png',
                      'assets/images/adul2.png',
                      'assets/images/adul3.png',
                      'assets/images/adul4.png',
                    ],
                    invertido: false,
                    movil: movil,
                  ),
                  _SeparadorOndas(),
                  _MinisterioSection(
                    titulo: 'Niños',
                    descripcion:
                        'SLV Un lugar donde los niños desarrollan convivencia en comunidad, '
                        'empiezan a hacer amistades, a desarrollar sus talentos. Aprenden '
                        'principios bíblicos que les ayudan y refuerzan las buenas enseñanzas '
                        'de los padres, para que crezcan saludables emocionalmente llenos de '
                        'alegría y bendición de Dios.',
                    imagenes: const [
                      'assets/images/nino1.png',
                      'assets/images/nino2.png',
                      'assets/images/nino3.png',
                    ],
                    invertido: true,
                    movil: movil,
                  ),
                  _BannerUnete(movil: movil),
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

// ── Hero: imagen fija + mensajes/versículos rotativos ─
class _HeroMensajes extends StatefulWidget {
  final bool movil;
  const _HeroMensajes({required this.movil});

  @override
  State<_HeroMensajes> createState() => _HeroMensajesState();
}

class _HeroMensajesState extends State<_HeroMensajes> {
  static const _slides = [
    (
      titulo: '¡Bienvenido, Te Estábamos Esperando!',
      sub: '¡Ya somos muchas vidas transformadas por el amor de Dios!',
    ),
    (
      titulo: '"Todo lo puedo en Cristo que me fortalece."',
      sub: 'Filipenses 4:13 — Ven y descubre lo que Dios tiene para ti.',
    ),
    (
      titulo: '¿Buscas un lugar donde pertenecer?',
      sub:
          'Aquí encontrarás familia, amor y el propósito que Dios tiene para tu vida.',
    ),
    (
      titulo:
          '"Porque donde están dos o tres congregados en mi nombre, allí estoy yo."',
      sub: 'Mateo 18:20 — Únete a nuestra familia y siéntelo.',
    ),
    (
      titulo: '¡Dios tiene un plan extraordinario para tu vida!',
      sub: 'Da el primer paso y forma parte de esta gran familia.',
    ),
    (
      titulo: '"El Señor es mi pastor; nada me faltará."',
      sub: 'Salmos 23:1 — Encuentra descanso y plenitud en Su presencia.',
    ),
  ];

  int _actual = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      setState(() => _actual = (_actual + 1) % _slides.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_actual];

    return SizedBox(
      width: double.infinity,
      height: widget.movil ? 420 : 540,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Imagen fija ──
          Image.asset(
            'assets/images/equipo_pastoral.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF111111),
                    Color(0xFF2A1A00),
                    Color(0xFF111111),
                  ],
                ),
              ),
            ),
          ),

          // ── Overlay oscuro ──
          Container(color: Colors.black.withOpacity(0.62)),

          // ── Barra dorada superior ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 5, color: kGold),
          ),

          // ── Texto central animado ──
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 700),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0, 0.1),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOut),
                        ),
                    child: child,
                  ),
                ),
                child: Column(
                  key: ValueKey(_actual),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slide.titulo,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kWhite,
                        fontSize: widget.movil ? 22 : 40,
                        fontWeight: FontWeight.bold,
                        height: 1.3,
                        shadows: const [
                          Shadow(blurRadius: 10, color: Colors.black87),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(width: 60, height: 3, color: kGold),
                    const SizedBox(height: 18),
                    Text(
                      slide.sub,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kGrey,
                        fontSize: widget.movil ? 13 : 17,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 34),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.pushReplacementNamed(context, '/sobre'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kGold,
                        side: const BorderSide(color: kGold, width: 1.5),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                      child: const Text(
                        'QUIÉNES SOMOS',
                        style: TextStyle(letterSpacing: 1.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Indicadores ──
          Positioned(
            bottom: 18,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (i) => GestureDetector(
                  onTap: () => setState(() => _actual = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _actual ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _actual ? kGold : kGrey.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Banner versículo ──────────────────────────────────
class _BannerVersiculo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kBg, kGoldDark.withOpacity(0.3), kBg],
        ),
      ),
      child: Row(
        children: [
          Container(width: 4, height: 70, color: kGold),
          const SizedBox(width: 24),
          const Expanded(
            child: Text(
              'Mas a todos los que le recibieron, a los que creen en su nombre, '
              'les dio potestad de ser hechos hijos de Dios. Jn. 1:12',
              style: TextStyle(
                color: kWhite,
                fontSize: 17,
                fontStyle: FontStyle.italic,
                height: 1.65,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sección ministerio ─────────────────────────────────
class _MinisterioSection extends StatefulWidget {
  final String titulo, descripcion;
  final List<String> imagenes;
  final bool invertido, movil;

  const _MinisterioSection({
    required this.titulo,
    required this.descripcion,
    required this.imagenes,
    required this.invertido,
    required this.movil,
  });

  @override
  State<_MinisterioSection> createState() => _MinisterioSectionState();
}

class _MinisterioSectionState extends State<_MinisterioSection> {
  int _actual = 0;

  void _anterior() => setState(
    () => _actual =
        (_actual - 1 + widget.imagenes.length) % widget.imagenes.length,
  );

  void _siguiente() =>
      setState(() => _actual = (_actual + 1) % widget.imagenes.length);

  @override
  Widget build(BuildContext context) {
    final slider = _SliderFotos(
      imagenes: widget.imagenes,
      actual: _actual,
      onAnterior: _anterior,
      onSiguiente: _siguiente,
    );
    final texto = _TextoMinisterio(
      titulo: widget.titulo,
      descripcion: widget.descripcion,
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: 40),
      color: kGoldDark.withOpacity(0.15),
      child: widget.movil
          ? Column(children: [slider, const SizedBox(height: 28), texto])
          : widget.invertido
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 5, child: texto),
                const SizedBox(width: 48),
                Expanded(flex: 4, child: slider),
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(flex: 4, child: slider),
                const SizedBox(width: 48),
                Expanded(flex: 5, child: texto),
              ],
            ),
    );
  }
}

class _SliderFotos extends StatelessWidget {
  final List<String> imagenes;
  final int actual;
  final VoidCallback onAnterior, onSiguiente;

  const _SliderFotos({
    required this.imagenes,
    required this.actual,
    required this.onAnterior,
    required this.onSiguiente,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  child: Image.asset(
                    imagenes[actual],
                    key: ValueKey(imagenes[actual]),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: kBgCard,
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: kGold,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(child: _BtnSlider(Icons.chevron_left, onAnterior)),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _BtnSlider(Icons.chevron_right, onSiguiente),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imagenes.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == actual ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == actual ? kGold : kGrey.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BtnSlider extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BtnSlider(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: kWhite, size: 22),
    ),
  );
}

class _TextoMinisterio extends StatelessWidget {
  final String titulo, descripcion;
  const _TextoMinisterio({required this.titulo, required this.descripcion});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: kGold,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Container(width: 50, height: 3, color: kGold),
        const SizedBox(height: 20),
        Text(
          descripcion,
          style: const TextStyle(color: kGrey, fontSize: 15, height: 1.75),
        ),
      ],
    );
  }
}

// ── Separador ondas ────────────────────────────────────
class _SeparadorOndas extends StatelessWidget {
  @override
  Widget build(BuildContext context) => CustomPaint(
    size: const Size(double.infinity, 60),
    painter: _OndasPainter(),
  );
}

class _OndasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kGold.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.25,
        0,
        size.width * 0.5,
        size.height * 0.4,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.8,
        size.width,
        size.height * 0.5,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Banner únete ──────────────────────────────────────
class _BannerUnete extends StatelessWidget {
  final bool movil;
  const _BannerUnete({required this.movil});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [kGoldDark, kGold, kGoldLight],
        ),
      ),
      child: Column(
        children: [
          Text(
            '¿Tienes el Verdadero Amor de Dios en Tu Vida?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: movil ? 22 : 30,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '¡Dios te Ama! Ven y Forma Parte De Esta Gran Familia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF2A1A00),
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/sobre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: kGold,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            child: const Text(
              'CONOCER MÁS',
              style: TextStyle(letterSpacing: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
