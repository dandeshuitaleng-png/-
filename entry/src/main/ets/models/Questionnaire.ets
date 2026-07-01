import { BreakfastTrait, FoodFeeling, MealPeriod, SpiceLevel } from './FoodCategory';

export interface CategoryAnswerFilters {
  foodFeeling?: FoodFeeling;
  spiceLevel?: SpiceLevel;
  breakfastTraits?: BreakfastTrait[];
}

export interface QuestionnaireOption {
  id: string;
  label: string;
  answerFilters: CategoryAnswerFilters;
}

export interface QuestionnaireQuestion {
  id: string;
  title: string;
  options: QuestionnaireOption[];
}

const BREAKFAST_QUESTIONS: QuestionnaireQuestion[] = [
  {
    id: 'breakfast-style',
    title: '想吃热食还是方便带走的？',
    options: [
      {
        id: 'breakfast-warm',
        label: '热乎现吃',
        answerFilters: {
          foodFeeling: FoodFeeling.WARM
        }
      },
      {
        id: 'breakfast-takeaway',
        label: '方便带走',
        answerFilters: {
          breakfastTraits: [BreakfastTrait.TAKEAWAY]
        }
      }
    ]
  },
  {
    id: 'breakfast-appetite',
    title: '想吃清淡的还是更管饱的？',
    options: [
      {
        id: 'breakfast-light',
        label: '清淡一点',
        answerFilters: {
          spiceLevel: SpiceLevel.NOT_SPICY
        }
      },
      {
        id: 'breakfast-filling',
        label: '更管饱',
        answerFilters: {
          breakfastTraits: [BreakfastTrait.FILLING]
        }
      }
    ]
  }
];

const MEAL_QUESTIONS: QuestionnaireQuestion[] = [
  {
    id: 'meal-feeling',
    title: '想吃热乎的还是清爽的？',
    options: [
      {
        id: 'meal-warm',
        label: '热乎满足',
        answerFilters: {
          foodFeeling: FoodFeeling.WARM
        }
      },
      {
        id: 'meal-refreshing',
        label: '清爽一点',
        answerFilters: {
          foodFeeling: FoodFeeling.REFRESHING
        }
      }
    ]
  },
  {
    id: 'meal-spice',
    title: '今天想吃清淡、微辣还是重口？',
    options: [
      {
        id: 'meal-not-spicy',
        label: '清淡',
        answerFilters: {
          spiceLevel: SpiceLevel.NOT_SPICY
        }
      },
      {
        id: 'meal-mild',
        label: '微辣',
        answerFilters: {
          spiceLevel: SpiceLevel.MILD
        }
      },
      {
        id: 'meal-spicy',
        label: '重口',
        answerFilters: {
          spiceLevel: SpiceLevel.SPICY
        }
      }
    ]
  }
];

export function getQuestionnaireQuestions(mealPeriod: MealPeriod): QuestionnaireQuestion[] {
  return mealPeriod === MealPeriod.BREAKFAST ? BREAKFAST_QUESTIONS : MEAL_QUESTIONS;
}

export function mergeAnswerFilters(options: QuestionnaireOption[]): CategoryAnswerFilters {
  const breakfastTraits: BreakfastTrait[] = [];
  let foodFeeling: FoodFeeling | undefined = undefined;
  let spiceLevel: SpiceLevel | undefined = undefined;

  options.forEach((option: QuestionnaireOption) => {
    if (option.answerFilters.foodFeeling !== undefined) {
      foodFeeling = option.answerFilters.foodFeeling;
    }
    if (option.answerFilters.spiceLevel !== undefined) {
      spiceLevel = option.answerFilters.spiceLevel;
    }
    option.answerFilters.breakfastTraits?.forEach((trait: BreakfastTrait) => {
      if (breakfastTraits.indexOf(trait) === -1) {
        breakfastTraits.push(trait);
      }
    });
  });

  return {
    foodFeeling: foodFeeling,
    spiceLevel: spiceLevel,
    breakfastTraits: breakfastTraits
  };
}

