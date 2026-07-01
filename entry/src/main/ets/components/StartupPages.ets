import { HomeUiTokens } from '../components/HomeUiTokens';
import { DEFAULT_MOCK_LOCATION, LocationPreset, MANUAL_LOCATION_PRESETS } from '../data/mock/MockLocation';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { PlateIllustration, SystemActionNotice } from '../components/SharedComponents';

// ═══════════════════════════════════════════
// STARTUP PAGES (locating / permission guide / location failed)
// ═══════════════════════════════════════════

@ComponentV2
export struct LocatingPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.SECTION_GAP_LARGE }) {
      Text('今天吃什么')
        .fontSize(HomeUiTokens.FONT_DISPLAY)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      PlateIllustration()

      Text('正在获取你的位置...')
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontColor($r('app.color.text_secondary'))

      LoadingProgress()
        .width(36)
        .height(36)
        .color($r('app.color.brand_primary'))
    }
    .width('100%')
    .height('100%')
    .padding({
      left: HomeUiTokens.PAGE_PADDING,
      right: HomeUiTokens.PAGE_PADDING,
      top: HomeUiTokens.PAGE_PADDING,
      bottom: HomeUiTokens.PAGE_PADDING
    })
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct PermissionGuidePage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.SECTION_GAP_LARGE }) {
      Text('定位没有打开')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text('可以开启系统定位，也可以先用手动位置继续。')
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(24)

      ManualLocationControls({ vm: this.vm })

      Button('前往系统设置')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.vm.openAppSettings();
        })

      SystemActionNotice({ message: this.vm.systemActionMessage })

      Button('使用默认位置继续')
        .width('100%')
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.continueWithManualLocation(DEFAULT_MOCK_LOCATION, '默认位置');
        })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: HomeUiTokens.PAGE_PADDING,
      right: HomeUiTokens.PAGE_PADDING,
      top: HomeUiTokens.PAGE_PADDING,
      bottom: HomeUiTokens.PAGE_PADDING
    })
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct LocationFailedPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.SECTION_GAP_LARGE }) {
      Text('定位失败')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Text('暂时拿不到系统位置，可以重试，也可以手动设置一个附近中心点。')
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .lineHeight(24)

      ManualLocationControls({ vm: this.vm })

      SystemActionNotice({ message: this.vm.systemActionMessage })

      Button('重试')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.vm.locationFailed = false;
          this.vm.isLocating = true;
          this.vm.getDeviceLocation();
        })

      Button('使用默认位置继续')
        .width('100%')
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.continueWithManualLocation(DEFAULT_MOCK_LOCATION, '默认位置');
        })
    }
    .width('100%')
    .height('100%')
    .padding({
      left: HomeUiTokens.PAGE_PADDING,
      right: HomeUiTokens.PAGE_PADDING,
      top: HomeUiTokens.PAGE_PADDING,
      bottom: HomeUiTokens.PAGE_PADDING
    })
    .backgroundColor($r('app.color.page_background'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

// ═══════════════════════════════════════════
// SHARED LOCATION CONTROLS (used by startup pages + home locationPanel)
// ═══════════════════════════════════════════

@ComponentV2
export struct ManualLocationControls {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach(MANUAL_LOCATION_PRESETS, (preset: LocationPreset) => {
          Button(preset.label)
            .layoutWeight(1)
            .height(HomeUiTokens.FILTER_BUTTON_HEIGHT)
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor(this.vm.currentLocationLabel === preset.label ? Color.White : $r('app.color.text_secondary'))
            .backgroundColor(this.vm.currentLocationLabel === preset.label ?
              $r('app.color.brand_primary') : $r('app.color.brand_soft'))
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .onClick(() => {
              this.vm.continueWithManualLocation(preset.location, preset.label);
            })
        }, (preset: LocationPreset) => preset.id)
      }
      .width('100%')

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        TextInput({ placeholder: '纬度', text: this.vm.manualLatitudeInput })
          .layoutWeight(1)
          .height(HomeUiTokens.FORM_FIELD_HEIGHT)
          .onChange((value: string) => this.vm.manualLatitudeInput = value)
        TextInput({ placeholder: '经度', text: this.vm.manualLongitudeInput })
          .layoutWeight(1)
          .height(HomeUiTokens.FORM_FIELD_HEIGHT)
          .onChange((value: string) => this.vm.manualLongitudeInput = value)
      }
      .width('100%')

      Button('应用手动位置')
        .width('100%')
        .height(HomeUiTokens.LIST_ACTION_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.brand_soft'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.applyManualLocationInput();
        })
    }
    .width('100%')
  }
}
