import { describe, expect, it } from '@ohos/hypium';
import { MockRestaurantAdapter } from '../main/ets/data/adapters/MockRestaurantAdapter';
import { GeoPoint } from '../main/ets/models/Location';
import { NearbyRestaurant, RestaurantSearchResult } from '../main/ets/models/RestaurantSearch';

const CENTER_SHANGHAI: GeoPoint = { latitude: 31.2304, longitude: 121.4737 };
const CENTER_BEIJING: GeoPoint = { latitude: 39.9042, longitude: 116.4074 };
const CENTER_GUANGZHOU: GeoPoint = { latitude: 23.1291, longitude: 113.2644 };

function validateRestaurant(item: NearbyRestaurant): void {
  expect(item.restaurant.id.length).assertLarger(0);
  expect(item.restaurant.name.length).assertLarger(0);
  expect(item.restaurant.latitude).assertLarger(-90);
  expect(item.restaurant.latitude).assertLess(90);
  expect(item.restaurant.longitude).assertLarger(-180);
  expect(item.restaurant.longitude).assertLess(180);
}

function minDistance(restaurants: NearbyRestaurant[]): number {
  return Math.min(...restaurants.map((r: NearbyRestaurant) => r.distanceMeters));
}

function maxDistance(restaurants: NearbyRestaurant[]): number {
  return Math.max(...restaurants.map((r: NearbyRestaurant) => r.distanceMeters));
}

export default function mockRestaurantAdapterTest() {
  describe('MockRestaurantAdapter', () => {
    it('searchNearby_returnsAll24Within3km_shanghai', 0, async () => {
      const adapter: MockRestaurantAdapter = new MockRestaurantAdapter();
      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: CENTER_SHANGHAI,
        radiusMeters: 3000
      });

      expect(result.restaurants.length).assertEqual(24);

      const minDist: number = minDistance(result.restaurants);
      const maxDist: number = maxDistance(result.restaurants);

      expect(minDist).assertLarger(0);
      expect(maxDist).assertLess(3001);

      for (const item of result.restaurants) {
        validateRestaurant(item);
      }
    });

    it('searchNearby_dynamicPositionDiffersFromOriginal_beijing', 0, async () => {
      const adapter: MockRestaurantAdapter = new MockRestaurantAdapter();
      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: CENTER_BEIJING,
        radiusMeters: 3000
      });

      expect(result.restaurants.length).assertEqual(24);

      const maxDist: number = maxDistance(result.restaurants);
      expect(maxDist).assertLess(3001);

      // Verify positions are actually shifted to Beijing area, not Shanghai
      for (const item of result.restaurants) {
        const latDiff: number = Math.abs(item.restaurant.latitude - CENTER_BEIJING.latitude);
        const lngDiff: number = Math.abs(item.restaurant.longitude - CENTER_BEIJING.longitude);
        expect(latDiff).assertLess(0.04);
        expect(lngDiff).assertLess(0.04);
      }
    });

    it('searchNearby_shopsSpanFrom100mTo3km_guangzhou', 0, async () => {
      const adapter: MockRestaurantAdapter = new MockRestaurantAdapter();
      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: CENTER_GUANGZHOU,
        radiusMeters: 3000
      });

      expect(result.restaurants.length).assertEqual(24);

      const minDist: number = minDistance(result.restaurants);
      const maxDist: number = maxDistance(result.restaurants);

      // Minimum distance should be at least 100m (target floor)
      expect(minDist).assertLarger(99);
      // Maximum distance must not exceed 3000m
      expect(maxDist).assertLess(3001);
      // Spread should cover a meaningful range (at least 2000m between min and max)
      expect(maxDist - minDist).assertLarger(1999);
    });

    it('searchNearby_reducedRadiusExcludesFarShops', 0, async () => {
      const adapter: MockRestaurantAdapter = new MockRestaurantAdapter();
      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: CENTER_SHANGHAI,
        radiusMeters: 500
      });

      expect(result.restaurants.length).assertLarger(0);
      expect(result.restaurants.length).assertLess(24);

      const maxDist: number = maxDistance(result.restaurants);
      expect(maxDist).assertLess(501);
    });

    it('searchNearby_invalidRadiusReturnsFailure', 0, async () => {
      const adapter: MockRestaurantAdapter = new MockRestaurantAdapter();
      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: CENTER_SHANGHAI,
        radiusMeters: 0
      });

      expect(result.restaurants.length).assertEqual(0);
    });

    it('searchNearby_zeroRadiusReturnsFailure', 0, async () => {
      const adapter: MockRestaurantAdapter = new MockRestaurantAdapter();
      const result: RestaurantSearchResult = await adapter.searchNearby({
        location: CENTER_SHANGHAI,
        radiusMeters: -1
      });

      expect(result.restaurants.length).assertEqual(0);
    });
  });
}

