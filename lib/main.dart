import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const ExpenseApp());

final currency = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
const categories = ['Alimentação', 'Transporte', 'Moradia', 'Lazer', 'Saúde', 'Outros'];
const colors = [Colors.orange, Colors.blue, Colors.purple, Colors.green, Colors.red, Colors.grey];

class Entry {
  final String description;
  final double amount;
  final String category;
  final bool isIncome;
  final DateTime date;

  Entry(this.description, this.amount, this.category, this.isIncome, this.date);

  Map<String, dynamic> toJson() => {
        'd': description, 'a': amount, 'c': category, 'i': isIncome, 't': date.toIso8601String(),
      };

  factory Entry.fromJson(Map<String, dynamic> j) =>
      Entry(j['d'], (j['a'] as num).toDouble(), j['c'], j['i'], DateTime.parse(j['t']));
}

class ExpenseApp extends StatelessWidget {
  const ExpenseApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Meus Gastos',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Entry> entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('entries') ?? [];
    setState(() => entries = raw.map((e) => Entry.fromJson(jsonDecode(e))).toList());
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('entries', entries.map((e) => jsonEncode(e.toJson())).toList());
  }

  double get income => entries.where((e) => e.isIncome).fold(0, (s, e) => s + e.amount);
  double get expenses => entries.where((e) => !e.isIncome).fold(0, (s, e) => s + e.amount);

  Map<String, double> get byCategory {
    final map = <String, double>{};
    for (final e in entries.where((e) => !e.isIncome)) {
      map[e.category] = (map[e.category] ?? 0) + e.amount;
    }
    return map;
  }

  void _openForm() {
    final desc = TextEditingController();
    final amount = TextEditingController();
    String category = categories.first;
    bool isIncome = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Despesa')),
                ButtonSegment(value: true, label: Text('Receita')),
              ],
              selected: {isIncome},
              onSelectionChanged: (s) => setModal(() => isIncome = s.first),
            ),
            TextField(controller: desc, decoration: const InputDecoration(labelText: 'Descrição')),
            TextField(
              controller: amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Valor (R\$)'),
            ),
            if (!isIncome)
              DropdownButtonFormField<String>(
                value: category,
                items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setModal(() => category = v!),
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final value = double.tryParse(amount.text.replaceAll(',', '.'));
                if (desc.text.isEmpty || value == null || value <= 0) return;
                setState(() => entries.insert(
                    0, Entry(desc.text, value, isIncome ? 'Receita' : category, isIncome, DateTime.now())));
                _save();
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cats = byCategory;
    return Scaffold(
      appBar: AppBar(title: const Text('💰 Meus Gastos')),
      floatingActionButton: FloatingActionButton(onPressed: _openForm, child: const Icon(Icons.add)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text('Saldo'),
              Text(currency.format(income - expenses),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                Text('⬆ ${currency.format(income)}', style: const TextStyle(color: Colors.green)),
                Text('⬇ ${currency.format(expenses)}', style: const TextStyle(color: Colors.red)),
              ]),
            ]),
          ),
        ),
        if (cats.isNotEmpty)
          SizedBox(
            height: 200,
            child: PieChart(PieChartData(
              sections: cats.entries.map((e) {
                final i = categories.indexOf(e.key);
                return PieChartSectionData(
                  value: e.value,
                  title: e.key,
                  color: colors[i < 0 ? colors.length - 1 : i],
                  radius: 70,
                  titleStyle: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                );
              }).toList(),
            )),
          ),
        const SizedBox(height: 12),
        ...entries.asMap().entries.map((item) {
          final e = item.value;
          return Dismissible(
            key: ValueKey('${e.date.toIso8601String()}-${item.key}'),
            background: Container(color: Colors.red),
            onDismissed: (_) {
              setState(() => entries.removeAt(item.key));
              _save();
            },
            child: ListTile(
              leading: Icon(e.isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: e.isIncome ? Colors.green : Colors.red),
              title: Text(e.description),
              subtitle: Text('${e.category} · ${DateFormat('dd/MM/yyyy').format(e.date)}'),
              trailing: Text(currency.format(e.amount)),
            ),
          );
        }),
      ]),
    );
  }
}
