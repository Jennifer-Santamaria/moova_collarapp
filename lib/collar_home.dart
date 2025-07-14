// --------------- 1) IMPORTS --------------- //
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';         
import 'package:device_info_plus/device_info_plus.dart';             

// --------------- 2) STATEFUL WIDGET --------------- //
class CollarHomePage extends StatefulWidget {
  const CollarHomePage({super.key});

  @override
  State<CollarHomePage> createState() => _CollarHomePageState();
}

class _CollarHomePageState extends State<CollarHomePage> {
  String? cowId;                                                
  final TextEditingController nameController =
      TextEditingController(text: 'Vaca 001');

  String lastUpdate = '';
  String latitude = '';
  String longitude = '';

  Position? _lastSentPosition;
  Timer? _timer;
  int _intervalMinutes = 1;
  StreamSubscription<Position>? _positionStream;

  @override
  void initState() {
    super.initState();
    _initCowId();
    _loadSavedData();
    _startBackgroundUpdates();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStream?.cancel();
    nameController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      nameController.text = prefs.getString('cowName') ?? nameController.text;
      lastUpdate   = prefs.getString('lastUpdate')   ?? '';
      latitude     = prefs.getString('latitude')     ?? '';
      longitude    = prefs.getString('longitude')    ?? '';
    });
  }

  Future<void> _saveLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cowName', nameController.text);
    await prefs.setString('lastUpdate', lastUpdate);
    await prefs.setString('latitude', latitude);
    await prefs.setString('longitude', longitude);
  }

  Future<void> _initCowId() async {
  final prefs = await SharedPreferences.getInstance();
  final deviceInfo = DeviceInfoPlugin();
  final androidInfo = await deviceInfo.androidInfo;
  
  setState(() {
    cowId = prefs.getString('cowId') ?? 'COW_${androidInfo.model.replaceAll(' ', '_')}_${androidInfo.id}';
  });
  
  if (prefs.getString('cowId') == null) {
    await prefs.setString('cowId', cowId!);
  }
}

  void _startBackgroundUpdates() {
    _timer = Timer.periodic(
      Duration(minutes: _intervalMinutes),
      (timer) => _sendData(),
    );

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position position) {
      if (_lastSentPosition == null ||
          Geolocator.distanceBetween(
            _lastSentPosition!.latitude,
            _lastSentPosition!.longitude,
            position.latitude,
            position.longitude,
          ) > 10) {
        _sendData(position);
      }
    });
  }

  Future<void> _sendData([Position? position]) async {
    if (cowId == null || cowId!.isEmpty) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showSnack('Permiso de ubicación denegado');
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      _showSnack('Permiso denegado permanentemente. Ve a Configuración');
      return;
    }

    final pos = position ?? await Geolocator.getCurrentPosition();
    final now = DateTime.now();
    final formattedDate = DateFormat('dd-MM-yyyy  hh:mm a').format(now);

    setState(() {
      lastUpdate = formattedDate;
      latitude   = pos.latitude.toString();
      longitude  = pos.longitude.toString();
    });

    _lastSentPosition = pos;
    await _saveLocalData();

   try {
  // Actualiza o crea el documento de la vaca con su nombre
  await FirebaseFirestore.instance
      .collection('ubicaciones')
      .doc(cowId)
      .set({'nombre': nameController.text}, SetOptions(merge: true));

  // Añade una entrada al historial de ubicaciones
  await FirebaseFirestore.instance
      .collection('ubicaciones')
      .doc(cowId)
      .collection('historial')
      .add({
        'lastUpdate': lastUpdate,
        'latitude': latitude,
        'longitude': longitude,
      });

  _showSnack('✅ Datos enviados correctamente a Firebase');
} catch (e) {
  _showSnack('❌ Error al enviar a Firestore: $e');
}

  }

  @override
  Widget build(BuildContext context) {
    const labelColor  = Color(0xFF143152);
    const buttonColor = Color.fromARGB(255, 81, 144, 4);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),
            SizedBox(
              height: 271.55,
              width: 256,
              child: Image.asset('assets/images/cow_logo.jpg', fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: 256,
              child: TextField(
                controller: nameController,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  labelStyle: TextStyle(color: labelColor),
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _saveLocalData(),
              ),
            ),
            const SizedBox(height: 8),
            Text('Id: $cowId', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            _infoField('Última Actualización', lastUpdate),
            const SizedBox(height: 12),
            _infoField('Latitud', latitude),
            const SizedBox(height: 12),
            _infoField('Longitud', longitude),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _actionButton('Enviar Datos', buttonColor, _sendData),
                const SizedBox(width: 16),
                _actionButton('Configurar', const Color(0xFFFF5190), _showIntervalConfig),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoField(String label, String value) => TextField(
        controller: TextEditingController(text: value),
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF143152)),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );

  Widget _actionButton(String label, Color color, VoidCallback onPressed) =>
      ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
        child: Text(label),
      );

  void _showSnack(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  void _showIntervalConfig() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Intervalo de envío automático',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _intervalOption(1),
            _intervalOption(5),
            _intervalOption(10),
          ],
        ),
      ),
    );
  }

  Widget _intervalOption(int minutes) {
    return ListTile(
      title: Text('$minutes minuto${minutes > 1 ? 's' : ''}'),
      leading: Radio<int>(
        value: minutes,
        groupValue: _intervalMinutes,
        onChanged: (value) {
          setState(() {
            _intervalMinutes = value!;
            _timer?.cancel();
            _startBackgroundUpdates();
          });
          Navigator.pop(context);
        },
      ),
    );
  }
}
