import { HomeUiTokens } from '../components/HomeUiTokens';
import { FoodCategory } from '../models/FoodCategory';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { StatusText, EmptyState } from '../components/SharedComponents';

@ComponentV2
export struct CategoryManagerPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      ForEach(this.vm.getAllCategories(), (category: FoodCategory) => {
        CategoryManagerRow({ category: category, vm: this.vm })
      }, (category: FoodCategory) => category.id)

      if (this.vm.getAllCategories().length === 0) {
        EmptyState({ title: '暂无品类', description: '点击下方按钮添加你的第一个品类' })
      }

      Button('新建品类')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.vm.openCategoryForm(undefined, 'categoryManager');
        })

      // Delete confirmation for used category
      if (this.vm.pendingDeleteCategoryId.length > 0) {
        DeleteCategoryConfirm({
          title: '该品类有关联店铺，删除将解除这些关联，确认删除吗？',
          onConfirm: () => this.vm.deleteCategory(this.vm.pendingDeleteCategoryId),
          onCancel: () => this.vm.pendingDeleteCategoryId = ''
        })
      }

      // Delete confirmation for unused category
      if (this.vm.pendingDeleteUnusedCategoryId.length > 0) {
        DeleteCategoryConfirm({
          title: '确认删除这个品类吗？',
          onConfirm: () => this.vm.deleteCategory(this.vm.pendingDeleteUnusedCategoryId),
          onCancel: () => this.vm.pendingDeleteUnusedCategoryId = ''
        })
        .id('delete_unused')
      }

      StatusText({ notice: this.vm.notice, errorMessage: this.vm.errorMessage })
    }
    .width('100%')
    .padding({ top: HomeUiTokens.ITEM_GAP_COMPACT, bottom: HomeUiTokens.PAGE_PADDING })
  }
}

@ComponentV2
struct CategoryManagerRow {
  @Param category: FoodCategory = new FoodCategory();
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
        Text(this.category.name)
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${this.category.mealPeriods.join(' · ')} · ${this.category.foodFeelings.join(' · ')}`)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      if (this.vm.currentPage === 'restaurantForm') {
        const isSelected: boolean = this.vm.restaurantCategoryIds.indexOf(this.category.id) !== -1;
        Button(isSelected ? '已选' : '选择')
          .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor(isSelected ? Color.White : $r('app.color.brand_primary'))
          .backgroundColor(isSelected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.toggleRestaurantCategory(this.category.id);
          })
      }

      Button(this.vm.isFavoriteCategory(this.category.id) ? '已收藏' : '收藏')
        .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.brand_soft'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.toggleFavoriteCategory(this.category.id);
        })

      Button('编辑')
        .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.openCategoryForm(this.category, 'categoryManager');
        })

      Button('删除')
        .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.danger'))
        .backgroundColor($r('app.color.danger_soft'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.vm.requestDeleteCategory(this.category.id);
        })
    }
    .width('100%')
    .padding(HomeUiTokens.ITEM_GAP_COMPACT)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }
}

@ComponentV2
struct DeleteCategoryConfirm {
  @Param title: string = '';
  @Event onConfirm?: () => void = undefined;
  @Event onCancel?: () => void = undefined;

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Text(this.title)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.warning'))
        .textAlign(TextAlign.Center)

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button('确认删除')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.danger'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            if (this.onConfirm !== undefined) {
              this.onConfirm();
            }
          })

        Button('取消')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            if (this.onCancel !== undefined) {
              this.onCancel();
            }
          })
      }
      .width('100%')
    }
    .width('100%')
    .padding(HomeUiTokens.ITEM_GAP_COMPACT)
    .backgroundColor($r('app.color.warning_soft'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }
}
