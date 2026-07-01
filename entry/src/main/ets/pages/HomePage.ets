import { LengthMetrics } from '@kit.ArkUI';
import { HomeUiTokens } from '../components/HomeUiTokens';
import { SpiceLevel, FoodCategory, MealPeriod, FoodFeeling, BreakfastTrait } from '../models/FoodCategory';
import { QuestionnaireOption } from '../models/Questionnaire';
import { BudgetOption } from '../models/Recommendation';
import { AppViewModel } from '../viewmodel/AppViewModel';
import {
  FilterButton, FilterTitle, StatusText, SystemActionNotice,
  PlateIllustration
} from '../components/SharedComponents';
import { ManualLocationControls } from '../components/StartupPages';

// ═══════════════════════════════════════════
// HOME PAGE
// ═══════════════════════════════════════════

@ComponentV2
export struct HomePage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Button('直接抽取')
        .layoutWeight(1)
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(this.vm.activeMode === 0 ? Color.White : $r('app.color.text_secondary'))
        .backgroundColor(this.vm.activeMode === 0 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.selectMode(0);
        })

      Button('回答两题')
        .layoutWeight(1)
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(this.vm.activeMode === 1 ? Color.White : $r('app.color.text_secondary'))
        .backgroundColor(this.vm.activeMode === 1 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.selectMode(1);
        })
    }
    .width('100%')

    LocationPanel({ vm: this.vm })

    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text(this.vm.activeMode === 0 ? '现在就帮你挑一个' : '先回答两题，再揭晓答案')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      PlateIllustration()

      Text(this.vm.activeMode === 0 ? '从附近营业中的店铺里，挑一种适合现在的口味。' :
        '午餐、晚餐和早餐会使用不同问题，让选择更贴近此刻的心情。')
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .lineHeight(22)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)

      if (this.vm.nearbyRestaurantCount > 0) {
        Text(`${this.vm.nearbyRestaurantCount} 家附近店铺已加载`)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      }

      if (this.vm.activeMode === 0) {
        Button(this.vm.getMainButtonText())
          .width('100%')
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .enabled(!this.vm.isLoading)
          .onClick(() => {
            this.vm.drawDirect();
          })
      } else {
        QuestionnairePanel({ vm: this.vm })
      }
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
    .translate({ x: this.vm.modeContentOffsetX })
    .animation({ duration: HomeUiTokens.MODE_SWITCH_TRANSITION_DURATION, curve: Curve.EaseOut })

    FilterPanel({ vm: this.vm })

    StatusText({ notice: this.vm.notice, errorMessage: this.vm.errorMessage })

    Text('模拟数据仅用于首版验证')
      .width('100%')
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor($r('app.color.text_tertiary'))
      .textAlign(TextAlign.Center)
  }
}

// ═══════════════════════════════════════════
// QUESTIONNAIRE PANEL (sub-component of HomePage)
// ═══════════════════════════════════════════

@ComponentV2
export struct QuestionnairePanel {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text(`第 ${this.vm.questionStep + 1} 题 / 共 2 题`)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.brand_primary'))

      Text(this.vm.getCurrentQuestion().title)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      ForEach(this.vm.getCurrentQuestion().options, (option: QuestionnaireOption) => {
        Button(option.label)
          .width('100%')
          .height(HomeUiTokens.QUESTION_OPTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor(this.vm.isQuestionOptionSelected(option) ? Color.White : $r('app.color.text_secondary'))
          .backgroundColor(this.vm.isQuestionOptionSelected(option) ?
            $r('app.color.brand_primary') : $r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .enabled(!this.vm.isLoading && !this.vm.isQuestionTransitioning)
          .onClick(() => {
            this.vm.selectQuestionOption(option);
          })
      }, (option: QuestionnaireOption) => option.id)

      if (this.vm.questionStep > 0) {
        Button('看看结果')
          .width('100%')
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .enabled(this.vm.canSubmitQuestionnaire() && !this.vm.isLoading)
          .onClick(() => {
            this.vm.submitQuestionnaire();
          })

        Button('返回修改上一题')
          .width('100%')
          .height(HomeUiTokens.QUESTION_BACK_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.questionStep = 0;
          })
      }
    }
    .width('100%')
    .padding(HomeUiTokens.QUESTION_PANEL_PADDING)
    .backgroundColor($r('app.color.brand_soft'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
    .alignItems(HorizontalAlign.Start)
  }
}

// ═══════════════════════════════════════════
// LOCATION PANEL (shared between home + result)
// ═══════════════════════════════════════════

@ComponentV2
export struct LocationPanel {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Row() {
        Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
          Text('当前位置')
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.text_secondary'))
          Text(this.vm.currentLocationLabel)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Start)

