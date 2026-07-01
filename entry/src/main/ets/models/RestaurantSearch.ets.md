# entry/src/main/ets/models/RestaurantSearch.ets

```typescript
import { GeoPoint } from './Location';
import { Restaurant } from './Restaurant';

export enum RestaurantSearchStatus {
  SUCCESS = 'success',
  FAILURE = 'failure'
}

export interface RestaurantSearchRequest {
  location: GeoPoint;
  radiusMeters: number;
}

export interface NearbyRestaurant {
  restaurant: Restaurant;
  distanceMeters: number;
}

export interface RestaurantSearchResult {
  status: RestaurantSearchStatus;
  restaurants: NearbyRestaurant[];
  errorMessage: string;
}

```
