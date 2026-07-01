# entry/src/test/FeatureFlags.test.ets

```typescript
import { describe, expect, it } from '@ohos/hypium';
import { ENABLE_DEVICE_LOCATION_ON_STARTUP } from '../main/ets/config/FeatureFlags';

export default function featureFlagsTest() {
  describe('FeatureFlags', () => {
    it('deviceLocationGateIsDisabledForEmulatorTesting', 0, () => {
      expect(ENABLE_DEVICE_LOCATION_ON_STARTUP).assertFalse();
    });
  });
}

```
