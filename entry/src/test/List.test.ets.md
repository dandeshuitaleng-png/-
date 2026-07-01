# entry/src/test/List.test.ets

```typescript
import appContentServiceTest from './AppContentService.test';
import featureFlagsTest from './FeatureFlags.test';
import homeUiTokensTest from './HomeUiTokens.test';
import localUnitTest from './LocalUnit.test';
import mockRestaurantAdapterTest from './MockRestaurantAdapter.test';
import questionnaireTest from './Questionnaire.test';
import recommendationServiceTest from './RecommendationService.test';

export default function testsuite() {
  appContentServiceTest();
  featureFlagsTest();
  homeUiTokensTest();
  localUnitTest();
  mockRestaurantAdapterTest();
  questionnaireTest();
  recommendationServiceTest();
}

```
