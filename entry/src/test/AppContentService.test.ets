import { describe, expect, it } from '@ohos/hypium';
import { CombinedRestaurantAdapter } from '../main/ets/data/adapters/CombinedRestaurantAdapter';
import { RestaurantDataAdapter } from '../main/ets/data/adapters/RestaurantDataAdapter';
import {
  BreakfastTrait,
  CategorySourceType,
  FoodCategory,
  FoodFeeling,
  MealPeriod,
  SpiceLevel
} from '../main/ets/models/FoodCategory';
import { GeoPoint } from '../main/ets/models/Location';
import { BudgetOption, RecommendationResult } from '../main/ets/models/Recommendation';
import { Restaurant, RestaurantSourceType } from '../main/ets/models/Restaurant';
import {
  RestaurantSearchRequest,
  RestaurantSearchResult,
  RestaurantSearchStatus
} from '../main/ets/models/RestaurantSearch';
import { AppContentService, DeleteCategoryResult, UserPreferences } from '../main/ets/services/AppContentService';
import { RecommendationService } from '../main/ets/services/RecommendationService';
import { RestaurantRepository } from '../main/ets/services/RestaurantRepository';
import { MemoryLocalStorageAdapter } from '../main/ets/storage/LocalStorageContract';

const TEST_LOCATION: GeoPoint = {
  latitude: 31.2304,
  longitude: 121.4737
};

class EmptyRestaurantAdapter implements RestaurantDataAdapter {
  async searchNearby(request: RestaurantSearchRequest): Promise<RestaurantSearchResult> {
    return {
      status: RestaurantSearchStatus.SUCCESS,
      restaurants: [],
      errorMessage: ''
    };
  }
}

function createCustomCategory(id: string): FoodCategory {
  return {
    id: id,
    sourceType: CategorySourceType.CUSTOM,
    name: 'Custom Category',
    mealPeriods: [MealPeriod.LUNCH],
    foodFeelings: [FoodFeeling.WARM],
    spiceLevels: [SpiceLevel.NOT_SPICY],
    breakfastTraits: [BreakfastTrait.FILLING]
  };
}

function createCustomRestaurant(id: string, categoryIds: string[], latitude: number = TEST_LOCATION.latitude,
  longitude: number = TEST_LOCATION.longitude): Restaurant {
  return {
    id: id,
    sourceType: RestaurantSourceType.CUSTOM,
    name: 'Custom Restaurant',
    latitude: latitude,
    longitude: longitude,
    categoryIds: categoryIds,
    averagePrice: 38,
    businessHours: '',
    isOpen: true
  };
}

