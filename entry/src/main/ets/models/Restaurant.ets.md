# entry/src/main/ets/models/Restaurant.ets

```typescript
export enum RestaurantSourceType {
  MOCK = 'mock',
  CUSTOM = 'custom',
  MAP = 'map'
}

export interface Restaurant {
  id: string;
  sourceType: RestaurantSourceType;
  name: string;
  latitude: number;
  longitude: number;
  categoryIds: string[];
  averagePrice: number;
  rating?: number;
  businessHours?: string;
  isOpen: boolean;
}

```
