import '../../domain/entity/relapse_plan.dart';
import '../database/app_database.dart';

class PlanRepository {
  final AppDatabase _database;
  PlanRepository(this._database);

  Future<List<RelapsePlanItem>> getPlansForUser(int userId) async {
    final plans = await _database.getRelapsePlansForUser(userId);
    return plans.map((p) => _mapToPlan(p)).toList();
  }

  Future<List<RelapsePlanItem>> getTemplatePlans() async {
    final plans = await _database.getTemplatePlans();
    return plans.map((p) => _mapToPlan(p)).toList();
  }

  Future<int> insertPlan(RelapsePlanItem plan) async {
    return _database.insertRelapsePlan({
      'user_id': plan.userId,
      'situation': plan.situation,
      'trigger': plan.trigger,
      'coping_plan': plan.copingPlan,
      'priority': plan.priority,
      'is_template': plan.isTemplate ? 1 : 0,
    });
  }

  Future<bool> deletePlan(int id) async {
    final rows = await _database.deleteRelapsePlan(id);
    return rows > 0;
  }

  RelapsePlanItem _mapToPlan(Map<String, dynamic> p) => RelapsePlanItem(
    id: p['id'] as int,
    userId: p['user_id'] as int,
    situation: p['situation'] as String,
    trigger: p['trigger'] as String?,
    copingPlan: p['coping_plan'] as String,
    priority: p['priority'] as int? ?? 0,
    isTemplate: (p['is_template'] as int?) == 1,
  );
}