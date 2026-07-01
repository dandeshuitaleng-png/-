import { HomeUiTokens } from '../components/HomeUiTokens';
import { FoodCategory } from '../models/FoodCategory';
import { Restaurant } from '../models/Restaurant';
import { NearbyRestaurant } from '../models/RestaurantSearch';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { StatusText, SystemActionNotice } from '../components/SharedComponents';

@ComponentV2
export struct FavoritesPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      FavoritesTabBar({ vm: this.vm })
      FavoritesContent({ vm: this.vm })
    }
    .width('100%')
  }
}

@ComponentV2
struct FavoritesTabBar {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Button('收藏品类')
        .layoutWeight(1)
        .height(HomeUiTokens.LIST_ACTION_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(this.vm.favoriteTab === 0 ? Color.White : $r('app.color.text_secondary'))
        .backgroundColor(this.vm.favoriteTab === 0 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.favoriteTab = 0;
        })

      Button('收藏店铺')
        .layoutWeight(1)
        .height(HomeUiTokens.LIST_ACTION_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(this.vm.favoriteTab === 1 ? Color.White : $r('app.color.text_secondary'))
        .backgroundColor(this.vm.favoriteTab === 1 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.favoriteTab = 1;
        })
    }
    .width('100%')
  }
}

@ComponentV2
struct FavoritesContent {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      if (this.vm.favoriteTab === 0) {
        FavoriteCategoriesList({ vm: this.vm })
      } else {
        FavoriteRestaurantsList({ vm: this.vm })
      }
    }
    .width('100%')
  }
}

@ComponentV2
struct FavoriteCategoriesList {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      ForEach(this.vm.getFavoriteCategories(), (category: FoodCategory) => {
        FavoriteCategoryItem({ category: category, vm: this.vm })
      }, (category: FoodCategory) => category.id)

      if (this.vm.getFavoriteCategories().length === 0) {
        EmptyState({ title: '还没有收藏任何品类', description: '在推荐结果页或品类管理中收藏你喜欢的品类' })
      }

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button('管理所有品类')
          .layoutWeight(1)
          .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.currentPage = 'categoryManager';
          })

        Button('新建品类')
          .layoutWeight(1)
          .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.openCategoryForm(undefined, 'favorites');
          })
      }
      .width('100%')
    }
    .width('100%')
  }
}

@ComponentV2
struct FavoriteCategoryItem {
  @Param category: FoodCategory = new FoodCategory();
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
      Text(this.category.name)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))

      Text(`${this.category.mealPeriods.join(' · ')} · ${this.category.foodFeelings.join(' · ')}`)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.text_secondary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .padding(HomeUiTokens.ITEM_GAP_COMPACT)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
    .onClick(() => {
      this.vm.toggleFavoriteCategory(this.category.id);
    })
  }
}

@ComponentV2
struct FavoriteRestaurantsList {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      ForEach(this.vm.getFavoriteNearbyRestaurants(), (item: NearbyRestaurant) => {
        FavoriteRestaurantItem({ item: item, vm: this.vm })
      }, (item: NearbyRestaurant) => item.restaurant.id)

      if (this.vm.getFavoriteNearbyRestaurants().length === 0) {
        EmptyState({ title: '还没有收藏任何店铺', description: '在推荐结果页收藏你喜欢的店铺' })
      }

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button('添加店铺')
          .layoutWeight(1)
          .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.openRestaurantForm();
          })
      }
      .width('100%')
    }
    .width('100%')
  }
}

@ComponentV2
struct FavoriteRestaurantItem {
  @Param item: NearbyRestaurant = new NearbyRestaurant();
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
      Text(this.item.restaurant.name)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Text(`人均 ¥${this.item.restaurant.averagePrice} · ${this.vm.formatDistance(this.item.distanceMeters)}`)
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(HomeUiTokens.ITEM_GAP_COMPACT)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
    .onClick(() => {
      this.vm.openRestaurantForm(this.item.restaurant);
    })
  }
}

import { EmptyState } from '../components/SharedComponents';
