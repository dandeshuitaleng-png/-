# entry/src/main/ets/data/adapters/CombinedRestaurantAdapter.ets

```typescript
import { GeoPoint } from '../../models/Location';
import { Restaurant } from '../../models/Restaurant';
import {
  NearbyRestaurant,
  RestaurantSearchRequest,
  RestaurantSearchResult,
  RestaurantSearchStatus
} from '../../models/RestaurantSearch';
import { RestaurantDataAdapter } from './RestaurantDataAdapter';

export class CombinedRestaurantAdapter implements RestaurantDataAdapter {
  private readonly baseAdapter: RestaurantDataAdapter;
  private readonly customRestaurantProvider: () => Restaurant[];

  constructor(baseAdapter: RestaurantDataAdapter, customRestaurantProvider: () => Restaurant[]) {
    this.baseAdapter = baseAdapter;
    this.customRestaurantProvider = customRestaurantProvider;
  }

  async searchNearby(request: RestaurantSearchRequest): Promise<RestaurantSearchResult> {
    const baseResult: RestaurantSearchResult = await this.baseAdapter.searchNearby(request);
    if (baseResult.status === RestaurantSearchStatus.FAILURE) {
      return baseResult;
    }
    const customRestaurants: NearbyRestaurant[] = this.customRestaurantProvider()
      .map((restaurant: Restaurant): NearbyRestaurant => {
        return {
          restaurant: restaurant,
          distanceMeters: this.calculateDistanceMeters(request.location, {
            latitude: restaurant.latitude,
            longitude: restaurant.longitude
          })
        };
      })
      .filter((item: NearbyRestaurant) => item.distanceMeters <= request.radiusMeters);
    return {
      status: RestaurantSearchStatus.SUCCESS,
      restaurants: baseResult.restaurants.concat(customRestaurants)
        .sort((left: NearbyRestaurant, right: NearbyRestaurant) => left.distanceMeters - right.distanceMeters),
      errorMessage: ''
    };
  }

  private calculateDistanceMeters(from: GeoPoint, to: GeoPoint): number {
    const earthRadiusMeters: number = 6371000;
    const latitudeDelta: number = this.toRadians(to.latitude - from.latitude);
    const longitudeDelta: number = this.toRadians(to.longitude - from.longitude);
    const fromLatitude: number = this.toRadians(from.latitude);
    const toLatitude: number = this.toRadians(to.latitude);
    const haversine: number = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
      Math.cos(fromLatitude) * Math.cos(toLatitude) *
      Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);
    return Math.round(earthRadiusMeters * 2 *
      Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine)));
  }

  private toRadians(degrees: number): number {
    return degrees * Math.PI / 180;
  }
}

```
