import 'package:flutter/material.dart';
import '../services/api_service.dart';

class LlmSelector extends StatefulWidget {
  const LlmSelector({super.key});

  @override
  State<LlmSelector> createState() => _LlmSelectorState();
}

class _LlmSelectorState extends State<LlmSelector> {
  String _currentProvider = 'echo';
  List<Map<String, dynamic>> _providers = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await ApiService.getProviders();
      if (data != null && mounted) {
        setState(() {
          _currentProvider = data['current'] ?? 'echo';
          _providers = List<Map<String, dynamic>>.from(data['providers'] ?? []);
        });
      }
    } catch (e) {
      print('加载提供商失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _switchProvider(String providerId) async {
    if (providerId == _currentProvider) return;

    setState(() => _isLoading = true);

    try {
      final success = await ApiService.switchProvider(providerId);
      if (success && mounted) {
        setState(() {
          _currentProvider = providerId;
        });
        
        // 可选：显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('已切换到 ${_getProviderName(providerId)}'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('切换提供商失败: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getProviderName(String providerId) {
    final provider = _providers.firstWhere(
      (p) => p['id'] == providerId,
      orElse: () => {'display_name': providerId},
    );
    return provider['display_name'] ?? providerId;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    return PopupMenuButton<String>(
      icon: const Icon(Icons.psychology),
      tooltip: 'AI提供商: $_currentProvider',
      onSelected: _switchProvider,
      itemBuilder: (context) {
        return _providers.map((provider) {
          final id = provider['id'] as String;
          final name = provider['display_name'] as String;
          final status = provider['status'] as String;
          final isCurrent = id == _currentProvider;

          return PopupMenuItem<String>(
            value: id,
            child: Row(
              children: [
                // 当前选中标记
                if (isCurrent)
                  const Icon(Icons.check, size: 18, color: Colors.blue),
                if (isCurrent) const SizedBox(width: 8),
                
                // 提供商名称
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                
                // 状态指示
                if (status == 'needs_key')
                  const Icon(Icons.warning, size: 16, color: Colors.orange),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}