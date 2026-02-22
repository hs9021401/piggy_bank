import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
import '../services/database_service.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  final DataRefreshNotifier refreshNotifier;

  const SettingsScreen({super.key, required this.refreshNotifier});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isPasswordEnabled = false;
  Map<String, double> _budgets = {};
  List<Map<String, dynamic>> _periodicTransactions = [];
  String? _lastExportedFile;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isPasswordEnabled = prefs.getBool('password_enabled') ?? false;
      final budgetsJson = prefs.getString('budgets');
      if (budgetsJson != null) {
        _budgets = Map<String, double>.from(json.decode(budgetsJson));
      }
      final periodicJson = prefs.getString('periodic_transactions');
      if (periodicJson != null) {
        _periodicTransactions = List<Map<String, dynamic>>.from(
          json.decode(periodicJson),
        );
      }
      _lastExportedFile = prefs.getString('last_exported_file');
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('password_enabled', _isPasswordEnabled);
    await prefs.setString('budgets', json.encode(_budgets));
    await prefs.setString(
      'periodic_transactions',
      json.encode(_periodicTransactions),
    );
    if (_lastExportedFile != null) {
      await prefs.setString('last_exported_file', _lastExportedFile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('安全', [
            _buildSwitchTile(
              '密碼鎖',
              '開啟App時需要輸入密碼',
              Icons.lock,
              _isPasswordEnabled,
              (value) {
                setState(() {
                  _isPasswordEnabled = value;
                });
                _saveSettings();
                if (value) {
                  _showSetPasswordDialog();
                }
              },
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('預算管理', [
            _buildTile(
              '每月預算設定',
              '設定各分類的每月預算',
              Icons.account_balance_wallet,
              () => _showBudgetDialog(),
            ),
            _buildTile(
              '預算提醒',
              '超支時通知',
              Icons.notifications,
              () => _showBudgetAlertDialog(),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('週期性記錄', [
            _buildTile(
              '新增週期性支出',
              '房租、訂閱等固定支出',
              Icons.repeat,
              () => _showPeriodicDialog(),
            ),
            _buildTile(
              '管理週期性記錄',
              '檢視或刪除週期記錄',
              Icons.list,
              () => _showPeriodicListDialog(),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection('資料管理', [
            _buildTile('匯出資料', '匯出為CSV格式', Icons.download, () => _exportData()),
            _buildTile(
              '開啟上次匯出的檔案',
              '在預設應用程式中開啟',
              Icons.open_in_new,
              () => _openLastExportedFile(),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6BCB77),
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6BCB77).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6BCB77)),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF6BCB77).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF6BCB77)),
      ),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF6BCB77),
      ),
    );
  }

  void _showSetPasswordDialog() {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定密碼'),
        content: TextField(
          controller: passwordController,
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: '輸入4位數密碼',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (passwordController.text.length == 4) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('password', passwordController.text);
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  void _showBudgetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('設定預算'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final category in [
                'food',
                'transport',
                'shopping',
                'entertainment',
                'bills',
                'health',
                'education',
                'other_expense',
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _getCategoryName(category),
                      prefixText: 'NT\$ ',
                      border: const OutlineInputBorder(),
                    ),
                    controller: TextEditingController(
                      text: _budgets[category]?.toString() ?? '',
                    ),
                    onChanged: (value) {
                      _budgets[category] = double.tryParse(value) ?? 0;
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _saveSettings();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('預算已儲存')));
            },
            child: const Text('儲存'),
          ),
        ],
      ),
    );
  }

  String _getCategoryName(String id) {
    final names = {
      'food': '餐飲',
      'transport': '交通',
      'shopping': '購物',
      'entertainment': '娛樂',
      'bills': '帳單',
      'health': '醫療',
      'education': '教育',
      'other_expense': '其他',
    };
    return names[id] ?? id;
  }

  void _showBudgetAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('預算提醒'),
        content: const Text('當支出超過預算時會發送通知提醒'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }

  void _showPeriodicDialog() {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'bills';
    int frequency = 1;
    DateTime startDate = DateTime.now();
    DateTime? endDate;
    bool isEndless = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新增週期性支出'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: '金額',
                    prefixText: 'NT\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteController,
                  decoration: const InputDecoration(
                    labelText: '備註（必填）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: '分類',
                    border: OutlineInputBorder(),
                  ),
                  items:
                      [
                            'food',
                            'transport',
                            'shopping',
                            'entertainment',
                            'bills',
                            'health',
                            'education',
                            'other_expense',
                          ]
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(_getCategoryName(e)),
                            ),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedCategory = value!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: '頻率',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 1, child: Text('每月')),
                    DropdownMenuItem(value: 3, child: Text('每季')),
                    DropdownMenuItem(value: 6, child: Text('每半年')),
                    DropdownMenuItem(value: 12, child: Text('每年')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => frequency = value!),
                ),
                const SizedBox(height: 16),
                const Text('開始日期', style: TextStyle(color: Colors.grey)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setDialogState(() => startDate = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '${startDate.year}/${startDate.month}/${startDate.day}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: isEndless,
                      onChanged: (value) {
                        setDialogState(() {
                          isEndless = value!;
                          if (isEndless) endDate = null;
                        });
                      },
                    ),
                    const Text('無期限'),
                  ],
                ),
                if (!isEndless) ...[
                  const SizedBox(height: 8),
                  const Text('結束日期', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            endDate ??
                            DateTime.now().add(const Duration(days: 365)),
                        firstDate: startDate,
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setDialogState(() => endDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            endDate != null
                                ? '${endDate!.year}/${endDate!.month}/${endDate!.day}'
                                : '選擇結束日期',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (amountController.text.isNotEmpty &&
                    noteController.text.isNotEmpty) {
                  final periodicId = DateTime.now().millisecondsSinceEpoch
                      .toString();
                  _periodicTransactions.add({
                    'id': periodicId,
                    'amount': double.parse(amountController.text),
                    'note': noteController.text,
                    'categoryId': selectedCategory,
                    'frequency': frequency,
                    'startDate': startDate.millisecondsSinceEpoch,
                    'endDate': endDate?.millisecondsSinceEpoch,
                  });
                  await _saveSettings();
                  await DatabaseService.instance.processPeriodicTransactions();

                  if (mounted) {
                    Navigator.pop(context);
                    widget.refreshNotifier.refresh();
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('週期性支出已新增')));
                  }
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('請填寫金額和備註')));
                  }
                }
              },
              child: const Text('儲存'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPeriodicListDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('週期性記錄'),
          content: SizedBox(
            width: double.maxFinite,
            child: _periodicTransactions.isEmpty
                ? const Text('尚無週期性記錄')
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: _periodicTransactions.length,
                    itemBuilder: (context, index) {
                      final item = _periodicTransactions[index];
                      final startTimestamp = item['startDate'] as int?;
                      final endTimestamp = item['endDate'] as int?;
                      final startDate = startTimestamp != null
                          ? DateTime.fromMillisecondsSinceEpoch(startTimestamp)
                          : DateTime.now();
                      final endDate = endTimestamp != null
                          ? DateTime.fromMillisecondsSinceEpoch(endTimestamp)
                          : null;

                      return ListTile(
                        title: Text('NT\$ ${item['amount']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['note'] ??
                                  _getCategoryName(item['categoryId']),
                            ),
                            Text(
                              '${startDate.year}/${startDate.month}/${startDate.day} ~ ${endDate != null ? '${endDate.year}/${endDate.month}/${endDate.day}' : '無期限'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await _saveSettings();
                            widget.refreshNotifier.refresh();
                            setDialogState(() {
                              _periodicTransactions.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('關閉'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final db = DatabaseService.instance;
      final transactions = await db.getTransactions();
      final categories = await db.getCategories(null);

      final categoryMap = {for (var c in categories) c.id: c.name};

      final csv = StringBuffer();
      csv.writeln('日期,類型,分類,金額,備註,發票號碼');

      for (final t in transactions) {
        final date =
            '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}-${t.date.day.toString().padLeft(2, '0')}';
        final type = t.type == TransactionType.income ? '收入' : '支出';
        final category = categoryMap[t.categoryId] ?? t.categoryId;
        final note = t.note.replaceAll(',', ' ');
        final invoice = t.invoiceNumber ?? '';

        csv.writeln('$date,$type,$category,${t.amount},$note,$invoice');
      }

      final directory = await getExternalStorageDirectory();
      final downloadDir = Directory('${directory!.path}/Download');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      final file = File(
        '${downloadDir.path}/piggy_bank_export_${DateTime.now().millisecondsSinceEpoch}.csv',
      );
      await file.writeAsString(csv.toString());
      _lastExportedFile = file.path;
      await _saveSettings();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已匯出至：${file.path}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('匯出失敗：$e')));
      }
    }
  }

  Future<void> _openLastExportedFile() async {
    if (_lastExportedFile == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('尚未匯出資料，請先匯出')));
      }
      return;
    }

    final file = File(_lastExportedFile!);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('找不到上次匯出的檔案')));
      }
      return;
    }

    bool hasPermission = false;
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ 不需要傳統 storage 權限來開啟自己應用的檔案
        hasPermission = true;
      } else {
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          status = await Permission.storage.request();
        }
        hasPermission = status.isGranted;
      }
    } else {
      hasPermission = true; // 其他平台暫不處理詳細權限
    }

    if (hasPermission) {
      final result = await OpenFilex.open(_lastExportedFile!);
      if (result.type != ResultType.done) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('無法開啟檔案：${_translateOpenResult(result.type)}')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('需要儲存權限才能開啟檔案')));
      }
    }
  }

  String _translateOpenResult(ResultType type) {
    switch (type) {
      case ResultType.fileNotFound:
        return '找不到檔案';
      case ResultType.noAppToOpen:
        return '找不到可開啟此格式的應用程式';
      case ResultType.permissionDenied:
        return '存取被拒絕';
      default:
        return '發生未知錯誤';
    }
  }
}
