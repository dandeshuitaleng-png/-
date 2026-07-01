import { describe, expect, it } from '@ohos/hypium';
import { RestaurantDataAdapter } from '../main/ets/data/adapters/RestaurantDataAdapter';
import { BreakfastTrait, FoodCategory, FoodFeeling, SpiceLevel } from '../main/ets/models/FoodCategory';
import { GeoPoint } from '../main/ets/models/Location';
import { CategoryAnswerFilters } from '../main/ets/models/Questionnaire';
import {
  BudgetOption,
  RecommendationFilters,
  RecommendationResult,
  RecommendationStatus
} from '../main/ets/models/Recommendation';
import { Restaurant, RestaurantSourceType } from '../main/ets/models/Restaurant';
import {
  NearbyRestaurant,
  RestaurantSearchRequest,
  RestaurantSearchResult,
  RestaurantSearchStatus
} from '../main/ets/models/RestaurantSearch';
import { RecommendationService } from '../main/ets/services/RecommendationService';
import { RestaurantRepository } from '../main/ets/services/RestaurantRepository';

const TEST_LOCATION: GeoPoint = {
  latitude: 31.2304,
  longitude: 121.4737
};

const ALL_FILTERS: RecommendationFilters = {
  budgetOption: BudgetOption.ALL
};

class TestRestaurantAdapter implements RestaurantDataAdapter {
  private readonly restaurants: NearbyRestaurant[];

  constructor(restaurants: NearbyRestaurant[]) {
    this.restaurants = restaurants;
  }

  async searchNearby(request: RestaurantSearchRequest): Promise<RestaurantSearchResult> {
    return {
      status: RestaurantSearchStatus.SUCCESS,
      restaurants: this.restaurants.filter((item: NearbyRestaurant) => item.distanceMeters <= request.radiusMeters),
      errorMessage: ''
    };
  }
}

function createNearbyRestaurant(id: string, name: string, categoryIds: string[], distanceMeters: number,
  averagePrice: number, isOpen: boolean = true, rating: number = 4.5): NearbyRestaurant {
  const restaurant: Restaurant = {
    id: id,
    sourceType: RestaurantSourceType.MOCK,
    name: name,
    latitude: TEST_LOCATION.latitude,
    longitude: TEST_LOCATION.longitude,
    categoryIds: categoryIds,
    averagePrice: averagePrice,
    rating: rating,
    businessHours: '10:00-22:00',
    isOpen: isOpen
  };
  return {
    restaurant: restaurant,
    distanceMeters: distanceMeters
  };
}

function createService(restaurants: NearbyRestaurant[], hour: number = 12, randomValue: number = 0):
  RecommendationService {
  return new RecommendationService(
    new RestaurantRepository(new TestRestaurantAdapter(restaurants)),
    TEST_LOCATION,
    () => new Date(2026, 5, 2, hour, 0, 0),
    () => randomValue
  );
}

function getCategoryName(result: RecommendationResult): string {
  const category: FoodCategory | undefined = result.category;
  return category === undefined ? '' : category.name;
}

