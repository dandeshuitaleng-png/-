# entry/src/main/ets/data/adapters/RestaurantDataAdapter.ets

```typescript
import { RestaurantSearchRequest, RestaurantSearchResult } from '../../models/RestaurantSearch';

// Map providers must normalize asynchronous nearby searches before entering
// recommendation logic. Real providers can report network or provider failures.
export interface RestaurantDataAdapter {
  searchNearby(request: RestaurantSearchRequest): Promise<RestaurantSearchResult>;
}

```
