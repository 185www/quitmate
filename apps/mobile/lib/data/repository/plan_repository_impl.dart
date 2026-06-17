import '../../domain/entity/relapse_plan.dart';
import '../../domain/repository/plan_repository.dart';
import '../database/app_database.dart';

class PlanRepositoryImpl implements PlanRepository {
  final AppDatabase _database;

  PlanRepositoryImpl(this._database);

  @override
  Future<List<RelapsePlanItem>> getPlansForUser(int userId) async {
    final plans = await _database.getRelapsePlansForUser(userId);
    return plans
        .map((p) => RelapsePlanItem(
              id: p.id,
              userId: p.userId,
              situation: p.situation,
              trigger: p.trigger,
              copingPlan: p.copingPlan,
              priority: p.priority,
              isTemplate: p.isTemplate,
            ))
        .toList();
  }

  @override
  Future<List<RelapsePlanItem>> getTemplatePlans() async {
    final plans = await _database.getTemplatePlans();
    return plans
        .map((p) => RelapsePlanItem(
              id: p.id,
              userId: p.userId,
              situation: p.situation,
              trigger: p.trigger,
              copingPlan: p.copingPlan,
              priority: p.priority,
              isTemplate: p.isTemplate,
            ))
        .toList();
  }

  @override
  Future<int> insertPlan(RelapsePlanItem plan) async {
    return await _database.insertRelapsePlan(
      RelapsePlanCompanion.insert(
        userId: plan.userId,
        situation: plan.situation,
        trigger: plan.trigger != null ? Value(plan.trigger!) : const Value.absent(),
        copingPlan: plan.copingPlan,
        priority: Value(plan.priority),
        isTemplate: Value(plan.isTemplate),
      ),
    );
  }

  @override
  Future<bool> updatePlan(RelapsePlanItem plan) async {
    return true;
  }

  @override
  Future<bool> deletePlan(int id) async {
    return await _database.deleteRelapsePlan(id);
  }
}