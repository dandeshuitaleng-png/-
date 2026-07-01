import { GeoPoint } from '../../models/Location';
import { Restaurant } from '../../models/Restaurant';
import {
  NearbyRestaurant,
  RestaurantSearchRequest,
  RestaurantSearchResult,
  RestaurantSearchStatus
} from '../../models/RestaurantSearch';
import { RestaurantDataAdapter } from './RestaurantDataAdapter';
import { haversineDistance } from '../../utils/GeoUtils';

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
          distanceMeters: haversineDistance(request.location, {
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
}

