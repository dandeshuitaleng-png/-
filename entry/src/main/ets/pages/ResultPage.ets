import { HomeUiTokens } from '../components/HomeUiTokens';
import { FoodCategory } from '../models/FoodCategory';
import { NearbyRestaurant } from '../models/RestaurantSearch';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { LocationPanel } from './HomePage';
import { StatusText, SystemActionNotice, ChipButton } from '../components/SharedComponents';

@ComponentV2
export struct ResultPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      ResultHeaderBlock({ vm: this.vm })
      ResultRestaurantList({ vm: this.vm })
      ResultActions({ vm: this.vm })
    }
    .width('100%')
  }
}

@ComponentV2
struct ResultHeaderBlock {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      if (this.vm.selectedCategory !== undefined) {
        ResultCategoryBadge({ category: this.vm.selectedCategory! })
      }
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.brand_soft'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
struct ResultCategoryBadge {
  @Param category: FoodCategory = new FoodCategory();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
      Text(this.category.name)
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Text(this.category.mealPeriods.join(' · '))
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_secondary'))
        Text('·')
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_tertiary'))
        Text(this.category.foodFeelings.join(' · '))
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_secondary'))
      }
    }
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
struct ResultRestaurantList {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      if (this.vm.resultRestaurants.length === 0) {
        Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          Text('暂无结果')
            .fontSize(HomeUiTokens.FONT_BODY)
            .fontColor($r('app.color.text_secondary'))
        }
        .width('100%')
        .padding(HomeUiTokens.CARD_PADDING)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.CARD_RADIUS)
      }

      ForEach(this.vm.resultRestaurants, (item: NearbyRestaurant) => {
        RestaurantCardItem({ item: item, vm: this.vm })
      }, (item: NearbyRestaurant) => item.restaurant.id)
    }
    .width('100%')
  }
}

@ComponentV2
struct RestaurantCardItem {
  @Param item: NearbyRestaurant = new NearbyRestaurant();
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
          Text(this.item.restaurant.name)
            .fontSize(HomeUiTokens.FONT_BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(`人均 ¥${this.item.restaurant.averagePrice}`)
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.text_secondary'))
        }
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Start)

        Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
          Text(this.vm.formatDistance(this.item.distanceMeters))
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.brand_primary'))

          Text(this.vm.formatRating(this.item.restaurant.rating))
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.text_tertiary'))
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button('导航')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.openMapNavigation(
              this.item.restaurant.name,
              this.item.restaurant.latitude,
              this.item.restaurant.longitude
            );
          })

        Button(this.vm.isFavoriteRestaurant(this.item.restaurant.id) ? '已收藏' : '收藏')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor(this.vm.isFavoriteRestaurant(this.item.restaurant.id) ?
            $r('app.color.warning') : $r('app.color.text_secondary'))
          .backgroundColor(this.vm.isFavoriteRestaurant(this.item.restaurant.id) ?
            $r('app.color.warning_soft') : $r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.toggleFavoriteRestaurant(this.item.restaurant.id);
          })
      }
      .width('100%')

      if (this.item.restaurant.businessHours.length > 0) {
        Text(`营业时间: ${this.item.restaurant.businessHours}`)
          .width('100%')
          .fontSize(HomeUiTokens.FONT_SMALL)
          .fontColor($r('app.color.text_tertiary'))
      }
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }
}

@ComponentV2
struct ResultActions {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      SystemActionNotice({ message: this.vm.systemActionMessage })

      StatusText({ notice: this.vm.notice, errorMessage: this.vm.errorMessage })

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button('再抽一次')
          .layoutWeight(2)
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .enabled(!this.vm.isLoading)
          .onClick(() => {
            this.vm.drawAgain();
          })

        Button('返回首页')
          .layoutWeight(1)
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.backToHome();
          })
      }
      .width('100%')

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button(this.vm.isFavoriteCategory(this.vm.selectedCategory?.id ?? '') ? '已收藏该品类' : '收藏该品类')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor(this.vm.isFavoriteCategory(this.vm.selectedCategory?.id ?? '') ?
            $r('app.color.warning') : $r('app.color.text_secondary'))
          .onClick(() => {
            const id: string = this.vm.selectedCategory?.id ?? '';
            if (id.length > 0) {
              this.vm.toggleFavoriteCategory(id);
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ top: HomeUiTokens.ITEM_GAP_COMPACT, bottom: HomeUiTokens.PAGE_PADDING })
  }
}
