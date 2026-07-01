import { MOCK_FOOD_CATEGORIES } from '../data/mock/MockFoodCategories';
import { BreakfastTrait, FoodCategory, MealPeriod, SpiceLevel } from '../models/FoodCategory';
import { GeoPoint } from '../models/Location';
import { CategoryAnswerFilters } from '../models/Questionnaire';
import {
  BudgetOption,
  RecommendationFilters,
  RecommendationPreferenceContext,
  RecommendationResult,
  RecommendationStatus
} from '../models/Recommendation';
import {
  NearbyRestaurant,
  RestaurantSearchResult,
  RestaurantSearchStatus
} from '../models/RestaurantSearch';
import { RestaurantRepository } from './RestaurantRepository';

interface CategoryCandidate {
  category: FoodCategory;
  restaurants: NearbyRestaurant[];
}

interface CandidateSearchResult {
  candidates: CategoryCandidate[];
  filters: RecommendationFilters;
  notice: string;
}

interface DisplayRestaurantResult {
  restaurants: NearbyRestaurant[];
  expandedDistance: boolean;
}

const QUESTIONNAIRE_FALLBACK_NOTICE: string = '这个组合附近选择不多，已经为你调整推荐范围';

export class RecommendationService {
  private readonly repository: RestaurantRepository;
  private location: GeoPoint;
  private readonly currentTimeProvider: () => Date;
  private readonly randomNumberProvider: () => number;
  private readonly categoryProvider: () => FoodCategory[];
  private readonly searchRadiusMeters: number = 3000;

  constructor(repository: RestaurantRepository, location: GeoPoint, currentTimeProvider: () => Date = () => new Date(),
    randomNumberProvider: () => number = () => Math.random(),
    categoryProvider: () => FoodCategory[] = () => MOCK_FOOD_CATEGORIES) {
    this.repository = repository;
    this.location = location;
    this.currentTimeProvider = currentTimeProvider;
    this.randomNumberProvider = randomNumberProvider;
    this.categoryProvider = categoryProvider;
  }

  async drawDirect(filters: RecommendationFilters, excludedCategoryIds: string[],
    answerFilters?: CategoryAnswerFilters,
    preferenceContext: RecommendationPreferenceContext = {
      favoriteCategoryIds: [],
      favoriteRestaurantIds: []
    }): Promise<RecommendationResult> {
    const searchResult: RestaurantSearchResult = await this.repository.searchNearby({
      location: this.location,
      radiusMeters: this.searchRadiusMeters
    });

    if (searchResult.status === RestaurantSearchStatus.FAILURE) {
      return {
        status: RecommendationStatus.SOURCE_FAILURE,
        restaurants: [],
        nearbyRestaurantCount: 0,
        notice: '',
        errorMessage: searchResult.errorMessage,
        cycleReset: false
      };
    }

    const openRestaurants: NearbyRestaurant[] = searchResult.restaurants
      .filter((item: NearbyRestaurant) => item.restaurant.isOpen);
    const candidateSearch: CandidateSearchResult =
      this.findCandidatesWithRelaxation(openRestaurants, filters, answerFilters);
    const relaxedResult: CategoryCandidate[] = candidateSearch.candidates;

    if (relaxedResult.length === 0) {
      return {
        status: RecommendationStatus.NO_RESULTS,
        restaurants: [],
        nearbyRestaurantCount: openRestaurants.length,
        notice: '',
        errorMessage: '附近暂时没有合适的店铺，换个条件试试。',
        cycleReset: false
      };
    }

    let candidates: CategoryCandidate[] = relaxedResult
      .filter((candidate: CategoryCandidate) => excludedCategoryIds.indexOf(candidate.category.id) === -1);
    let cycleReset: boolean = false;
    if (candidates.length === 0) {
      candidates = relaxedResult;
      cycleReset = true;
    }

    const selected: CategoryCandidate = this.pickWeightedCandidate(candidates, preferenceContext);
    const displayResult: DisplayRestaurantResult = this.getDisplayRestaurants(
      openRestaurants,
      selected.category.id,
      candidateSearch.filters.budgetOption,
      filters.distanceLimitMeters,
      preferenceContext
    );

    return {
      status: RecommendationStatus.SUCCESS,
      category: selected.category,
      restaurants: displayResult.restaurants,
      nearbyRestaurantCount: openRestaurants.length,
      notice: this.getResultNotice(cycleReset, candidateSearch.notice, displayResult.expandedDistance),
      errorMessage: '',
      cycleReset: cycleReset
    };
  }

