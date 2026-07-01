export enum CategorySourceType {
  BUILT_IN = 'builtIn',
  CUSTOM = 'custom'
}

export enum MealPeriod {
  BREAKFAST = 'breakfast',
  LUNCH = 'lunch',
  DINNER = 'dinner'
}

export enum FoodFeeling {
  WARM = 'warm',
  REFRESHING = 'refreshing'
}

export enum SpiceLevel {
  NOT_SPICY = 'notSpicy',
  MILD = 'mild',
  SPICY = 'spicy'
}

export enum BreakfastTrait {
  TAKEAWAY = 'takeaway',
  FILLING = 'filling'
}

export interface FoodCategory {
  id: string;
  sourceType: CategorySourceType;
  name: string;
  mealPeriods: MealPeriod[];
  foodFeelings: FoodFeeling[];
  spiceLevels: SpiceLevel[];
  breakfastTraits: BreakfastTrait[];
}

