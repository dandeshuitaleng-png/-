# entry/src/main/ets/services/AppContentService.ets

```typescript
import { CategorySourceType, FoodCategory, SpiceLevel } from '../models/FoodCategory';
import { GeoPoint } from '../models/Location';
import { BudgetOption } from '../models/Recommendation';
import { Restaurant, RestaurantSourceType } from '../models/Restaurant';
import { LocalStorageAdapter, LocalStorageKeys } from '../storage/LocalStorageContract';

export interface DeleteCategoryResult {
  affectedRestaurantCount: number;
  orphanRestaurantCount: number;
}

export interface UserPreferences {
  selectedDistanceMeters: number;
  selectedBudget: BudgetOption;
  selectedSpice: string;
  locationLabel: string;
  manualLocation?: GeoPoint;
}

export class AppContentService {
  private readonly storage: LocalStorageAdapter;
  private favoriteCategoryIds: string[] = [];
  private favoriteRestaurantIds: string[] = [];
  private customCategories: FoodCategory[] = [];
  private customRestaurants: Restaurant[] = [];
  private userPreferences: UserPreferences = this.createDefaultUserPreferences();

  constructor(storage: LocalStorageAdapter) {
    this.storage = storage;
  }

  async load(): Promise<void> {
    this.favoriteCategoryIds = JSON.parse(await this.storage.getString(LocalStorageKeys.FAVORITE_CATEGORY_IDS, '[]'));
    this.favoriteRestaurantIds =
      JSON.parse(await this.storage.getString(LocalStorageKeys.FAVORITE_RESTAURANT_IDS, '[]'));
    this.customCategories = JSON.parse(await this.storage.getString(LocalStorageKeys.CUSTOM_CATEGORIES, '[]'));
    this.customRestaurants = JSON.parse(await this.storage.getString(LocalStorageKeys.CUSTOM_RESTAURANTS, '[]'));
    this.userPreferences = this.normalizeUserPreferences(
      JSON.parse(await this.storage.getString(LocalStorageKeys.USER_PREFERENCES, '{}')) as UserPreferences);
  }

  getFavoriteCategoryIds(): string[] {
    return this.favoriteCategoryIds.slice();
  }

  getFavoriteRestaurantIds(): string[] {
    return this.favoriteRestaurantIds.slice();
  }

  getCustomCategories(): FoodCategory[] {
    return this.customCategories.slice();
  }

  getCustomRestaurants(): Restaurant[] {
    return this.customRestaurants.slice();
  }

  getUserPreferences(): UserPreferences {
    const preferences: UserPreferences = this.userPreferences;
    return {
      selectedDistanceMeters: preferences.selectedDistanceMeters,
      selectedBudget: preferences.selectedBudget,
      selectedSpice: preferences.selectedSpice,
      locationLabel: preferences.locationLabel,
      manualLocation: preferences.manualLocation === undefined ? undefined : {
        latitude: preferences.manualLocation.latitude,
        longitude: preferences.manualLocation.longitude
      }
    };
  }

  isFavoriteCategory(categoryId: string): boolean {
    return this.favoriteCategoryIds.indexOf(categoryId) !== -1;
  }

  isFavoriteRestaurant(restaurantId: string): boolean {
    return this.favoriteRestaurantIds.indexOf(restaurantId) !== -1;
  }

  async toggleFavoriteCategory(categoryId: string): Promise<void> {
    this.favoriteCategoryIds = this.toggleId(this.favoriteCategoryIds, categoryId);
    await this.persistFavoriteCategoryIds();
  }

  async toggleFavoriteRestaurant(restaurantId: string): Promise<void> {
    this.favoriteRestaurantIds = this.toggleId(this.favoriteRestaurantIds, restaurantId);
    await this.persistFavoriteRestaurantIds();
  }

  async saveCategory(category: FoodCategory): Promise<void> {
    const normalized: FoodCategory = {
      id: category.id,
      sourceType: CategorySourceType.CUSTOM,
      name: category.name,
      mealPeriods: category.mealPeriods.slice(),
      foodFeelings: category.foodFeelings.slice(),
      spiceLevels: category.spiceLevels.slice(),
      breakfastTraits: category.breakfastTraits.slice()
    };
    const index: number = this.customCategories.findIndex((item: FoodCategory) => item.id === normalized.id);
    if (index === -1) {
      this.customCategories.push(normalized);
    } else {
      this.customCategories[index] = normalized;
    }
    await this.persistCustomCategories();
  }

  async deleteCategory(categoryId: string): Promise<DeleteCategoryResult> {
    this.customCategories = this.customCategories.filter((category: FoodCategory) => category.id !== categoryId);
    this.favoriteCategoryIds = this.favoriteCategoryIds.filter((id: string) => id !== categoryId);
    let affectedRestaurantCount: number = 0;
    let orphanRestaurantCount: number = 0;
    this.customRestaurants = this.customRestaurants.map((restaurant: Restaurant): Restaurant => {
      if (restaurant.categoryIds.indexOf(categoryId) === -1) {
        return restaurant;
      }
      affectedRestaurantCount++;
      const categoryIds: string[] = restaurant.categoryIds.filter((id: string) => id !== categoryId);
      if (categoryIds.length === 0) {
        orphanRestaurantCount++;
      }
      return {
        id: restaurant.id,
        sourceType: restaurant.sourceType,
        name: restaurant.name,
        latitude: restaurant.latitude,
        longitude: restaurant.longitude,
        categoryIds: categoryIds,
        averagePrice: restaurant.averagePrice,
        rating: restaurant.rating,
        businessHours: restaurant.businessHours,
        isOpen: restaurant.isOpen
      };
    });
    await this.persistCustomCategories();
    await this.persistCustomRestaurants();
    await this.persistFavoriteCategoryIds();
    return {
      affectedRestaurantCount: affectedRestaurantCount,
      orphanRestaurantCount: orphanRestaurantCount
    };
  }

  async saveRestaurant(restaurant: Restaurant): Promise<void> {
    const normalized: Restaurant = {
      id: restaurant.id,
      sourceType: RestaurantSourceType.CUSTOM,
      name: restaurant.name,
      latitude: restaurant.latitude,
      longitude: restaurant.longitude,
      categoryIds: restaurant.categoryIds.slice(),
      averagePrice: restaurant.averagePrice,
      rating: restaurant.rating,
      businessHours: restaurant.businessHours,
      isOpen: restaurant.isOpen
    };
    const index: number = this.customRestaurants.findIndex((item: Restaurant) => item.id === normalized.id);
    if (index === -1) {
      this.customRestaurants.push(normalized);
    } else {
      this.customRestaurants[index] = normalized;
    }
    await this.persistCustomRestaurants();
  }

  async saveUserPreferences(preferences: UserPreferences): Promise<void> {
    this.userPreferences = this.normalizeUserPreferences(preferences);
    await this.storage.putString(LocalStorageKeys.USER_PREFERENCES, JSON.stringify(this.userPreferences));
  }

  async deleteRestaurant(restaurantId: string): Promise<void> {
    this.customRestaurants = this.customRestaurants.filter((restaurant: Restaurant) => restaurant.id !== restaurantId);
    this.favoriteRestaurantIds = this.favoriteRestaurantIds.filter((id: string) => id !== restaurantId);
    await this.persistCustomRestaurants();
    await this.persistFavoriteRestaurantIds();
  }

  private toggleId(ids: string[], id: string): string[] {
    return ids.indexOf(id) === -1 ? ids.concat(id) : ids.filter((item: string) => item !== id);
  }

  private async persistFavoriteCategoryIds(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.FAVORITE_CATEGORY_IDS, JSON.stringify(this.favoriteCategoryIds));
  }

  private async persistFavoriteRestaurantIds(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.FAVORITE_RESTAURANT_IDS, JSON.stringify(this.favoriteRestaurantIds));
  }

  private async persistCustomCategories(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.CUSTOM_CATEGORIES, JSON.stringify(this.customCategories));
  }

  private async persistCustomRestaurants(): Promise<void> {
    await this.storage.putString(LocalStorageKeys.CUSTOM_RESTAURANTS, JSON.stringify(this.customRestaurants));
  }

  private createDefaultUserPreferences(): UserPreferences {
    return {
      selectedDistanceMeters: 0,
      selectedBudget: BudgetOption.ALL,
      selectedSpice: 'all',
      locationLabel: '默认位置'
    };
  }

  private normalizeUserPreferences(preferences: UserPreferences): UserPreferences {
    const defaultPreferences: UserPreferences = this.createDefaultUserPreferences();
    const distanceMeters: number = preferences.selectedDistanceMeters === 500 ||
      preferences.selectedDistanceMeters === 1000 || preferences.selectedDistanceMeters === 3000 ?
      preferences.selectedDistanceMeters : defaultPreferences.selectedDistanceMeters;
    const budget: BudgetOption = this.isSupportedBudget(preferences.selectedBudget) ?
      preferences.selectedBudget : defaultPreferences.selectedBudget;
    const selectedSpice: string = this.isSupportedSpice(preferences.selectedSpice) ?
      preferences.selectedSpice : defaultPreferences.selectedSpice;
    const location: GeoPoint | undefined = preferences.manualLocation;
    const normalized: UserPreferences = {
      selectedDistanceMeters: distanceMeters,
      selectedBudget: budget,
      selectedSpice: selectedSpice,
      locationLabel: preferences.locationLabel !== undefined && preferences.locationLabel.length > 0 ?
        preferences.locationLabel : defaultPreferences.locationLabel
    };
    if (location !== undefined && this.isValidLocation(location)) {
      normalized.manualLocation = {
        latitude: location.latitude,
        longitude: location.longitude
      };
    }
    return normalized;
  }

  private isSupportedBudget(budget: BudgetOption): boolean {
    return budget === BudgetOption.ALL || budget === BudgetOption.UNDER_30 ||
      budget === BudgetOption.FROM_30_TO_60 || budget === BudgetOption.FROM_60_TO_100;
  }

  private isSupportedSpice(spice: string): boolean {
    return spice === 'all' || spice === SpiceLevel.NOT_SPICY || spice === SpiceLevel.MILD ||
      spice === SpiceLevel.SPICY;
  }

  private isValidLocation(location: GeoPoint): boolean {
    return location.latitude === location.latitude && location.longitude === location.longitude &&
      location.latitude >= -90 && location.latitude <= 90 &&
      location.longitude >= -180 && location.longitude <= 180;
  }
}

```
