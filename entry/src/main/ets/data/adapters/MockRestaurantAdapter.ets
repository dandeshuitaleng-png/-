import { GeoPoint } from '../../models/Location';
import {
  NearbyRestaurant,
  RestaurantSearchRequest,
  RestaurantSearchResult,
  RestaurantSearchStatus
} from '../../models/RestaurantSearch';
import { MOCK_RESTAURANTS } from '../mock/MockRestaurants';
import { DEFAULT_MOCK_LOCATION } from '../mock/MockLocation';
import { Restaurant, RestaurantSourceType } from '../../models/Restaurant';
import { RestaurantDataAdapter } from './RestaurantDataAdapter';
import { haversineDistance, calculateBearing, destinationPoint } from '../../utils/GeoUtils';

export class MockRestaurantAdapter implements RestaurantDataAdapter {
  private readonly MOCK_RANGE_SCALE: number = 2.7;

  async searchNearby(request: RestaurantSearchRequest): Promise<RestaurantSearchResult> {
    if (request.radiusMeters <= 0) {
      return {
        status: RestaurantSearchStatus.FAILURE,
        restaurants: [],
        errorMessage: '搜索范围无效，请稍后重试。'
      };
    }

    const restaurants: NearbyRestaurant[] = MOCK_RESTAURANTS
      .map((restaurant: Restaurant): NearbyRestaurant => {
        const originalDistance: number = haversineDistance(DEFAULT_MOCK_LOCATION, {
          latitude: restaurant.latitude,
          longitude: restaurant.longitude
        });
        const bearing: number = calculateBearing(DEFAULT_MOCK_LOCATION, {
          latitude: restaurant.latitude,
          longitude: restaurant.longitude
        });
        const scaledDistance: number = originalDistance * this.MOCK_RANGE_SCALE;
        const shifted: GeoPoint = destinationPoint(request.location, scaledDistance, bearing);
        return {
          restaurant: {
            id: restaurant.id,
            sourceType: restaurant.sourceType,
            name: restaurant.name,
            latitude: shifted.latitude,
            longitude: shifted.longitude,
            categoryIds: restaurant.categoryIds,
            averagePrice: restaurant.averagePrice,
            rating: restaurant.rating,
            businessHours: restaurant.businessHours,
            isOpen: restaurant.isOpen
          },
          distanceMeters: haversineDistance(request.location, shifted)
        };
      })
      .filter((item: NearbyRestaurant) => item.distanceMeters <= request.radiusMeters)
      .sort((left: NearbyRestaurant, right: NearbyRestaurant) => left.distanceMeters - right.distanceMeters);

    return {
      status: RestaurantSearchStatus.SUCCESS,
      restaurants: restaurants,
      errorMessage: ''
    };
  }
}