export default function recommendationServiceTest() {
  describe('RecommendationService', () => {
    it('lunchDrawOnlyUsesLunchCategories', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('breakfast-a', '早餐店 A', ['baozi-porridge'], 100, 12),
        createNearbyRestaurant('hotpot-a', '火锅店 A', ['hotpot'], 200, 60)
      ], 12);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, []);

      expect(result.status).assertEqual(RecommendationStatus.SUCCESS);
      expect(getCategoryName(result)).assertEqual('火锅');
    });

    it('closedRestaurantsDoNotParticipate', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('barbecue-closed', '烧烤店 D', ['barbecue'], 100, 50, false),
        createNearbyRestaurant('home-cooking-a', '家常菜馆 A', ['home-cooking'], 200, 40)
      ], 18);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, []);

      expect(getCategoryName(result)).assertEqual('家常炒菜');
      expect(result.restaurants.length).assertEqual(1);
      expect(result.restaurants[0].restaurant.id).assertEqual('home-cooking-a');
    });

    it('distanceFilterShowsWithinRangeRestaurantsFirst', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', '火锅店 A', ['hotpot'], 200, 60),
        createNearbyRestaurant('hotpot-b', '火锅店 B', ['hotpot'], 800, 60)
      ]);
      const filters: RecommendationFilters = {
        distanceLimitMeters: 500,
        budgetOption: BudgetOption.ALL
      };

      const result: RecommendationResult = await service.drawDirect(filters, []);

      expect(result.restaurants.length).assertEqual(2);
      expect(result.restaurants[0].restaurant.id).assertEqual('hotpot-a');
      expect(result.restaurants[1].restaurant.id).assertEqual('hotpot-b');
      expect(result.notice).assertEqual('附近选择不多，已经为你扩大范围');
    });

    it('distanceFilterExpandsWhenNoRestaurantMatches', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-b', '火锅店 B', ['hotpot'], 800, 60)
      ]);
      const filters: RecommendationFilters = {
        distanceLimitMeters: 500,
        budgetOption: BudgetOption.ALL
      };

      const result: RecommendationResult = await service.drawDirect(filters, []);

      expect(getCategoryName(result)).assertEqual('火锅');
      expect(result.restaurants[0].restaurant.id).assertEqual('hotpot-b');
      expect(result.notice).assertEqual('附近选择不多，已经为你扩大范围');
    });

    it('budgetRelaxesOnlyAfterDistanceStillHasNoResults', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-b', '火锅店 B', ['hotpot'], 800, 45)
      ]);
      const filters: RecommendationFilters = {
        distanceLimitMeters: 500,
        budgetOption: BudgetOption.UNDER_30
      };

      const result: RecommendationResult = await service.drawDirect(filters, []);

      expect(getCategoryName(result)).assertEqual('火锅');
      expect(result.restaurants[0].restaurant.id).assertEqual('hotpot-b');
      expect(result.notice).assertEqual('附近选择不多，已经为你扩大范围');
    });

    it('spiceFilterOnlyUsesMatchingCategories', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('cantonese-a', 'Cantonese A', ['cantonese'], 200, 45),
        createNearbyRestaurant('barbecue-a', 'Barbecue A', ['barbecue'], 300, 45)
      ]);
      const filters: RecommendationFilters = {
        budgetOption: BudgetOption.ALL,
        spiceLevel: SpiceLevel.SPICY
      };

      const result: RecommendationResult = await service.drawDirect(filters, []);

      expect(result.category?.id).assertEqual('barbecue');
      expect(result.restaurants.length).assertEqual(1);
      expect(result.restaurants[0].restaurant.id).assertEqual('barbecue-a');
    });

    it('spiceRelaxesAfterDistanceAndBudgetStillHaveNoResults', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('cantonese-b', 'Cantonese B', ['cantonese'], 800, 80)
      ]);
      const filters: RecommendationFilters = {
        distanceLimitMeters: 500,
        budgetOption: BudgetOption.UNDER_30,
        spiceLevel: SpiceLevel.SPICY
      };

      const result: RecommendationResult = await service.drawDirect(filters, []);

      expect(result.category?.id).assertEqual('cantonese');
      expect(result.restaurants.length).assertEqual(1);
      expect(result.restaurants[0].restaurant.id).assertEqual('cantonese-b');
      expect(result.notice).assertEqual('附近选择不多，已经为你扩大范围');
    });

    it('questionnaireFiltersRemainActiveWhileUserFiltersRelax', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', 'Hotpot A', ['hotpot'], 200, 20),
        createNearbyRestaurant('cantonese-b', 'Cantonese B', ['cantonese'], 800, 80)
      ]);
      const filters: RecommendationFilters = {
        distanceLimitMeters: 500,
        budgetOption: BudgetOption.UNDER_30
      };

      const result: RecommendationResult = await service.drawDirect(filters, [], {
        foodFeeling: FoodFeeling.REFRESHING
      });

      expect(result.category?.id).assertEqual('cantonese');
      expect(result.restaurants.length).assertEqual(1);
      expect(result.restaurants[0].restaurant.id).assertEqual('cantonese-b');
      expect(result.notice).assertEqual('附近选择不多，已经为你扩大范围');
    });

    it('conflictingQuestionnaireAnswersRelaxSpiceBeforeFoodFeeling', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', 'Hotpot A', ['hotpot'], 200, 60),
        createNearbyRestaurant('cantonese-a', 'Cantonese A', ['cantonese'], 300, 50)
      ]);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, [], {
        foodFeeling: FoodFeeling.REFRESHING,
        spiceLevel: SpiceLevel.SPICY
      });

      expect(result.category?.id).assertEqual('cantonese');
      expect(result.restaurants[0].restaurant.id).assertEqual('cantonese-a');
      expect(result.notice).assertEqual('这个组合附近选择不多，已经为你调整推荐范围');
    });

    it('questionnaireFallsBackToFoodFeelingAfterSpiceStillHasNoResults', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', 'Hotpot A', ['hotpot'], 200, 60)
      ]);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, [], {
        foodFeeling: FoodFeeling.REFRESHING,
        spiceLevel: SpiceLevel.SPICY
      });

      expect(result.category?.id).assertEqual('hotpot');
      expect(result.restaurants[0].restaurant.id).assertEqual('hotpot-a');
      expect(result.notice).assertEqual('这个组合附近选择不多，已经为你调整推荐范围');
    });

    it('mealQuestionAnswerCombinationsAlwaysReturnResult', 0, async () => {
      const restaurants: NearbyRestaurant[] = [
        createNearbyRestaurant('hotpot-a', 'Hotpot A', ['hotpot'], 200, 60),
        createNearbyRestaurant('cantonese-a', 'Cantonese A', ['cantonese'], 300, 50),
        createNearbyRestaurant('quick-meal-a', 'Quick Meal A', ['quick-meal'], 400, 35)
      ];
      const feelings: FoodFeeling[] = [FoodFeeling.WARM, FoodFeeling.REFRESHING];
      const spiceLevels: SpiceLevel[] = [SpiceLevel.NOT_SPICY, SpiceLevel.MILD, SpiceLevel.SPICY];

      for (let feelingIndex: number = 0; feelingIndex < feelings.length; feelingIndex++) {
        for (let spiceIndex: number = 0; spiceIndex < spiceLevels.length; spiceIndex++) {
          const service: RecommendationService = createService(restaurants);
          const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, [], {
            foodFeeling: feelings[feelingIndex],
            spiceLevel: spiceLevels[spiceIndex]
          });

          expect(result.status).assertEqual(RecommendationStatus.SUCCESS);
        }
      }
    });

    it('breakfastQuestionAnswerCombinationsAlwaysReturnResult', 0, async () => {
      const restaurants: NearbyRestaurant[] = [
        createNearbyRestaurant('noodles-a', 'Noodles A', ['noodles'], 200, 20)
      ];
      const answerFilters: CategoryAnswerFilters[] = [
        {
          foodFeeling: FoodFeeling.WARM,
          spiceLevel: SpiceLevel.NOT_SPICY
        },
        {
          foodFeeling: FoodFeeling.WARM,
          breakfastTraits: [BreakfastTrait.FILLING]
        },
        {
          breakfastTraits: [BreakfastTrait.TAKEAWAY],
          spiceLevel: SpiceLevel.NOT_SPICY
        },
        {
          breakfastTraits: [BreakfastTrait.TAKEAWAY, BreakfastTrait.FILLING]
        }
      ];

      for (let index: number = 0; index < answerFilters.length; index++) {
        const service: RecommendationService = createService(restaurants, 8);
        const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, [], answerFilters[index]);

        expect(result.status).assertEqual(RecommendationStatus.SUCCESS);
      }
    });

    it('displayListDoesNotSilentlyRelaxBudgetToFillThreePlaces', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', '火锅店 A', ['hotpot'], 200, 25),
        createNearbyRestaurant('hotpot-b', '火锅店 B', ['hotpot'], 800, 80)
      ]);
      const filters: RecommendationFilters = {
        distanceLimitMeters: 500,
        budgetOption: BudgetOption.UNDER_30
      };

      const result: RecommendationResult = await service.drawDirect(filters, []);

      expect(result.restaurants.length).assertEqual(1);
      expect(result.restaurants[0].restaurant.id).assertEqual('hotpot-a');
      expect(result.notice).assertEqual('');
    });

    it('favoriteCategoryInfluencesWeightedDraw', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', '火锅店 A', ['hotpot'], 200, 60),
        createNearbyRestaurant('home-cooking-a', '家常菜馆 A', ['home-cooking'], 300, 40)
      ], 12, 0.6);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, [], undefined, {
        favoriteCategoryIds: ['hotpot'],
        favoriteRestaurantIds: []
      });

      expect(result.category?.id).assertEqual('hotpot');
    });

    it('ratingImprovesRestaurantDisplayOrder', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-low', '普通火锅', ['hotpot'], 200, 60, true, 4.1),
        createNearbyRestaurant('hotpot-high', '高分火锅', ['hotpot'], 500, 60, true, 4.9)
      ]);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, []);

      expect(result.restaurants[0].restaurant.id).assertEqual('hotpot-high');
      expect(result.restaurants[1].restaurant.id).assertEqual('hotpot-low');
    });

    it('drawAgainExcludesRevealedCategories', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', '火锅店 A', ['hotpot'], 200, 60),
        createNearbyRestaurant('home-cooking-a', '家常菜馆 A', ['home-cooking'], 300, 40)
      ]);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, ['hotpot']);

      expect(getCategoryName(result)).assertEqual('家常炒菜');
    });

    it('exhaustedCandidatesResetCycleAndShowNotice', 0, async () => {
      const service: RecommendationService = createService([
        createNearbyRestaurant('hotpot-a', '火锅店 A', ['hotpot'], 200, 60),
        createNearbyRestaurant('home-cooking-a', '家常菜馆 A', ['home-cooking'], 300, 40)
      ]);

      const result: RecommendationResult = await service.drawDirect(ALL_FILTERS, ['hotpot', 'home-cooking']);

      expect(result.cycleReset).assertTrue();
      expect(getCategoryName(result)).assertEqual('火锅');
      expect(result.notice).assertEqual('换一轮口味');
    });
  });
}

