# entry/src/main/ets/data/adapters/MockRestaurantAdapter.ets

```typescript
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
        const originalDistance: number = this.calculateDistanceMeters(DEFAULT_MOCK_LOCATION, {
          latitude: restaurant.latitude,
          longitude: restaurant.longitude
        });
        const bearing: number = this.calculateBearing(DEFAULT_MOCK_LOCATION, {
          latitude: restaurant.latitude,
          longitude: restaurant.longitude
        });
        const scaledDistance: number = originalDistance * this.MOCK_RANGE_SCALE;
        const shifted: GeoPoint = this.destinationPoint(request.location, scaledDistance, bearing);
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
          distanceMeters: this.calculateDistanceMeters(request.location, shifted)
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

  private calculateDistanceMeters(from: GeoPoint, to: GeoPoint): number {
    const earthRadiusMeters: number = 6371000;
    const latitudeDelta: number = this.toRadians(to.latitude - from.latitude);
    const longitudeDelta: number = this.toRadians(to.longitude - from.longitude);
    const fromLatitude: number = this.toRadians(from.latitude);
    const toLatitude: number = this.toRadians(to.latitude);
    const haversine: number = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
      Math.cos(fromLatitude) * Math.cos(toLatitude) *
      Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);
    const angularDistance: number = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
    return Math.round(earthRadiusMeters * angularDistance);
  }

  private calculateBearing(from: GeoPoint, to: GeoPoint): number {
    const fromLat: number = this.toRadians(from.latitude);
    const toLat: number = this.toRadians(to.latitude);
    const deltaLng: number = this.toRadians(to.longitude - from.longitude);
    const y: number = Math.sin(deltaLng) * Math.cos(toLat);
    const x: number = Math.cos(fromLat) * Math.sin(toLat) -
      Math.sin(fromLat) * Math.cos(toLat) * Math.cos(deltaLng);
    const bearingRad: number = Math.atan2(y, x);
    return this.toDegrees(bearingRad);
  }

  private destinationPoint(from: GeoPoint, distanceMeters: number, bearingDegrees: number): GeoPoint {
    const earthRadiusMeters: number = 6371000;
    const angularDistance: number = distanceMeters / earthRadiusMeters;
    const bearingRad: number = this.toRadians(bearingDegrees);
    const fromLat: number = this.toRadians(from.latitude);
    const fromLng: number = this.toRadians(from.longitude);
    const toLat: number = Math.asin(
      Math.sin(fromLat) * Math.cos(angularDistance) +
      Math.cos(fromLat) * Math.sin(angularDistance) * Math.cos(bearingRad)
    );
    const toLng: number = fromLng + Math.atan2(
      Math.sin(bearingRad) * Math.sin(angularDistance) * Math.cos(fromLat),
      Math.cos(angularDistance) - Math.sin(fromLat) * Math.sin(toLat)
    );
    return {
      latitude: this.toDegrees(toLat),
      longitude: this.toDegrees(toLng)
    };
  }

  private toRadians(degrees: number): number {
    return degrees * Math.PI / 180;
  }

  private toDegrees(radians: number): number {
    return radians * 180 / Math.PI;
  }
}

```