export default function appContentServiceTest() {
  describe('AppContentService', () => {
    it('favoritesAndCustomContentPersistAfterReload', 0, async () => {
      const storage: MemoryLocalStorageAdapter = new MemoryLocalStorageAdapter();
      const first: AppContentService = new AppContentService(storage);
      await first.load();
      await first.toggleFavoriteCategory('custom-category');
      await first.toggleFavoriteRestaurant('custom-restaurant');
      await first.saveCategory(createCustomCategory('custom-category'));
      await first.saveRestaurant(createCustomRestaurant('custom-restaurant', ['custom-category']));

      const reloaded: AppContentService = new AppContentService(storage);
      await reloaded.load();

      expect(reloaded.isFavoriteCategory('custom-category')).assertTrue();
      expect(reloaded.isFavoriteRestaurant('custom-restaurant')).assertTrue();
      expect(reloaded.getCustomCategories().length).assertEqual(1);
      expect(reloaded.getCustomRestaurants().length).assertEqual(1);
    });

    it('userPreferencesPersistAfterReload', 0, async () => {
      const storage: MemoryLocalStorageAdapter = new MemoryLocalStorageAdapter();
      const first: AppContentService = new AppContentService(storage);
      await first.load();
      await first.saveUserPreferences({
        selectedDistanceMeters: 1000,
        selectedBudget: BudgetOption.FROM_30_TO_60,
        selectedSpice: SpiceLevel.MILD,
        locationLabel: '手动位置',
        manualLocation: {
          latitude: 31.2201,
          longitude: 121.4802
        }
      });

      const reloaded: AppContentService = new AppContentService(storage);
      await reloaded.load();
      const preferences: UserPreferences = reloaded.getUserPreferences();

      expect(preferences.selectedDistanceMeters).assertEqual(1000);
      expect(preferences.selectedBudget).assertEqual(BudgetOption.FROM_30_TO_60);
      expect(preferences.selectedSpice).assertEqual(SpiceLevel.MILD);
      expect(preferences.locationLabel).assertEqual('手动位置');
      expect(preferences.manualLocation?.latitude).assertEqual(31.2201);
      expect(preferences.manualLocation?.longitude).assertEqual(121.4802);
    });

    it('deletingUsedCategoryOnlyRemovesAssociation', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();
      await service.saveCategory(createCustomCategory('custom-category'));
      await service.saveRestaurant(createCustomRestaurant('custom-restaurant', ['custom-category']));

      const result: DeleteCategoryResult = await service.deleteCategory('custom-category');

      expect(result.affectedRestaurantCount).assertEqual(1);
      expect(result.orphanRestaurantCount).assertEqual(1);
      expect(service.getCustomRestaurants().length).assertEqual(1);
      expect(service.getCustomRestaurants()[0].categoryIds.length).assertEqual(0);
    });

    it('customRestaurantCanBeEditedAndDeleted', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();
      await service.saveRestaurant(createCustomRestaurant('custom-restaurant', ['category-a']));
      const edited: Restaurant = createCustomRestaurant('custom-restaurant', ['category-b']);
      edited.name = 'Edited Restaurant';
      edited.averagePrice = 66;
      await service.saveRestaurant(edited);

      expect(service.getCustomRestaurants().length).assertEqual(1);
      expect(service.getCustomRestaurants()[0].name).assertEqual('Edited Restaurant');
      expect(service.getCustomRestaurants()[0].averagePrice).assertEqual(66);
      expect(service.getCustomRestaurants()[0].categoryIds[0]).assertEqual('category-b');

      await service.toggleFavoriteRestaurant('custom-restaurant');
      await service.deleteRestaurant('custom-restaurant');

      expect(service.getCustomRestaurants().length).assertEqual(0);
      expect(service.isFavoriteRestaurant('custom-restaurant')).assertFalse();
    });

    it('customCategoryCanBeEditedAndDeleted', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();
      await service.saveCategory(createCustomCategory('custom-category'));
      const edited: FoodCategory = createCustomCategory('custom-category');
      edited.name = 'Edited Category';
      edited.mealPeriods = [MealPeriod.DINNER];
      await service.saveCategory(edited);

      expect(service.getCustomCategories().length).assertEqual(1);
      expect(service.getCustomCategories()[0].name).assertEqual('Edited Category');
      expect(service.getCustomCategories()[0].mealPeriods[0]).assertEqual(MealPeriod.DINNER);

      await service.deleteCategory('custom-category');

      expect(service.getCustomCategories().length).assertEqual(0);
    });

    it('customRestaurantsJoinNearbySearchInDistanceOrder', 0, async () => {
      const customRestaurants: Restaurant[] = [
        createCustomRestaurant('far', ['custom-category'], 31.2320, 121.4737),
        createCustomRestaurant('near', ['custom-category'], 31.2305, 121.4737)
      ];
      const adapter: CombinedRestaurantAdapter =
        new CombinedRestaurantAdapter(new EmptyRestaurantAdapter(), () => customRestaurants);

      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: TEST_LOCATION,
        radiusMeters: 3000
      });

      expect(result.restaurants.length).assertEqual(2);
      expect(result.restaurants[0].restaurant.id).assertEqual('near');
      expect(result.restaurants[1].restaurant.id).assertEqual('far');
    });

    it('customCategoryAndRestaurantParticipateInRecommendation', 0, async () => {
      const category: FoodCategory = createCustomCategory('custom-category');
      const restaurant: Restaurant = createCustomRestaurant('custom-restaurant', ['custom-category']);
      const adapter: CombinedRestaurantAdapter =
        new CombinedRestaurantAdapter(new EmptyRestaurantAdapter(), () => [restaurant]);
      const recommendationService: RecommendationService = new RecommendationService(
        new RestaurantRepository(adapter),
        TEST_LOCATION,
        () => new Date(2026, 5, 2, 12, 0, 0),
        () => 0,
        () => [category]
      );

      const result: RecommendationResult = await recommendationService.drawDirect({
        budgetOption: BudgetOption.ALL
      }, []);

      expect(result.category?.id).assertEqual('custom-category');
      expect(result.restaurants[0].restaurant.id).assertEqual('custom-restaurant');
    });

    it('unfavoritedRestaurantNotInFavoriteList', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();
      await service.saveRestaurant(createCustomRestaurant('custom-restaurant', ['category-a']));

      expect(service.isFavoriteRestaurant('custom-restaurant')).assertFalse();
      expect(service.getFavoriteRestaurantIds().length).assertEqual(0);
    });

    it('favoritedRestaurantAppearsInList', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();
      await service.saveRestaurant(createCustomRestaurant('custom-restaurant', ['category-a']));
      await service.toggleFavoriteRestaurant('custom-restaurant');

      expect(service.isFavoriteRestaurant('custom-restaurant')).assertTrue();
      expect(service.getFavoriteRestaurantIds().length).assertEqual(1);
      expect(service.getFavoriteRestaurantIds()[0]).assertEqual('custom-restaurant');
    });

    it('cancelFavoriteRemovesFromList', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();
      await service.saveRestaurant(createCustomRestaurant('custom-restaurant', ['category-a']));
      await service.toggleFavoriteRestaurant('custom-restaurant');
      expect(service.isFavoriteRestaurant('custom-restaurant')).assertTrue();

      await service.toggleFavoriteRestaurant('custom-restaurant');
      expect(service.isFavoriteRestaurant('custom-restaurant')).assertFalse();
      expect(service.getFavoriteRestaurantIds().length).assertEqual(0);
    });

    it('saveNewRestaurantThenToggleMirrorsUiAutoFavorite', 0, async () => {
      const service: AppContentService = new AppContentService(new MemoryLocalStorageAdapter());
      await service.load();

      // Mirror Index.ets saveRestaurantForm: new restaurant triggers auto-favorite
      await service.saveRestaurant(createCustomRestaurant('new-shop', ['category-a']));
      await service.toggleFavoriteRestaurant('new-shop');

      expect(service.isFavoriteRestaurant('new-shop')).assertTrue();
      expect(service.getFavoriteRestaurantIds().indexOf('new-shop') !== -1).assertTrue();

      // Editing the same restaurant should preserve favorite state (Index.ets only
      // auto-favorites when isNewRestaurant is true)
      const edited: Restaurant = createCustomRestaurant('new-shop', ['category-b']);
      edited.name = 'Updated Shop';
      await service.saveRestaurant(edited);

      expect(service.isFavoriteRestaurant('new-shop')).assertTrue();
      expect(service.getFavoriteRestaurantIds().length).assertEqual(1);

      // Second new restaurant also gets auto-favorited
      await service.saveRestaurant(createCustomRestaurant('second-shop', ['category-c']));
      await service.toggleFavoriteRestaurant('second-shop');

      expect(service.isFavoriteRestaurant('second-shop')).assertTrue();
      expect(service.getFavoriteRestaurantIds().length).assertEqual(2);
    });
  });
}

