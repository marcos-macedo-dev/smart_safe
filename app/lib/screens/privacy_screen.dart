import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PrivacyScreen extends StatefulWidget {
  const PrivacyScreen({super.key});

  @override
  State<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends State<PrivacyScreen> {
  bool _location = false;
  bool _camera = false;
  bool _microphone = false;
  bool _contacts = false;
  bool _photos = false;
  bool _videos = false;
  bool _audio = false;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final loc = await Permission.location.isGranted;
    final cam = await Permission.camera.isGranted;
    final mic = await Permission.microphone.isGranted;
    final contacts = await Permission.contacts.isGranted;
    final photos = await Permission.photos.isGranted;
    final videos = await Permission.videos.isGranted;
    final audio = await Permission.audio.isGranted;


    setState(() {
      _location = loc;
      _camera = cam;
      _microphone = mic;
      _contacts = contacts;
      _photos = photos;
      _videos = videos;
      _audio = audio;
    });
  }

  Future<void> _requestPermission(
    Permission permission,
    ValueChanged<bool> setter,
  ) async {
    final status = await permission.request();
    setter(status.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacidade'),
        centerTitle: true,
        elevation: 1,
      ),
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPermissionCard(
                icon: Icons.location_on,
                title: 'Localização',
                subtitle: 'Permitir acesso à localização',
                value: _location,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.location, (granted) {
                      setState(() => _location = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
              _buildPermissionCard(
                icon: Icons.camera_alt,
                title: 'Câmera',
                subtitle: 'Permitir acesso à câmera',
                value: _camera,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.camera, (granted) {
                      setState(() => _camera = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
              _buildPermissionCard(
                icon: Icons.mic,
                title: 'Microfone',
                subtitle: 'Permitir acesso ao microfone',
                value: _microphone,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.microphone, (granted) {
                      setState(() => _microphone = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
              _buildPermissionCard(
                icon: Icons.contacts,
                title: 'Contatos',
                subtitle: 'Permitir acesso aos contatos',
                value: _contacts,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.contacts, (granted) {
                      setState(() => _contacts = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
              _buildPermissionCard(
                icon: Icons.photo,
                title: 'Fotos',
                subtitle: 'Permitir acesso às fotos',
                value: _photos,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.photos, (granted) {
                      setState(() => _photos = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
              _buildPermissionCard(
                icon: Icons.video_library,
                title: 'Vídeos',
                subtitle: 'Permitir acesso aos vídeos',
                value: _videos,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.videos, (granted) {
                      setState(() => _videos = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
              _buildPermissionCard(
                icon: Icons.music_note,
                title: 'Música e Áudio',
                subtitle: 'Permitir acesso a música e áudio',
                value: _audio,
                onChanged: (val) {
                  if (val) {
                    _requestPermission(Permission.audio, (granted) {
                      setState(() => _audio = granted);
                    });
                  } else {
                    openAppSettings();
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        secondary: Icon(icon, color: theme.colorScheme.primary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
