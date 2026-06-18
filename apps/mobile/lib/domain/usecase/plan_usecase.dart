import '../entity/relapse_plan.dart';
import '../../data/repository/plan_repository_impl.dart';

class PlanUseCase {
  final PlanRepository _repository;
  PlanUseCase(this._repository);

  Future<List<RelapsePlanItem>> getPlansForUser(int userId) => _repository.getPlansForUser(userId);
  Future<List<RelapsePlanItem>> getTemplatePlans() => _repository.getTemplatePlans();
  Future<int> createPlan(RelapsePlanItem plan) => _repository.insertPlan(plan);
  Future<bool> deletePlan(int id) => _repository.deletePlan(id);
}
