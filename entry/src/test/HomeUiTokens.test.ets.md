# entry/src/test/HomeUiTokens.test.ets

```typescript
import { describe, expect, it } from '@ohos/hypium';
import { HomeUiTokens } from '../main/ets/components/HomeUiTokens';

export default function homeUiTokensTest() {
  describe('HomeUiTokens', () => {
    it('flipAnimationSlowsDownTowardResult', 0, () => {
      for (let index: number = 1; index < HomeUiTokens.FLIP_STEP_DURATIONS.length; index++) {
        expect(HomeUiTokens.FLIP_STEP_DURATIONS[index] > HomeUiTokens.FLIP_STEP_DURATIONS[index - 1]).assertTrue();
      }
    });

    it('flipAnimationDurationStaysWithinProductRange', 0, () => {
      let totalDuration: number = 0;
      HomeUiTokens.FLIP_STEP_DURATIONS.forEach((duration: number) => {
        totalDuration += duration;
      });

      expect(totalDuration >= 1000).assertTrue();
      expect(totalDuration <= 2000).assertTrue();
    });

    it('questionOptionHeightUsesComfortableTouchTarget', 0, () => {
      expect(HomeUiTokens.QUESTION_OPTION_HEIGHT).assertEqual(48);
    });

    it('questionSelectionFeedbackDurationStaysWithinProductRange', 0, () => {
      expect(HomeUiTokens.QUESTION_SELECTION_FEEDBACK_DURATION >= 120).assertTrue();
      expect(HomeUiTokens.QUESTION_SELECTION_FEEDBACK_DURATION <= 180).assertTrue();
    });

    it('modeSwitchTransitionStaysLightweight', 0, () => {
      expect(HomeUiTokens.MODE_SWITCH_TRANSLATE_DISTANCE > 0).assertTrue();
      expect(HomeUiTokens.MODE_SWITCH_TRANSITION_DURATION >= 180).assertTrue();
      expect(HomeUiTokens.MODE_SWITCH_TRANSITION_DURATION <= 220).assertTrue();
    });
  });
}

```
