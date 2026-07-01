export class LocalStorageKeys {
  static readonly FAVORITE_CATEGORY_IDS: string = 'favoriteCategoryIds';
  static readonly FAVORITE_RESTAURANT_IDS: string = 'favoriteRestaurantIds';
  static readonly CUSTOM_CATEGORIES: string = 'customCategories';
  static readonly CUSTOM_RESTAURANTS: string = 'customRestaurants';
  static readonly USER_PREFERENCES: string = 'userPreferences';
}

export interface LocalStorageAdapter {
  getString(key: string, defaultValue: string): Promise<string>;
  putString(key: string, value: string): Promise<void>;
}

export class MemoryLocalStorageAdapter implements LocalStorageAdapter {
  private values: Map<string, string> = new Map<string, string>();

  async getString(key: string, defaultValue: string): Promise<string> {
    return this.values.has(key) ? this.values.get(key) ?? defaultValue : defaultValue;
  }

  async putString(key: string, value: string): Promise<void> {
    this.values.set(key, value);
  }
}

