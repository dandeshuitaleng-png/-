# entry/src/main/ets/services/RestaurantRepository.ets

```typescript
import { RestaurantDataAdapter } from '../data/adapters/RestaurantDataAdapter';
import { RestaurantSearchRequest, RestaurantSearchResult } from '../models/RestaurantSearch';

export class RestaurantRepository {
  private readonly adapter: RestaurantDataAdapter;

  constructor(adapter: RestaurantDataAdapter) {
    this.adapter = adapter;
  }

  async searchNearby(request: RestaurantSearchRequest): Promise<RestaurantSearchResult> {
    return this.adapter.searchNearby(request);
  }
}

```
