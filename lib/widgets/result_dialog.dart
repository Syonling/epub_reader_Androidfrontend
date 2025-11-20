import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/analysis_result.dart';

/// 分析结果弹窗
/// 支持显示 DeepSeek 返回的 JSON 格式结果
/// 增强：支持完整的日语动词变形展示
class ResultDialog extends StatelessWidget {
  final AnalysisResult result;

  const ResultDialog({Key? key, required this.result}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        width: MediaQuery.of(context).size.width * 0.9,
        child: Column(
          children: [
            // 标题栏
            _buildAppBar(context),
            
            // 可滚动内容
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: AppBar(
        title: const Text('分析结果'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    // 检查是否是 AI 分析结果（DeepSeek JSON 格式）
    if (result.analysis['method'] == 'ai_analysis') {
      return _buildAIAnalysisContent();
    } else {
      // 词典解析结果
      return _buildWordParserContent();
    }
  }

  /// 构建 AI 分析内容（DeepSeek JSON 格式）
  Widget _buildAIAnalysisContent() {
    try {
      // 解析 JSON 字符串
      final analysisResult = result.analysis['result'];
      Map<String, dynamic> parsedResult;
      
      if (analysisResult is String) {
        // 如果是字符串，需要解析
        parsedResult = jsonDecode(analysisResult);
      } else {
        // 如果已经是 Map
        parsedResult = analysisResult as Map<String, dynamic>;
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 原文
          _buildOriginalText(),
          const SizedBox(height: 16),
          
          // 翻译
          if (parsedResult.containsKey('translation'))
            _buildTranslation(parsedResult['translation']),
          const SizedBox(height: 16),
          
          // 语法点
          if (parsedResult.containsKey('grammar_points') &&
              (parsedResult['grammar_points'] as List).isNotEmpty) ...[
            _buildGrammarPoints(parsedResult['grammar_points']),
            const SizedBox(height: 16),
          ],
          
          // 词汇
          if (parsedResult.containsKey('vocabulary') &&
              (parsedResult['vocabulary'] as List).isNotEmpty) ...[
            _buildVocabulary(parsedResult['vocabulary']),
            const SizedBox(height: 16),
          ],
          
          // 特殊说明
          if (parsedResult.containsKey('special_notes') &&
              (parsedResult['special_notes'] as List).isNotEmpty)
            _buildSpecialNotes(parsedResult['special_notes']),
        ],
      );
    } catch (e) {
      // 解析失败，显示原始文本
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOriginalText(),
          const SizedBox(height: 16),
          const Text(
            '❌ 解析失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text('错误: $e'),
          const SizedBox(height: 16),
          const Text('原始结果:'),
          Text(result.analysis['result'].toString()),
        ],
      );
    }
  }

  /// 构建词典解析内容
  Widget _buildWordParserContent() {
    try {
      // 获取词典解析结果
      final analysisResult = result.analysis['result'];
      Map<String, dynamic> parsedResult;
      
      if (analysisResult is String) {
        // 如果是字符串，需要解析
        parsedResult = jsonDecode(analysisResult);
      } else {
        // 如果已经是对象，直接使用
        parsedResult = analysisResult as Map<String, dynamic>;
      }
      
      // 使用与AI分析相同的格式显示
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOriginalText(),
          const SizedBox(height: 16),
          
          // 翻译
          if (parsedResult['translation'] != null)
            _buildTranslation(parsedResult['translation']),
          
          const SizedBox(height: 16),
          
          // 语法点
          if (parsedResult['grammar_points'] != null && 
              (parsedResult['grammar_points'] as List).isNotEmpty)
            _buildGrammarPoints(parsedResult['grammar_points']),
          
          const SizedBox(height: 16),
          
          // 词汇
          if (parsedResult['vocabulary'] != null)
            _buildVocabulary(parsedResult['vocabulary']),
          
          const SizedBox(height: 16),
          
          // 特殊说明
          if (parsedResult['special_notes'] != null &&
              (parsedResult['special_notes'] as List).isNotEmpty)
            _buildSpecialNotes(parsedResult['special_notes']),
        ],
      );
    } catch (e) {
      // 解析失败，显示错误
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOriginalText(),
          const SizedBox(height: 16),
          const Text(
            '❌ 解析失败',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text('错误: $e'),
          const SizedBox(height: 16),
          const Text('原始结果:'),
          Text(result.analysis['result'].toString()),
        ],
      );
    }
  }

  Widget _buildOriginalText() {
    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📄 原文',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.originalText,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslation(String translation) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📖 翻译',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              translation,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrammarPoints(List<dynamic> grammarPoints) {
    return ExpansionTile(
      title: Text(
        '📚 语法点 (${grammarPoints.length})',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: true,
      children: grammarPoints.map((grammar) {
        final g = grammar as Map<String, dynamic>;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    g['pattern'] ?? '',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(g['level'] ?? ''),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    g['level'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(g['explanation'] ?? ''),
                const SizedBox(height: 4),
                // Text(
                //   '例：${g['example_in_sentence'] ?? ''}',
                //   style: TextStyle(
                //     fontSize: 14,
                //     color: Colors.grey.shade600,
                //     fontStyle: FontStyle.italic,
                //   ),
                // ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildVocabulary(List<dynamic> vocabulary) {
    return ExpansionTile(
      title: Text(
        '📝 词汇 (${vocabulary.length})',
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      initiallyExpanded: true,
      children: vocabulary.map((vocab) {
        final v = vocab as Map<String, dynamic>;
        final conjugation = v['conjugation'] as Map<String, dynamic>? ?? {};
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 词汇标题
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            v['word'] ?? '',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if ((v['reading'] ?? '').isNotEmpty)
                            Text(
                              v['reading'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getLevelColor(v['level'] ?? ''),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        v['level'] ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // 意思
                if ((v['meaning'] ?? '').isNotEmpty)
                  Text(
                    '意思：${v['meaning']}',
                    style: const TextStyle(fontSize: 15),
                  ),
                
                // 活用信息
                if (conjugation['has_conjugation'] == true) ...[
                  const Divider(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 基本活用信息
                        Text(
                          '原型：${conjugation['original_form'] ?? ''}',
                          style: const TextStyle(fontSize: 14),
                        ),
                        if ((conjugation['current_form'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          // Text(
                          //   '当前形式：${conjugation['current_form']}',
                          //   style: const TextStyle(
                          //     fontSize: 14,
                          //     fontWeight: FontWeight.w500,
                          //   ), 
                          // ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          '变形：${conjugation['conjugation_type'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if ((conjugation['reason'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '原因：${conjugation['reason']}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                        
                        // ⭐ 动词类型信息
                        if (conjugation['verb_class'] != null &&
                            conjugation['verb_class'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: Colors.green.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              conjugation['verb_class'].toString(),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                        
                        // ⭐ 自他动词
                        if (conjugation['transitivity'] != null &&
                            conjugation['transitivity'].toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            conjugation['transitivity'].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        
                        // ⭐ 折叠框：所有活用形式（默认折叠）
                        if (conjugation.containsKey('all_forms') &&
                            conjugation['all_forms'] is Map) ...[
                          const SizedBox(height: 12),
                          ExpansionTile(
                            title: const Text(
                              '📖 所有活用形式',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            initiallyExpanded: false, // ⭐ 默认折叠
                            children: [
                              const SizedBox(height: 8),
                              _buildVerbFormsGrid(
                                conjugation['all_forms'] as Map<String, dynamic>,
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// ⭐ 构建动词变形网格
  Widget _buildVerbFormsGrid(Map<String, dynamic> allForms) {
    // 定义变形的显示顺序和名称
    final formDefinitions = [
      {'key': 'dictionary_form', 'name': '辞书形', 'color': Colors.blue},
      {'key': 'masu_form', 'name': 'ます形', 'color': Colors.green},
      {'key': 'te_form', 'name': 'て形', 'color': Colors.orange},
      {'key': 'ta_form', 'name': 'た形', 'color': Colors.orange},
      {'key': 'nai_form', 'name': 'ない形', 'color': Colors.red},
      {'key': 'nakatta_form', 'name': 'なかった形', 'color': Colors.red},
      {'key': 'ba_form', 'name': 'ば形', 'color': Colors.purple},
      {'key': 'command_form', 'name': '命令形', 'color': Colors.pink},
      {'key': 'volitional_form', 'name': '意志形', 'color': Colors.indigo},
      {'key': 'passive_form', 'name': '受身形', 'color': Colors.teal},
      {'key': 'causative_form', 'name': '使役形', 'color': Colors.amber},
      {'key': 'potential_form', 'name': '可能形', 'color': Colors.cyan},
      {'key': 'causative_passive_form', 'name': '使役受身形', 'color': Colors.brown},
    ];
    
    return Column(
      children: formDefinitions.where((def) {
        // 只显示存在的变形
        final key = def['key'] as String;
        return allForms.containsKey(key) && 
               allForms[key] != null &&
               allForms[key].toString().isNotEmpty &&
               !allForms[key].toString().contains('待实现') &&
               !allForms[key].toString().contains('需要');
      }).map((def) {
        final formKey = def['key'] as String;
        final formName = def['name'] as String;
        final formColor = def['color'] as Color;
        final formValue = allForms[formKey].toString();
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 变形名称标签
              Container(
                width: 95,
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: formColor.withAlpha(38),  // 0.15 * 255 ≈ 38
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: formColor.withAlpha(102),  // 0.4 * 255 ≈ 102
                    width: 1,
                  ),
                ),
                child: Text(
                  formName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color.lerp(formColor, Colors.black, 0.6)!,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 8),
              
              // 变形结果
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    formValue,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSpecialNotes(List<dynamic> specialNotes) {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️ 特殊说明',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            ...specialNotes.map((note) {
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        note.toString(),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'N1':
        return Colors.red;
      case 'N2':
        return Colors.orange;
      case 'N3以下':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _formatAnalysis(Map<String, dynamic> analysis) {
    return analysis.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('\n');
  }
}