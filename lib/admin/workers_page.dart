import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../home/session_utils.dart';
import '../services/api_config.dart';
import '../services/auth_service.dart';

/// Один рабочий из списка (`GET /admin/workers` — пользователи с
/// role = 'worker' в таблице users).
class WorkerInfo {
  WorkerInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  final int id;
  final String name;
  final String email;
  final String phone;

  factory WorkerInfo.fromJson(Map<String, dynamic> json) {
    return WorkerInfo(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}') ?? 0,
      name: (json['name'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }
}

/// Вкладка администратора "Рабочие": список пользователей с ролью worker.
class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  late Future<List<WorkerInfo>> _workersFuture;

  @override
  void initState() {
    super.initState();
    _workersFuture = _loadWorkers();
  }

  Future<void> _refresh() async {
    setState(() {
      _workersFuture = _loadWorkers();
    });
    await _workersFuture;
  }

  Future<List<WorkerInfo>> _loadWorkers() async {
    final headers = await AuthService.getAuthHeaders();
    final response = await http.get(
      ApiConfig.uri('/admin/workers'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      if (mounted) {
        await redirectToSignIn(context);
      }
      throw Exception('Сессия истекла, войдите снова');
    }

    if (response.statusCode == 403) {
      throw Exception('Доступ только для администратора');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Ошибка сервера: ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map((entry) => WorkerInfo.fromJson(entry))
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: FutureBuilder<List<WorkerInfo>>(
        future: _workersFuture,
        builder: (context, snapshot) {
          final isLoading = snapshot.connectionState == ConnectionState.waiting;
          final error = snapshot.error;
          final workers = snapshot.data ?? const <WorkerInfo>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Рабочие',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Пользователи с ролью "рабочий"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                const SizedBox(height: 120),
                                Center(
                                  child: Text(
                                    'Не удалось загрузить список\n$error',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : workers.isEmpty
                              ? ListView(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  children: [
                                    const SizedBox(height: 120),
                                    Center(
                                      child: Text(
                                        'Рабочих пока нет',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : ListView.separated(
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemCount: workers.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) {
                                    final worker = workers[index];
                                    return Card(
                                      elevation: 8,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.all(16),
                                        leading: CircleAvatar(
                                          radius: 26,
                                          backgroundColor: const Color(0xFF1F6F8B).withOpacity(0.15),
                                          child: const Icon(Icons.engineering_rounded, color: Color(0xFF1F6F8B)),
                                        ),
                                        title: Text(
                                          worker.name.isEmpty ? 'Без имени' : worker.name,
                                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(top: 6),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              if (worker.email.isNotEmpty) Text('Email: ${worker.email}'),
                                              if (worker.phone.isNotEmpty) Text('Телефон: ${worker.phone}'),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
