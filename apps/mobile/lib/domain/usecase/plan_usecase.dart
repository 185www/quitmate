import '../entity/relapse_plan.dart';
import '../repository/plan_repository.dart';

class PlanUseCase {
  final PlanRepository _planRepository;

  PlanUseCase(this._planRepository);

  Future<List<RelapsePlanItem>> getPlansForUser(int userId) {
    return _planRepository.getPlansForUser(userId);
  }

  Future<List<RelapsePlanItem>> getTemplatePlans() {
    return _planRepository.getTemplatePlans();
  }

  Future<int> createPlan(RelapsePlanItem plan) {
    return _planRepository.insertPlan(plan);
  }

  Future<bool> updatePlan(RelapsePlanItem plan) {
    return _planRepository.updatePlan(plan);
  }

  Future<bool> deletePlan(int id) {
    return _planRepository.deletePlan(id);
  }

  Future<List<RelapsePlanItem>> getDefaultPlans() async {
    final templates = await _planRepository.getTemplatePlans();
    return templates;
  }
}