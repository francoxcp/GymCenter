import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/services/notification_service.dart';

class Achievement {
  final String id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final int points;
  final DateTime createdAt;

  Achievement({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.points,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      description: json['description'],
      icon: json['icon'],
      points: json['points'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  Achievement? achievement; // Relación con Achievement

  UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'],
      userId: json['user_id'],
      achievementId: json['achievement_id'],
      unlockedAt: DateTime.parse(json['unlocked_at']),
      achievement: json['achievements'] != null
          ? Achievement.fromJson(json['achievements'])
          : null,
    );
  }
}

class AchievementsProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _unlockedAchievements = [];
  bool _isLoading = false;
  String? _error;

  List<Achievement> get allAchievements => _allAchievements;
  List<UserAchievement> get unlockedAchievements => _unlockedAchievements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalPoints {
    return _unlockedAchievements.fold(0, (sum, ua) {
      return sum + (ua.achievement?.points ?? 0);
    });
  }

  int get unlockedCount => _unlockedAchievements.length;
  int get totalCount => _allAchievements.length;

  /// Cargar todos los logros disponibles
  Future<void> loadAllAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _supabase
          .from('achievements')
          .select()
          .order('points', ascending: true);

      _allAchievements =
          (response as List).map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      _error = 'Error al cargar logros: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Cargar logros desbloqueados del usuario
  Future<void> loadUnlockedAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      final response = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);

      _unlockedAchievements = (response as List)
          .map((json) => UserAchievement.fromJson(json))
          .toList();
    } catch (e) {
      _error = 'Error al cargar logros desbloqueados: $e';
      debugPrint(_error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verificar si un logro está desbloqueado
  bool isUnlocked(String achievementCode) {
    return _unlockedAchievements
        .any((ua) => ua.achievement?.code == achievementCode);
  }

  /// Desbloquear un logro
  Future<bool> unlockAchievement(String achievementCode,
      {bool showNotification = true}) async {
    // Verificar si ya está desbloqueado
    if (isUnlocked(achievementCode)) {
      return false;
    }

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Usuario no autenticado');
      }

      // Buscar el logro por código
      final achievement = _allAchievements.firstWhere(
        (a) => a.code == achievementCode,
        orElse: () => throw Exception('Logro no encontrado'),
      );

      // Insertar en user_achievements
      final response = await _supabase
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_id': achievement.id,
          })
          .select('*, achievements(*)')
          .single();

      final userAchievement = UserAchievement.fromJson(response);
      _unlockedAchievements.insert(0, userAchievement);

      // Mostrar notificación del logro
      if (showNotification) {
        await NotificationService().showAchievementNotification(
          achievementName: achievement.name,
          points: achievement.points,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Error al desbloquear logro: $e';
      debugPrint(_error);
      return false;
    }
  }

  /// Verificar y desbloquear logros automáticamente
  Future<void> checkAndUnlockAchievements({
    int? totalWorkouts,
    int? currentStreak,
    double? weightLoss,
  }) async {
    // Primer entrenamiento
    if (totalWorkouts == 1 && !isUnlocked('first_workout')) {
      await unlockAchievement('first_workout');
    }

    // Primera semana
    if (totalWorkouts == 7 && !isUnlocked('first_week')) {
      await unlockAchievement('first_week');
    }

    // 10 entrenamientos
    if (totalWorkouts != null &&
        totalWorkouts >= 10 &&
        !isUnlocked('ten_workouts')) {
      await unlockAchievement('ten_workouts');
    }

    // Racha de 7 días
    if (currentStreak != null &&
        currentStreak >= 7 &&
        !isUnlocked('streak_7')) {
      await unlockAchievement('streak_7');
    }

    // Racha de 30 días
    if (currentStreak != null &&
        currentStreak >= 30 &&
        !isUnlocked('streak_30')) {
      await unlockAchievement('streak_30');
    }

    // Pérdida de 5kg
    if (weightLoss != null &&
        weightLoss >= 5.0 &&
        !isUnlocked('weight_loss_5kg')) {
      await unlockAchievement('weight_loss_5kg');
    }
  }
}