  private getDisplayRestaurants(restaurants: NearbyRestaurant[], categoryId: string, budgetOption: BudgetOption,
    requestedDistanceLimitMeters?: number,
    preferenceContext: RecommendationPreferenceContext = {
      favoriteCategoryIds: [],
      favoriteRestaurantIds: []
    }): DisplayRestaurantResult {
    const matchingRestaurants: NearbyRestaurant[] = restaurants
      .filter((item: NearbyRestaurant) => item.restaurant.categoryIds.indexOf(categoryId) !== -1 &&
        this.isWithinBudget(item, budgetOption))
      .sort((left: NearbyRestaurant, right: NearbyRestaurant) =>
        this.compareDisplayRestaurants(left, right, preferenceContext));

    if (requestedDistanceLimitMeters === undefined) {
      return {
        restaurants: matchingRestaurants.slice(0, 3),
        expandedDistance: false
      };
    }

    const withinRange: NearbyRestaurant[] = matchingRestaurants
      .filter((item: NearbyRestaurant) => this.isWithinDistance(item, requestedDistanceLimitMeters));
    if (withinRange.length >= 3) {
      return {
        restaurants: withinRange.slice(0, 3),
        expandedDistance: false
      };
    }

    const fartherAway: NearbyRestaurant[] = matchingRestaurants
      .filter((item: NearbyRestaurant) => !this.isWithinDistance(item, requestedDistanceLimitMeters));
    return {
      restaurants: withinRange.concat(fartherAway).slice(0, 3),
      expandedDistance: fartherAway.length > 0
    };
  }

  private getResultNotice(cycleReset: boolean, candidateNotice: string, expandedDistance: boolean): string {
    if (cycleReset && expandedDistance) {
      return '换一轮口味；附近选择不多，已经为你扩大范围';
    }
    if (cycleReset) {
      return '换一轮口味';
    }
    if (expandedDistance) {
      return '附近选择不多，已经为你扩大范围';
    }
    return candidateNotice;
  }

  private pickWeightedCandidate(candidates: CategoryCandidate[],
    preferenceContext: RecommendationPreferenceContext): CategoryCandidate {
    const weights: number[] = candidates.map((candidate: CategoryCandidate): number =>
      this.getCandidateWeight(candidate, preferenceContext));
    const totalWeight: number = weights.reduce((sum: number, weight: number) => sum + weight, 0);
    let threshold: number = this.randomNumberProvider() * totalWeight;
    for (let index: number = 0; index < candidates.length; index++) {
      threshold -= weights[index];
      if (threshold < 0) {
        return candidates[index];
      }
    }
    return candidates[candidates.length - 1];
  }

  private getCandidateWeight(candidate: CategoryCandidate,
    preferenceContext: RecommendationPreferenceContext): number {
    let weight: number = 1;
    if (preferenceContext.favoriteCategoryIds.indexOf(candidate.category.id) !== -1) {
      weight += 2;
    }
    const favoriteRestaurantCount: number = candidate.restaurants
      .filter((item: NearbyRestaurant) =>
        preferenceContext.favoriteRestaurantIds.indexOf(item.restaurant.id) !== -1)
      .length;
    weight += favoriteRestaurantCount * 0.7;
    const averageRating: number = this.getAverageRating(candidate.restaurants);
    if (averageRating > 4) {
      weight += (averageRating - 4) * 0.8;
    }
    return weight;
  }

