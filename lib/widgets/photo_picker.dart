import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:sekolahku/core/theme.dart';
import 'package:sekolahku/services/firebase_service.dart' as firebase_service;
import 'package:sekolahku/widgets/widgets.dart';

/// Pilih & unggah satu foto ke Firebase Storage, tampilkan preview.
/// `onChanged` dipanggil dengan URL download (atau null jika dihapus).
class PhotoPicker extends StatefulWidget {
  final String folder; // subfolder penyimpanan (mis. 'mading')
  final String? initialUrl;
  final ValueChanged<String?> onChanged;
  const PhotoPicker({
    super.key,
    required this.folder,
    this.initialUrl,
    required this.onChanged,
  });

  @override
  State<PhotoPicker> createState() => _PhotoPickerState();
}

class _PhotoPickerState extends State<PhotoPicker> {
  String? _url;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _url = widget.initialUrl;
  }

  Future<void> _pick() async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 82,
    );
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final url = await firebase_service.FirebaseService.i.uploadImage(
        folder: widget.folder,
        filename: file.name,
        bytes: bytes,
      );
      if (!mounted) return;
      if (url == null) {
        toast(context, 'Gagal mengunggah foto');
      } else {
        setState(() => _url = url);
        widget.onChanged(url);
      }
    } catch (e) {
      debugPrint('PhotoPicker error: $e');
      if (mounted) toast(context, 'Gagal mengunggah foto');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _clear() {
    setState(() => _url = null);
    widget.onChanged(null);
  }

  @override
  Widget build(BuildContext context) {
    if (_uploading) {
      return const Card2(
        padding: EdgeInsets.all(12),
        child: Row(children: [
          SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2)),
          SizedBox(width: 12),
          Text('Mengunggah foto…'),
        ]),
      );
    }

    if (_url != null) {
      return Column(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            _url!,
            height: 180,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (c, e, s) => Container(
              height: 90,
              width: double.infinity,
              color: kSoft,
              alignment: Alignment.center,
              child: const Text('⚠️ Gambar gagal dimuat'),
            ),
          ),
        ),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          TextButton.icon(
              onPressed: _pick,
              icon: const Icon(Icons.refresh),
              label: const Text('Ganti')),
          TextButton.icon(
              onPressed: _clear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus')),
        ]),
      ]);
    }

    return OutlinedButton.icon(
      onPressed: _pick,
      icon: const Icon(Icons.add_a_photo_outlined),
      label: const Text('Tambah foto / lampiran'),
    );
  }
}