        Button(this.vm.locationPanelExpanded ? '收起' : '调整')
          .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.locationPanelExpanded = !this.vm.locationPanelExpanded;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      if (this.vm.locationPanelExpanded) {
        ManualLocationControls({ vm: this.vm })
      }
    }
    .width('100%')
    .padding(HomeUiTokens.SECTION_GAP)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }
}

// ═══════════════════════════════════════════
// FILTER PANEL
// ═══════════════════════════════════════════

@ComponentV2
export struct FilterPanel {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Row() {
        Text('筛选条件')
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(this.vm.filtersExpanded ? '收起' : '展开')
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(() => {
        this.vm.filtersExpanded = !this.vm.filtersExpanded;
      })

      if (this.vm.filtersExpanded) {
        Column({ space: HomeUiTokens.ITEM_GAP }) {
          FilterTitle({ title: '距离' })
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            FilterButton({ label: '不限', selected: this.vm.selectedDistanceMeters === 0,
              onSelect: () => this.vm.selectDistanceFilter(0) })
            FilterButton({ label: '500 米', selected: this.vm.selectedDistanceMeters === 500,
              onSelect: () => this.vm.selectDistanceFilter(500) })
            FilterButton({ label: '1 公里', selected: this.vm.selectedDistanceMeters === 1000,
              onSelect: () => this.vm.selectDistanceFilter(1000) })
            FilterButton({ label: '3 公里', selected: this.vm.selectedDistanceMeters === 3000,
              onSelect: () => this.vm.selectDistanceFilter(3000) })
          }
          .width('100%')

          FilterTitle({ title: '人均预算' })
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            FilterButton({ label: '不限', selected: this.vm.selectedBudget === BudgetOption.ALL,
              onSelect: () => this.vm.selectBudgetFilter(BudgetOption.ALL) })
            FilterButton({ label: '30 内', selected: this.vm.selectedBudget === BudgetOption.UNDER_30,
              onSelect: () => this.vm.selectBudgetFilter(BudgetOption.UNDER_30) })
            FilterButton({ label: '30-60', selected: this.vm.selectedBudget === BudgetOption.FROM_30_TO_60,
              onSelect: () => this.vm.selectBudgetFilter(BudgetOption.FROM_30_TO_60) })
            FilterButton({ label: '60-100', selected: this.vm.selectedBudget === BudgetOption.FROM_60_TO_100,
              onSelect: () => this.vm.selectBudgetFilter(BudgetOption.FROM_60_TO_100) })
          }
          .width('100%')

          FilterTitle({ title: '辣度' })
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            FilterButton({ label: '不限', selected: this.vm.selectedSpice === 'all',
              onSelect: () => this.vm.selectSpiceFilter('all') })
            FilterButton({ label: '不辣', selected: this.vm.selectedSpice === SpiceLevel.NOT_SPICY,
              onSelect: () => this.vm.selectSpiceFilter(SpiceLevel.NOT_SPICY) })
            FilterButton({ label: '微辣', selected: this.vm.selectedSpice === SpiceLevel.MILD,
              onSelect: () => this.vm.selectSpiceFilter(SpiceLevel.MILD) })
            FilterButton({ label: '能吃辣', selected: this.vm.selectedSpice === SpiceLevel.SPICY,
              onSelect: () => this.vm.selectSpiceFilter(SpiceLevel.SPICY) })
          }
          .width('100%')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .padding(HomeUiTokens.SECTION_GAP)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }
}
