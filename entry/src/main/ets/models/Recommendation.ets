import { FoodCategory, SpiceLevel } from './FoodCategory';
import { NearbyRestaurant } from './RestaurantSearch';

export enum BudgetOption {
  ALL = 'all',
  UNDER_30 = 'under30',
  FROM_30_TO_60 = '30to60',
  FROM_60_TO_100 = '60to100'
}

export enum RecommendationStatus {
  SUCCESS = 'success',
  NO_RESULTS = 'noResults',
  SOURCE_FAILURE = 'sourceFailure'
}

export interface RecommendationFilters {
  distanceLimitMeters?: number;
  budgetOption: BudgetOption;
  spiceLevel?: SpiceLevel;
}

export interface RecommendationPreferenceContext {
  favoriteCategoryIds: string[];
  favoriteRestaurantIds: string[];
}

export interface RecommendationResult {
  status: RecommendationStatus;
  category?: FoodCategory;
  restaurants: NearbyRestaurant[];
  nearbyRestaurantCount: number;
  notice: string;
  errorMessage: string;
  cycleReset: boolean;
}

