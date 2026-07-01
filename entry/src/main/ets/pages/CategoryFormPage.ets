import { HomeUiTokens } from '../components/HomeUiTokens';
import { MealPeriod, FoodFeeling, SpiceLevel, BreakfastTrait } from '../models/FoodCategory';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { FormSectionTitle, ChipButton, StatusText, SystemActionNotice } from '../components/SharedComponents';

@ComponentV2
export struct CategoryFormPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      // Name
      FormSectionTitle({ title: '品类名称' })
      TextInput({ placeholder: '输入品类名称', text: this.vm.categoryNameInput })
        .width('100%')
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .onChange((value: string) => this.vm.categoryNameInput = value)

      // Meal periods
      FormSectionTitle({ title: '餐段' })
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach([
          { value: MealPeriod.BREAKFAST, label: '早餐' },
          { value: MealPeriod.LUNCH, label: '午餐' },
          { value: MealPeriod.DINNER, label: '晚餐' },
          { value: MealPeriod.LATE_NIGHT, label: '宵夜' }
        ], (item: MealPeriodOption) => {
          ChipButton({ label: item.label,
            selected: this.vm.categoryMealPeriods.indexOf(item.value) !== -1,
            onSelect: () => this.vm.toggleMealPeriod(item.value) })
        }, (item: MealPeriodOption) => item.value)
      }
      .width('100%')

      // Food feelings
      FormSectionTitle({ title: '食物感受' })
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach([
          { value: FoodFeeling.HOT_SOUP, label: '热汤水' },
          { value: FoodFeeling.COMFORT, label: '暖胃满足' },
          { value: FoodFeeling.LIGHT, label: '清爽轻食' },
          { value: FoodFeeling.RICH, label: '浓郁饱足' },
          { value: FoodFeeling.COLD, label: '凉感' }
        ], (item: FoodFeelingOption) => {
          ChipButton({ label: item.label,
            selected: this.vm.categoryFoodFeelings.indexOf(item.value) !== -1,
            onSelect: () => this.vm.toggleFoodFeeling(item.value) })
        }, (item: FoodFeelingOption) => item.value)
      }
      .width('100%')

      // Spice
      FormSectionTitle({ title: '辣度' })
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach([
          { value: SpiceLevel.NOT_SPICY, label: '不辣' },
          { value: SpiceLevel.MILD, label: '微辣' },
          { value: SpiceLevel.SPICY, label: '能吃辣' }
        ], (item: SpiceLevelOption) => {
          ChipButton({ label: item.label,
            selected: this.vm.categorySpiceLevels.indexOf(item.value) !== -1,
            onSelect: () => this.vm.toggleCategorySpice(item.value) })
        }, (item: SpiceLevelOption) => item.value)
      }
      .width('100%')

      // Breakfast traits (shown only when breakfast is selected)
      if (this.vm.categoryMealPeriods.indexOf(MealPeriod.BREAKFAST) !== -1) {
        FormSectionTitle({ title: '早餐特征 (可不选)' })
        Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          ForEach([
            { value: BreakfastTrait.DRY, label: '干' },
            { value: BreakfastTrait.WET, label: '湿' }
          ], (item: BreakfastTraitOption) => {
            ChipButton({ label: item.label,
              selected: this.vm.categoryBreakfastTraits.indexOf(item.value) !== -1,
              onSelect: () => this.vm.toggleBreakfastTrait(item.value) })
          }, (item: BreakfastTraitOption) => item.value)
        }
        .width('100%')
      }

      StatusText({ notice: this.vm.notice, errorMessage: this.vm.errorMessage })
      SystemActionNotice({ message: this.vm.systemActionMessage })

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button(this.vm.editingCategoryId.length > 0 ? '保存修改' : '创建品类')
          .layoutWeight(2)
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .onClick(() => {
            this.vm.saveCategoryForm();
          })

        Button('取消')
          .layoutWeight(1)
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.goBack();
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: HomeUiTokens.ITEM_GAP_COMPACT, bottom: HomeUiTokens.PAGE_PADDING })
  }
}

// ═══════════════════════════════════════════
// LOCAL OPTION TYPES (avoid model import for UI display labels)
// ═══════════════════════════════════════════

interface MealPeriodOption {
  value: MealPeriod;
  label: string;
}

interface FoodFeelingOption {
  value: FoodFeeling;
  label: string;
}

interface SpiceLevelOption {
  value: SpiceLevel;
  label: string;
}

interface BreakfastTraitOption {
  value: BreakfastTrait;
  label: string;
}