  private compareDisplayRestaurants(left: NearbyRestaurant, right: NearbyRestaurant,
    preferenceContext: RecommendationPreferenceContext): number {
    const leftFavorite: number = preferenceContext.favoriteRestaurantIds.indexOf(left.restaurant.id) === -1 ? 1 : 0;
    const rightFavorite: number = preferenceContext.favoriteRestaurantIds.indexOf(right.restaurant.id) === -1 ? 1 : 0;
    if (leftFavorite !== rightFavorite) {
      return leftFavorite - rightFavorite;
    }
    const leftRating: number = left.restaurant.rating ?? 0;
    const rightRating: number = right.restaurant.rating ?? 0;
    if (leftRating !== rightRating) {
      return rightRating - leftRating;
    }
    return left.distanceMeters - right.distanceMeters;
  }

  private getAverageRating(restaurants: NearbyRestaurant[]): number {
    const ratedRestaurants: NearbyRestaurant[] = restaurants
      .filter((item: NearbyRestaurant) => item.restaurant.rating !== undefined);
    if (ratedRestaurants.length === 0) {
      return 0;
    }
    const totalRating: number = ratedRestaurants
      .reduce((sum: number, item: NearbyRestaurant) => sum + (item.restaurant.rating ?? 0), 0);
    return totalRating / ratedRestaurants.length;
  }

  private findCandidatesWithRelaxation(restaurants: NearbyRestaurant[], filters: RecommendationFilters,
    answerFilters?: CategoryAnswerFilters): CandidateSearchResult {
    let notice: string = '';
    let activeFilters: RecommendationFilters = {
      distanceLimitMeters: filters.distanceLimitMeters,
      budgetOption: filters.budgetOption,
      spiceLevel: filters.spiceLevel
    };
    let candidates: CategoryCandidate[] = this.findCandidates(restaurants, activeFilters, answerFilters);

    if (candidates.length === 0 && activeFilters.distanceLimitMeters !== undefined) {
      activeFilters.distanceLimitMeters = undefined;
      candidates = this.findCandidates(restaurants, activeFilters, answerFilters);
      notice = '附近选择不多，已经为你扩大范围';
    }
    if (candidates.length === 0 && activeFilters.budgetOption !== BudgetOption.ALL) {
      activeFilters.budgetOption = BudgetOption.ALL;
      candidates = this.findCandidates(restaurants, activeFilters, answerFilters);
      notice = '附近选择不多，已经为你扩大范围';
    }
    if (candidates.length === 0 && activeFilters.spiceLevel !== undefined) {
      activeFilters.spiceLevel = undefined;
      candidates = this.findCandidates(restaurants, activeFilters, answerFilters);
      notice = '附近选择不多，已经为你扩大范围';
    }
    if (candidates.length === 0) {
      const answerFallbacks: CategoryAnswerFilters[] = this.getAnswerFallbacks(answerFilters);
      for (let index: number = 0; index < answerFallbacks.length; index++) {
        candidates = this.findCandidates(restaurants, activeFilters, answerFallbacks[index]);
        if (candidates.length > 0) {
          notice = this.appendNotice(notice, QUESTIONNAIRE_FALLBACK_NOTICE);
          break;
        }
      }
    }
    return {
      candidates: candidates,
      filters: activeFilters,
      notice: notice
    };
  }

  private findCandidates(restaurants: NearbyRestaurant[], filters: RecommendationFilters,
    answerFilters?: CategoryAnswerFilters): CategoryCandidate[] {
    const mealPeriod: MealPeriod = this.getCurrentMealPeriod();
    return this.categoryProvider()
      .filter((category: FoodCategory) => category.mealPeriods.indexOf(mealPeriod) !== -1)
      .filter((category: FoodCategory) => filters.spiceLevel === undefined ||
        category.spiceLevels.indexOf(filters.spiceLevel) !== -1)
      .filter((category: FoodCategory) => this.matchesAnswerFilters(category, answerFilters))
      .map((category: FoodCategory): CategoryCandidate => {
        return {
          category: category,
          restaurants: restaurants.filter((item: NearbyRestaurant) => {
            return item.restaurant.categoryIds.indexOf(category.id) !== -1 &&
              this.isWithinDistance(item, filters.distanceLimitMeters) &&
              this.isWithinBudget(item, filters.budgetOption);
          })
        };
      })
      .filter((candidate: CategoryCandidate) => candidate.restaurants.length > 0);
  }

