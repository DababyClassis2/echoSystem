import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../../models/transfer_session.dart';

// Mock active transfers
final activeTransfersProvider = StateProvider<List<TransferProgress>>((ref) => [
  TransferProgress(sessionId: "t1", fileName: "vacation_video.mp4", bytesTransferred: 450000000, totalBytes: 1200000000, speedBps: 15400000),
]);

class FilesScreen extends ConsumerWidget {
  const FilesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('File Manager'),
          bottom: const TabBar(
            tabs: [Tab(text: "RECEIVED"), Tab(text: "SENT")],
            indicatorColor: AppTheme.primaryColor,
            labelColor: AppTheme.primaryColor,
          ),
        ),
        body: Column(
          children: [
            _buildActiveTransfers(ref),
            const Expanded(
              child: TabBarView(
                children: [
                  _FileGrid(isReceived: true),
                  _FileGrid(isReceived: false),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {},
          backgroundColor: AppTheme.primaryColor,
          child: const Icon(Icons.add, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildActiveTransfers(WidgetRef ref) {
    final active = ref.watch(activeTransfersProvider);
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: AppTheme.surfaceColor.withOpacity(0.5),
      child: Column(
        children: active.map((t) => _TransferProgressBar(progress: t)).toList(),
      ),
    );
  }
}

class _TransferProgressBar extends StatelessWidget {
  final TransferProgress progress;
  const _TransferProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, size: 16, color: AppTheme.primaryColor)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 2.seconds),
              const SizedBox(width: 8),
              Expanded(child: Text(progress.fileName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis)),
              Text(progress.speedLabel, style: AppTheme.monoStyle.copyWith(fontSize: 11, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.percent,
              backgroundColor: Colors.white10,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primaryColor),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${(progress.percent * 100).toInt()}%", style: AppTheme.monoStyle.copyWith(fontSize: 10, color: Colors.grey)),
              Text("ETA: ${progress.eta}", style: AppTheme.monoStyle.copyWith(fontSize: 10, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _FileGrid extends StatelessWidget {
  final bool isReceived;
  const _FileGrid({required this.isReceived});

  @override
  Widget build(BuildContext context) {
    // Mock files
    final files = List.generate(8, (i) => {
      'name': 'Document_$i.pdf',
      'size': '2.4 MB',
      'device': 'MacBook Pro',
      'date': 'Oct 24, 2023',
    });

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: files.length,
      itemBuilder: (context, index) {
        final file = files[index];
        return _FileCard(file: file)
            .animate()
            .fadeIn(duration: 300.ms, delay: (index * 50).ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      },
    );
  }
}

class _FileCard extends StatelessWidget {
  final Map<String, String> file;
  const _FileCard({required this.file});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showFileOptions(context, file['name']!),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: const Icon(FontAwesomeIcons.filePdf, color: Colors.red, size: 20),
              ),
              const Spacer(),
              Text(file['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text(file['size']!, style: AppTheme.monoStyle.copyWith(fontSize: 10, color: Colors.grey)),
              const Divider(height: 16, color: Colors.white10),
              Row(
                children: [
                  const Icon(Icons.devices, size: 10, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(file['device']!, style: const TextStyle(fontSize: 9, color: Colors.grey), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFileOptions(BuildContext context, String fileName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ListTile(leading: const Icon(Icons.open_in_new), title: const Text("Open"), onTap: () {}),
            ListTile(leading: const Icon(Icons.share), title: const Text("Share"), onTap: () {}),
            ListTile(leading: const Icon(Icons.copy), title: const Text("Copy Path"), onTap: () {}),
            ListTile(leading: const Icon(Icons.delete, color: Colors.red), title: const Text("Delete", style: TextStyle(color: Colors.red)), onTap: () {}),
          ],
        ),
      ),
    );
  }
}
