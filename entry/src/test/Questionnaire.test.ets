import { describe, expect, it } from '@ohos/hypium';
import { BreakfastTrait, FoodFeeling, MealPeriod, SpiceLevel } from '../main/ets/models/FoodCategory';
import {
  CategoryAnswerFilters,
  getQuestionnaireQuestions,
  mergeAnswerFilters,
  QuestionnaireOption,
  QuestionnaireQuestion
} from '../main/ets/models/Questionnaire';

export default function questionnaireTest() {
  describe('Questionnaire', () => {
    it('mealPeriodUsesTwoFixedQuestions', 0, () => {
      const lunchQuestions: QuestionnaireQuestion[] = getQuestionnaireQuestions(MealPeriod.LUNCH);
      const dinnerQuestions: QuestionnaireQuestion[] = getQuestionnaireQuestions(MealPeriod.DINNER);

      expect(lunchQuestions.length).assertEqual(2);
      expect(dinnerQuestions.length).assertEqual(2);
      expect(lunchQuestions[0].id).assertEqual('meal-feeling');
      expect(lunchQuestions[1].id).assertEqual('meal-spice');
      expect(dinnerQuestions[0].id).assertEqual('meal-feeling');
      expect(dinnerQuestions[1].id).assertEqual('meal-spice');
    });

    it('breakfastUsesDedicatedTwoQuestions', 0, () => {
      const questions: QuestionnaireQuestion[] = getQuestionnaireQuestions(MealPeriod.BREAKFAST);

      expect(questions.length).assertEqual(2);
      expect(questions[0].id).assertEqual('breakfast-style');
      expect(questions[1].id).assertEqual('breakfast-appetite');
    });

    it('breakfastAnswersMergeIntoCategoryFilters', 0, () => {
      const questions: QuestionnaireQuestion[] = getQuestionnaireQuestions(MealPeriod.BREAKFAST);
      const takeaway: QuestionnaireOption = questions[0].options[1];
      const filling: QuestionnaireOption = questions[1].options[1];

      const filters: CategoryAnswerFilters = mergeAnswerFilters([takeaway, filling]);

      expect(filters.breakfastTraits?.length).assertEqual(2);
      expect(filters.breakfastTraits?.indexOf(BreakfastTrait.TAKEAWAY)).assertEqual(0);
      expect(filters.breakfastTraits?.indexOf(BreakfastTrait.FILLING)).assertEqual(1);
    });

    it('mealAnswersMergeIntoCategoryFilters', 0, () => {
      const questions: QuestionnaireQuestion[] = getQuestionnaireQuestions(MealPeriod.LUNCH);
      const refreshing: QuestionnaireOption = questions[0].options[1];
      const spicy: QuestionnaireOption = questions[1].options[2];

      const filters: CategoryAnswerFilters = mergeAnswerFilters([refreshing, spicy]);

      expect(filters.foodFeeling).assertEqual(FoodFeeling.REFRESHING);
      expect(filters.spiceLevel).assertEqual(SpiceLevel.SPICY);
    });
  });
}

