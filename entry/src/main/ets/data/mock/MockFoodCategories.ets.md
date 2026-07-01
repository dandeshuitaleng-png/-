# entry/src/main/ets/data/mock/MockFoodCategories.ets

```typescript
import {
  BreakfastTrait,
  CategorySourceType,
  FoodCategory,
  FoodFeeling,
  MealPeriod,
  SpiceLevel
} from '../../models/FoodCategory';

export const MOCK_FOOD_CATEGORIES: FoodCategory[] = [
  {
    id: 'baozi-porridge',
    sourceType: CategorySourceType.BUILT_IN,
    name: '包子粥铺',
    mealPeriods: [MealPeriod.BREAKFAST],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY],
    breakfastTraits: [BreakfastTrait.TAKEAWAY, BreakfastTrait.FILLING]
  },
  {
    id: 'noodles',
    sourceType: CategorySourceType.BUILT_IN,
    name: '粉面',
    mealPeriods: [MealPeriod.BREAKFAST, MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY, SpiceLevel.MILD, SpiceLevel.SPICY],
    breakfastTraits: [BreakfastTrait.TAKEAWAY, BreakfastTrait.FILLING]
  },
  {
    id: 'dumpling-wonton',
    sourceType: CategorySourceType.BUILT_IN,
    name: '饺子馄饨',
    mealPeriods: [MealPeriod.BREAKFAST, MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY, SpiceLevel.MILD],
    breakfastTraits: [BreakfastTrait.FILLING]
  },
  {
    id: 'soy-milk-fritter',
    sourceType: CategorySourceType.BUILT_IN,
    name: '豆浆油条',
    mealPeriods: [MealPeriod.BREAKFAST],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY],
    breakfastTraits: [BreakfastTrait.TAKEAWAY]
  },
  {
    id: 'hotpot',
    sourceType: CategorySourceType.BUILT_IN,
    name: '火锅',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY, SpiceLevel.MILD, SpiceLevel.SPICY],
    breakfastTraits: []
  },
  {
    id: 'barbecue',
    sourceType: CategorySourceType.BUILT_IN,
    name: '烧烤',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.MILD, SpiceLevel.SPICY],
    breakfastTraits: []
  },
  {
    id: 'sichuan-hunan',
    sourceType: CategorySourceType.BUILT_IN,
    name: '川湘菜',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.MILD, SpiceLevel.SPICY],
    breakfastTraits: []
  },
  {
    id: 'home-cooking',
    sourceType: CategorySourceType.BUILT_IN,
    name: '家常炒菜',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY, SpiceLevel.MILD],
    breakfastTraits: []
  },
  {
    id: 'cantonese',
    sourceType: CategorySourceType.BUILT_IN,
    name: '粤菜',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM, FoodFeeling.REFRESHING],
    spiceLevels: [SpiceLevel.NOT_SPICY],
    breakfastTraits: []
  },
  {
    id: 'malatang',
    sourceType: CategorySourceType.BUILT_IN,
    name: '麻辣烫',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.MILD, SpiceLevel.SPICY],
    breakfastTraits: []
  },
  {
    id: 'claypot-rice',
    sourceType: CategorySourceType.BUILT_IN,
    name: '砂锅煲仔饭',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY, SpiceLevel.MILD],
    breakfastTraits: []
  },
  {
    id: 'quick-meal',
    sourceType: CategorySourceType.BUILT_IN,
    name: '快餐简餐',
    mealPeriods: [MealPeriod.LUNCH, MealPeriod.DINNER],
    foodFeelings: [FoodFeeling.WARM, FoodFeeling.REFRESHING],
    spiceLevels: [SpiceLevel.NOT_SPICY, SpiceLevel.MILD],
    breakfastTraits: []
  }
];

```
