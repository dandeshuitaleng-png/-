import { HomeUiTokens } from '../components/HomeUiTokens';
import { FoodCategory, MealPeriod, FoodFeeling, SpiceLevel, BreakfastTrait } from '../models/FoodCategory';
import { Restaurant } from '../models/Restaurant';
import { AppViewModel } from '../viewmodel/AppViewModel';
import { FormSectionTitle, ChipButton, SystemActionNotice, StatusText } from '../components/SharedComponents';

@ComponentV2
export struct RestaurantFormPage {
  @Param vm: AppViewModel = new AppViewModel();

  build() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      // Name
      FormSectionTitle({ title: '店铺名称' })
      TextInput({ placeholder: '输入店铺名称', text: this.vm.restaurantNameInput })
        .width('100%')
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .onChange((value: string) => this.vm.restaurantNameInput = value)

      // Price
      FormSectionTitle({ title: '人均价格 (¥)' })
      TextInput({ placeholder: '输入人均价格', text: this.vm.restaurantPriceInput })
        .width('100%')
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .type(InputType.Number)
        .onChange((value: string) => this.vm.restaurantPriceInput = value)

      // Business hours
      FormSectionTitle({ title: '营业时间' })
      TextInput({ placeholder: '如 "11:00-22:00"', text: this.vm.restaurantHoursInput })
        .width('100%')
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .onChange((value: string) => this.vm.restaurantHoursInput = value)

      // Categories
      FormSectionTitle({ title: '所属品类' })
      if (this.vm.restaurantCategoryIds.length > 0) {
        Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          ForEach(this.vm.restaurantCategoryIds, (categoryId: string) => {
            const category: FoodCategory | undefined = this.getCategoryById(categoryId);
            if (category !== undefined) {
              ChipButton({ label: category.name, selected: true,
                onSelect: () => this.vm.toggleRestaurantCategory(categoryId) })
            }
          }, (id: string) => id)
        }
        .width('100%')
      }

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Text(`${this.vm.restaurantCategoryIds.length} 个品类已选`)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.text_secondary'))
        Button('选择品类')
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.currentPage = 'categoryManager';
          })
        Button('新建品类')
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.vm.openCategoryForm(undefined, 'restaurantForm');
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      // Actions
      StatusText({ notice: this.vm.notice, errorMessage: this.vm.errorMessage })
      SystemActionNotice({ message: this.vm.systemActionMessage })

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button(this.vm.editingRestaurantId.length > 0 ? '保存修改' : '添加店铺')
          .layoutWeight(2)
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .onClick(() => {
            this.vm.saveRestaurantForm();
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

      if (this.vm.editingRestaurantId.length > 0) {
        Button(this.vm.showDeleteRestaurantConfirm ? '确认删除？再次点击确认' : '删除这家店铺')
          .width('100%')
          .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.danger'))
          .backgroundColor($r('app.color.danger_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            if (this.vm.showDeleteRestaurantConfirm) {
              this.vm.deleteEditingRestaurant();
            } else {
              this.vm.showDeleteRestaurantConfirm = true;
            }
          })
      }
    }
    .width('100%')
    .padding({ top: HomeUiTokens.ITEM_GAP_COMPACT, bottom: HomeUiTokens.PAGE_PADDING })
  }

  private getCategoryById(categoryId: string): FoodCategory | undefined {
    return this.vm.getAllCategories().find((c: FoodCategory) => c.id === categoryId);
  }
}
