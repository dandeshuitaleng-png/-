import { common, display } from '@kit.AbilityKit';
import { HomeUiTokens } from '../components/HomeUiTokens';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { LocatingPage, PermissionGuidePage, LocationFailedPage } from '../components/StartupPages';
import { HomePage } from '../pages/HomePage';
import { FlipPage } from '../pages/FlipPage';
import { ResultPage } from '../pages/ResultPage';
import { FavoritesPage } from '../pages/FavoritesPage';
import { RestaurantFormPage } from '../pages/RestaurantFormPage';
import { CategoryManagerPage } from '../pages/CategoryManagerPage';
import { CategoryFormPage } from '../pages/CategoryFormPage';

@Entry
@ComponentV2
struct Index {
  @Local vm: AppViewModel = new AppViewModel();

  aboutToAppear(): void {
    this.vm.uiContext = this.getUIContext();
    this.vm.initialize();
    this.setupSwipeGesture();
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      if (!this.vm.locationReady) {
        if (this.vm.isLocating) {
          LocatingPage({ vm: this.vm })
        } else if (this.vm.locationFailed) {
          LocationFailedPage({ vm: this.vm })
        } else {
          PermissionGuidePage({ vm: this.vm })
        }
      } else {
        this.buildMainContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_background'))
  }

  @Builder
  buildMainContent() {
    Column() {
      // Navigation bar (shown on non-home pages)
      if (this.vm.currentPage !== 'home') {
        Row() {
          Button('‹ 返回')
            .height(HomeUiTokens.NAV_BAR_HEIGHT)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor($r('app.color.brand_primary'))
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.vm.goBack();
            })

          Text(this.getPageTitle())
            .layoutWeight(1)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .height(HomeUiTokens.NAV_BAR_HEIGHT)
        .padding({ left: HomeUiTokens.PAGE_PADDING, right: HomeUiTokens.PAGE_PADDING })
        .backgroundColor($r('app.color.page_background'))
      }

      // Page content
      Scroll() {
        Column() {
          if (this.vm.currentPage === 'home') {
            HomePage({ vm: this.vm })
          } else if (this.vm.currentPage === 'flip') {
            FlipPage({ vm: this.vm })
          } else if (this.vm.currentPage === 'result') {
            ResultPage({ vm: this.vm })
          } else if (this.vm.currentPage === 'favorites') {
            FavoritesPage({ vm: this.vm })
          } else if (this.vm.currentPage === 'restaurantForm') {
            RestaurantFormPage({ vm: this.vm })
          } else if (this.vm.currentPage === 'categoryManager') {
            CategoryManagerPage({ vm: this.vm })
          } else if (this.vm.currentPage === 'categoryForm') {
            CategoryFormPage({ vm: this.vm })
          }
        }
        .width('100%')
        .padding({
          left: HomeUiTokens.PAGE_PADDING,
          right: HomeUiTokens.PAGE_PADDING,
          top: HomeUiTokens.ITEM_GAP_COMPACT,
          bottom: HomeUiTokens.PAGE_PADDING
        })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)

      // Bottom nav (home-only)
      if (this.vm.currentPage === 'home') {
        Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          Button('首页')
            .layoutWeight(1)
            .height(HomeUiTokens.BOTTOM_NAV_HEIGHT)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor(this.vm.currentPage === 'home' ? $r('app.color.brand_primary') : $r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .onClick(() => {
              this.vm.backToHome();
            })

          Button('收藏')
            .layoutWeight(1)
            .height(HomeUiTokens.BOTTOM_NAV_HEIGHT)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor(Color.Transparent)
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .onClick(() => {
              this.vm.currentPage = 'favorites';
            })
        }
        .width('100%')
        .height(HomeUiTokens.BOTTOM_NAV_HEIGHT + HomeUiTokens.PAGE_PADDING)
        .padding({ left: HomeUiTokens.PAGE_PADDING, right: HomeUiTokens.PAGE_PADDING, bottom: HomeUiTokens.PAGE_PADDING })
        .backgroundColor($r('app.color.card_background'))
      }
    }
    .width('100%')
    .height('100%')
  }

  private getPageTitle(): string {
    if (this.vm.currentPage === 'flip') return '';
    if (this.vm.currentPage === 'result') return '推荐结果';
    if (this.vm.currentPage === 'favorites') return '收藏';
    if (this.vm.currentPage === 'restaurantForm') return this.vm.editingRestaurantId.length > 0 ? '编辑店铺' : '添加店铺';
    if (this.vm.currentPage === 'categoryManager') return '品类管理';
    if (this.vm.currentPage === 'categoryForm') return this.vm.editingCategoryId.length > 0 ? '编辑品类' : '新建品类';
    return '';
  }

  private setupSwipeGesture(): void {
    // TODO: wire swipe for mode switching on home page
  }
}
