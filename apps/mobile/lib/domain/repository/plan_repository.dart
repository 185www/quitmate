import '../entity/relapse_plan.dart';

abstract class PlanRepository {
  Future<List<RelapsePlanItem>> getPlansForUser(int userId);
  Future<List<RelapsePlanItem>> getTemplatePlans();
  Future<int> insertPlan(RelapsePlanItem plan);
  Future<bool> updatePlan(RelapsePlanItem plan);
  Future<bool> deletePlan(int id);
}