import { HomeUiTokens } from '../components/HomeUiTokens';

// ═══════════════════════════════════════════════
// SHARED UI BUILDERS
// ═══════════════════════════════════════════════

@ComponentV2
export struct PlateIllustration {
  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Column()
          .width(4)
          .height(16)
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .backgroundColor($r('app.color.brand_primary'))
          .opacity(0.38)
        Column()
          .width(4)
          .height(22)
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .backgroundColor($r('app.color.brand_primary'))
          .opacity(0.38)
      }
      .alignItems(VerticalAlign.Bottom)

      Column() {
        Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          Column()
            .width(18)
            .height(18)
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .backgroundColor($r('app.color.brand_primary'))
          Column()
            .width(16)
            .height(16)
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .backgroundColor($r('app.color.accent_warm'))
          Column()
            .width(18)
            .height(18)
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .backgroundColor($r('app.color.success_soft'))
        }
      }
      .width(HomeUiTokens.PLATE_SIZE)
      .height(HomeUiTokens.PLATE_SIZE)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor($r('app.color.card_background'))
      .border({
        width: 1,
        color: $r('app.color.border_soft')
      })
      .borderRadius(HomeUiTokens.PILL_RADIUS)
    }
    .width(HomeUiTokens.ILLUSTRATION_SIZE)
    .height(HomeUiTokens.ILLUSTRATION_SIZE)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.brand_soft'))
    .borderRadius(HomeUiTokens.PILL_RADIUS)
  }
}

@ComponentV2
export struct FilterButton {
  @Param label: string = '';
  @Param selected: boolean = false;
  @Event onSelect?: () => void = undefined;

  build() {
    Button(this.label)
      .layoutWeight(1)
      .height(HomeUiTokens.FILTER_BUTTON_HEIGHT)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor(this.selected ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(this.selected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
      .borderRadius(HomeUiTokens.PILL_RADIUS)
      .onClick(() => {
        if (this.onSelect !== undefined) {
          this.onSelect();
        }
      })
  }
}

@ComponentV2
export struct FilterTitle {
  @Param title: string = '';

  build() {
    Text(this.title)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_secondary'))
  }
}

@ComponentV2
export struct ChipButton {
  @Param label: string = '';
  @Param selected: boolean = false;
  @Event onSelect?: () => void = undefined;

  build() {
    Button(this.label)
      .height(HomeUiTokens.CHOICE_CHIP_HEIGHT)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor(this.selected ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(this.selected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
      .borderRadius(HomeUiTokens.PILL_RADIUS)
      .padding({ left: 12, right: 12 })
      .onClick(() => {
        if (this.onSelect !== undefined) {
          this.onSelect();
        }
      })
  }
}

@ComponentV2
export struct ChoiceButton {
  @Param label: string = '';
  @Param selected: boolean = false;
  @Event onSelect?: () => void = undefined;

  build() {
    Button(this.label)
      .width('100%')
      .height(HomeUiTokens.FILTER_BUTTON_HEIGHT)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor(this.selected ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(this.selected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
      .borderRadius(HomeUiTokens.PILL_RADIUS)
      .onClick(() => {
        if (this.onSelect !== undefined) {
          this.onSelect();
        }
      })
  }
}

@ComponentV2
export struct EmptyState {
  @Param title: string = '';
  @Param description?: string = undefined;

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Text(this.title)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
      if (this.description !== undefined) {
        Text(this.description!)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .padding(HomeUiTokens.EMPTY_STATE_PADDING)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct FormSectionTitle {
  @Param title: string = '';

  build() {
    Text(this.title)
      .width('100%')
      .fontSize(HomeUiTokens.FONT_BODY_SMALL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
  }
}

@ComponentV2
export struct StatusText {
  @Param notice: string = '';
  @Param errorMessage: string = '';

  build() {
    if (this.errorMessage.length > 0) {
      Text(this.errorMessage)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.brand_primary'))
        .textAlign(TextAlign.Center)
    } else if (this.isDistanceExpansionNotice()) {
      Text(this.notice)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.warning'))
        .backgroundColor($r('app.color.warning_soft'))
        .borderRadius(HomeUiTokens.ITEM_GAP_COMPACT)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .textAlign(TextAlign.Center)
    } else {
      Text(this.notice)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
    }
  }

  private isDistanceExpansionNotice(): boolean {
    return this.notice.indexOf('附近选择不多，已经为你扩大范围') !== -1 ||
      this.notice.indexOf('这个组合附近选择不多，已经为你调整推荐范围') !== -1;
  }
}

@ComponentV2
export struct SystemActionNotice {
  @Param message: string = '';

  build() {
    if (this.message.length > 0) {
      Text(this.message)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.danger'))
        .backgroundColor($r('app.color.danger_soft'))
        .borderRadius(HomeUiTokens.ITEM_GAP_COMPACT)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .textAlign(TextAlign.Center)
    }
  }
}
