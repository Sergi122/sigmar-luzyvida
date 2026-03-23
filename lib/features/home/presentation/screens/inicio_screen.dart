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
                  _HeroSection(movil: movil),
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
                      'assets/images/hero1.png',
                      'assets/images/hero2.png',
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
                      'assets/images/hero3.png',
                      'assets/images/hero4.png',
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
                      'assets/images/hero5.png',
                      'assets/images/hero1.png',
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
                      'assets/images/hero2.png',
                      'assets/images/hero3.png',
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

// ── Hero ──────────────────────────────────────────────
class _HeroSection extends StatelessWidget {
  final bool movil;
  const _HeroSection({required this.movil});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: movil ? 420 : 540,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen de fondo
          Image.asset(
            'assets/images/hero1.png',
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
          // Overlay oscuro
          Container(color: Colors.black.withOpacity(0.65)),
          // Barra dorada superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(height: 5, color: kGold),
          ),
          // Contenido
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '¡Bienvenido Te Estábamos Esperando!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kWhite,
                      fontSize: movil ? 28 : 48,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '¡Ya Somos Muchas Vidas Transformadas por El Amor de Dios!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kGrey,
                      fontSize: movil ? 14 : 18,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 14,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kGold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text(
                          'ACCEDER AL SISTEMA',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/sobre'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kGold,
                          side: const BorderSide(color: kGold),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        child: const Text('QUIÉNES SOMOS'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Indicadores
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(
                  5,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == 0 ? 22 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == 0 ? kGold : kGrey.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(4),
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

// ── Sección ministerio con slider de fotos ─────────────
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

  void _anterior() {
    setState(() {
      _actual = (_actual - 1 + widget.imagenes.length) % widget.imagenes.length;
    });
  }

  void _siguiente() {
    setState(() {
      _actual = (_actual + 1) % widget.imagenes.length;
    });
  }

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
            // Imagen principal
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.asset(
                  imagenes[actual],
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: kBgCard,
                    child: const Center(
                      child: Icon(Icons.image_outlined, color: kGold, size: 64),
                    ),
                  ),
                ),
              ),
            ),
            // Botón anterior
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(child: _BtnSlider(Icons.chevron_left, onAnterior)),
            ),
            // Botón siguiente
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
        // Indicadores
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...List.generate(
              imagenes.length,
              (i) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == actual ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == actual ? kGold : kGrey.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
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

// ── Separador de ondas ─────────────────────────────────
class _SeparadorOndas extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(double.infinity, 60),
      painter: _OndasPainter(),
    );
  }
}

class _OndasPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = kGold.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.0,
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
    canvas.drawPath(path1, p1);
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