  private isWithinDistance(item: NearbyRestaurant, distanceLimitMeters?: number): boolean {
    return distanceLimitMeters === undefined || item.distanceMeters <= distanceLimitMeters;
  }

  private isWithinBudget(item: NearbyRestaurant, budgetOption: BudgetOption): boolean {
    const price: number = item.restaurant.averagePrice;
    if (budgetOption === BudgetOption.UNDER_30) {
      return price <= 30;
    }
    if (budgetOption === BudgetOption.FROM_30_TO_60) {
      return price > 30 && price <= 60;
    }
    if (budgetOption === BudgetOption.FROM_60_TO_100) {
      return price > 60 && price <= 100;
    }
    return true;
  }

  private matchesAnswerFilters(category: FoodCategory, answerFilters?: CategoryAnswerFilters): boolean {
    if (answerFilters === undefined) {
      return true;
    }
    if (answerFilters.foodFeeling !== undefined &&
      category.foodFeelings.indexOf(answerFilters.foodFeeling) === -1) {
      return false;
    }
    if (answerFilters.spiceLevel !== undefined &&
      category.spiceLevels.indexOf(answerFilters.spiceLevel) === -1) {
      return false;
    }
    return answerFilters.breakfastTraits === undefined ||
      answerFilters.breakfastTraits.every((trait: BreakfastTrait) => category.breakfastTraits.indexOf(trait) !== -1);
  }

  private getAnswerFallbacks(answerFilters?: CategoryAnswerFilters): CategoryAnswerFilters[] {
    if (answerFilters === undefined) {
      return [];
    }
    const fallbacks: CategoryAnswerFilters[] = [];
    let activeFilters: CategoryAnswerFilters = this.copyAnswerFilters(answerFilters);
    if (activeFilters.spiceLevel !== undefined) {
      activeFilters.spiceLevel = undefined;
      fallbacks.push(this.copyAnswerFilters(activeFilters));
    }
    if (activeFilters.foodFeeling !== undefined) {
      activeFilters.foodFeeling = undefined;
      fallbacks.push(this.copyAnswerFilters(activeFilters));
    }
    while (activeFilters.breakfastTraits !== undefined && activeFilters.breakfastTraits.length > 0) {
      activeFilters.breakfastTraits = activeFilters.breakfastTraits.slice(0, activeFilters.breakfastTraits.length - 1);
      fallbacks.push(this.copyAnswerFilters(activeFilters));
    }
    return fallbacks;
  }

  private copyAnswerFilters(filters: CategoryAnswerFilters): CategoryAnswerFilters {
    return {
      foodFeeling: filters.foodFeeling,
      spiceLevel: filters.spiceLevel,
      breakfastTraits: filters.breakfastTraits === undefined ? undefined : filters.breakfastTraits.slice()
    };
  }

  private appendNotice(currentNotice: string, nextNotice: string): string {
    return currentNotice.length === 0 ? nextNotice : `${currentNotice}；${nextNotice}`;
  }

  getCurrentMealPeriod(): MealPeriod {
    const hour: number = this.currentTimeProvider().getHours();
    if (hour >= 5 && hour < 10) {
      return MealPeriod.BREAKFAST;
    }
    if (hour >= 10 && hour < 16) {
      return MealPeriod.LUNCH;
    }
    return MealPeriod.DINNER;
  }

  setLocation(location: GeoPoint): void {
    this.location = location;
  }
}

