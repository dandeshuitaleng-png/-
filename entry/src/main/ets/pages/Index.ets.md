# entry/src/main/ets/pages/Index.ets

```typescript
import { common, abilityAccessCtrl, PermissionRequestResult, Want } from '@kit.AbilityKit';
import { LengthMetrics } from '@kit.ArkUI';
import { geoLocationManager } from '@kit.LocationKit';
import { HomeUiTokens } from '../components/HomeUiTokens';
import { ENABLE_DEVICE_LOCATION_ON_STARTUP } from '../config/FeatureFlags';
import { CombinedRestaurantAdapter } from '../data/adapters/CombinedRestaurantAdapter';
import { MockRestaurantAdapter } from '../data/adapters/MockRestaurantAdapter';
import { MOCK_FOOD_CATEGORIES } from '../data/mock/MockFoodCategories';
import { DEFAULT_MOCK_LOCATION, LocationPreset, MANUAL_LOCATION_PRESETS } from '../data/mock/MockLocation';
import { MOCK_RESTAURANTS } from '../data/mock/MockRestaurants';
import {
  BreakfastTrait,
  CategorySourceType,
  FoodCategory,
  FoodFeeling,
  MealPeriod,
  SpiceLevel
} from '../models/FoodCategory';
import {
  CategoryAnswerFilters,
  getQuestionnaireQuestions,
  mergeAnswerFilters,
  QuestionnaireOption,
  QuestionnaireQuestion
} from '../models/Questionnaire';
import {
  BudgetOption,
  RecommendationFilters,
  RecommendationResult,
  RecommendationStatus
} from '../models/Recommendation';
import { NearbyRestaurant } from '../models/RestaurantSearch';
import { Restaurant, RestaurantSourceType } from '../models/Restaurant';
import { GeoPoint } from '../models/Location';
import { AppContentService, DeleteCategoryResult, UserPreferences } from '../services/AppContentService';
import { RecommendationService } from '../services/RecommendationService';
import { RestaurantRepository } from '../services/RestaurantRepository';
import { PreferencesLocalStorageAdapter } from '../storage/PreferencesLocalStorageAdapter';

@Entry
@Component
struct Index {
  @State activeMode: number = 0;
  @State filtersExpanded: boolean = false;
  @State isLoading: boolean = false;
  @State currentPage: string = 'home';
  @State notice: string = '轻松一点，交给今天的灵感。';
  @State errorMessage: string = '';
  @State nearbyRestaurantCount: number = 0;
  @State selectedDistanceMeters: number = 0;
  @State selectedBudget: BudgetOption = BudgetOption.ALL;
  @State selectedSpice: string = 'all';
  @State selectedCategory?: FoodCategory = undefined;
  @State resultRestaurants: NearbyRestaurant[] = [];
  @State revealedCategoryIds: string[] = [];
  @State questionStep: number = 0;
  @State selectedQuestionOptions: QuestionnaireOption[] = [];
  @State flippingCategoryNames: string[] = [];
  @State isQuestionTransitioning: boolean = false;
  @State modeContentOffsetX: number = 0;
  @State favoriteCategoryIds: string[] = [];
  @State favoriteRestaurantIds: string[] = [];
  @State customCategories: FoodCategory[] = [];
  @State customRestaurants: Restaurant[] = [];
  @State favoriteTab: number = 0;
  @State editingRestaurantId: string = '';
  @State restaurantNameInput: string = '';
  @State restaurantPriceInput: string = '';
  @State restaurantHoursInput: string = '';
  @State restaurantCategoryIds: string[] = [];
  @State editingCategoryId: string = '';
  @State categoryNameInput: string = '';
  @State categoryMealPeriods: MealPeriod[] = [];
  @State categoryFoodFeelings: FoodFeeling[] = [];
  @State categorySpiceLevels: SpiceLevel[] = [];
  @State categoryBreakfastTraits: BreakfastTrait[] = [];
  @State returnAfterCategorySave: string = 'categoryManager';
  @State pendingDeleteCategoryId: string = '';
  @State showDeleteRestaurantConfirm: boolean = false;
  @State pendingDeleteUnusedCategoryId: string = '';
  @State favoritesMenuExpanded: boolean = false;
  @State locationReady: boolean = false;
  @State permissionPermanentlyDenied: boolean = false;
  @State locationFailed: boolean = false;
  @State isLocating: boolean = true;
  @State systemActionMessage: string = '';
  @State locationPanelExpanded: boolean = false;
  @State currentLocationLabel: string = '默认位置';
  @State manualLatitudeInput: string = `${DEFAULT_MOCK_LOCATION.latitude}`;
  @State manualLongitudeInput: string = `${DEFAULT_MOCK_LOCATION.longitude}`;

  private contentService?: AppContentService = undefined;
  private currentLocation: GeoPoint = DEFAULT_MOCK_LOCATION;
  private readonly combinedAdapter: CombinedRestaurantAdapter =
    new CombinedRestaurantAdapter(new MockRestaurantAdapter(), () => this.customRestaurants);
  private readonly repository: RestaurantRepository = new RestaurantRepository(this.combinedAdapter);
  private readonly recommendationService: RecommendationService =
    new RecommendationService(this.repository, DEFAULT_MOCK_LOCATION, () => new Date(), () => Math.random(),
      () => MOCK_FOOD_CATEGORIES.concat(this.customCategories));

  aboutToAppear(): void {
    if (ENABLE_DEVICE_LOCATION_ON_STARTUP) {
      this.requestLocationPermission();
    } else {
      this.useMockLocationForDevelopment();
    }
  }

  private async useMockLocationForDevelopment(): Promise<void> {
    await this.ensureContentLoaded();
    const preferences: UserPreferences | undefined = this.contentService?.getUserPreferences();
    const location: GeoPoint = preferences?.manualLocation ?? DEFAULT_MOCK_LOCATION;
    const label: string = preferences?.locationLabel ?? '默认位置';
    this.setActiveLocation(location, label);
  }

  private async requestLocationPermission(): Promise<void> {
    const context: common.UIAbilityContext | undefined =
      this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.isLocating = false;
      this.locationFailed = true;
      return;
    }

    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const grantStatus: abilityAccessCtrl.GrantStatus =
        atManager.checkAccessTokenSync(context.applicationInfo.accessTokenId,
          'ohos.permission.APPROXIMATELY_LOCATION');

      if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        await this.getDeviceLocation();
        return;
      }

      const result: PermissionRequestResult =
        await atManager.requestPermissionsFromUser(context,
          ['ohos.permission.APPROXIMATELY_LOCATION', 'ohos.permission.LOCATION']);

      if (result.authResults !== undefined && result.authResults.length > 0 && result.authResults[0] === 0) {
        await this.getDeviceLocation();
        return;
      }

      // Permission denied
      const permanentlyDenied: boolean = result.dialogShownResults !== undefined &&
        result.dialogShownResults.length > 0 && !result.dialogShownResults[0];

      if (permanentlyDenied) {
        this.permissionPermanentlyDenied = true;
        this.isLocating = false;
      } else {
        this.permissionPermanentlyDenied = true;
        this.isLocating = false;
      }
    } catch (error) {
      this.isLocating = false;
      this.locationFailed = true;
    }
  }

  private async getDeviceLocation(): Promise<void> {
    let locationObtained: boolean = false;
    try {
      const location: geoLocationManager.Location = await geoLocationManager.getCurrentLocation();
      if (location !== undefined && location.latitude !== undefined && location.longitude !== undefined) {
        this.currentLocation = {
          latitude: location.latitude,
          longitude: location.longitude
        };
        locationObtained = true;
      }
    } catch (error) {
      // Location acquisition failed
    }

    if (!locationObtained) {
      this.isLocating = false;
      this.locationFailed = true;
      return;
    }

    await this.ensureContentLoaded();
    this.setActiveLocation(this.currentLocation, '系统定位');
  }

  build() {
    if (this.isLocating) {
      this.locatingContent()
    } else if (this.locationFailed) {
      this.locationFailedContent()
    } else if (!this.locationReady) {
      this.permissionGuideContent()
    } else {
      Scroll() {
        Column({ space: HomeUiTokens.SECTION_GAP }) {
          this.pageHeader()

          if (this.currentPage === 'home') {
            this.homeContent()
          } else if (this.currentPage === 'flip') {
            this.flipContent()
          } else if (this.currentPage === 'favorites') {
            this.favoritesContent()
          } else if (this.currentPage === 'restaurantForm') {
            this.restaurantFormContent()
          } else if (this.currentPage === 'categoryManager') {
            this.categoryManagerContent()
          } else if (this.currentPage === 'categoryForm') {
            this.categoryFormContent()
          } else {
            this.resultContent()
          }
        }
        .width('100%')
        .padding({
          left: HomeUiTokens.PAGE_PADDING,
          right: HomeUiTokens.PAGE_PADDING,
          top: HomeUiTokens.PAGE_TOP_PADDING,
          bottom: HomeUiTokens.PAGE_TOP_PADDING
        })
        .gesture(
          PanGesture({ direction: PanDirection.Horizontal, distance: HomeUiTokens.MODE_SWIPE_GESTURE_DISTANCE })
            .onActionEnd((event: GestureEvent) => {
              this.handleModeSwipe(event.offsetX);
            })
        )
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_background'))
    }
  }

  @Builder
  locatingContent() {
    Column({ space: HomeUiTokens.SECTION_GAP_LARGE }) {
      Text('今天吃什么')
        .fontSize(HomeUiTokens.FONT_DISPLAY)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.plateIllustration()

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

  @Builder
  permissionGuideContent() {
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

      this.manualLocationControls()

      Button('前往系统设置')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.openAppSettings();
        })

      this.systemActionNotice()

      Button('使用默认位置继续')
        .width('100%')
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.continueWithManualLocation(DEFAULT_MOCK_LOCATION, '默认位置');
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

  @Builder
  locationFailedContent() {
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

      this.manualLocationControls()

      this.systemActionNotice()

      Button('重试')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.locationFailed = false;
          this.isLocating = true;
          this.getDeviceLocation();
        })

      Button('使用默认位置继续')
        .width('100%')
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.continueWithManualLocation(DEFAULT_MOCK_LOCATION, '默认位置');
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

  @Builder
  pageHeader() {
    Row() {
      if (this.currentPage !== 'home' && this.currentPage !== 'flip') {
        Button('返回')
          .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.goBack();
          })
      } else {
        Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
          Text('今天吃什么')
            .fontSize(HomeUiTokens.FONT_DISPLAY)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
          Text('不用纠结，先选一种轻松的方式')
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor($r('app.color.text_secondary'))
        }
        .alignItems(HorizontalAlign.Start)
      }

      if (this.currentPage === 'home' || this.currentPage === 'result') {
        Button('收藏')
          .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.currentPage = 'favorites';
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  homeContent() {
    Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Button('直接抽取')
        .layoutWeight(1)
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(this.activeMode === 0 ? Color.White : $r('app.color.text_secondary'))
        .backgroundColor(this.activeMode === 0 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.selectMode(0);
        })

      Button('回答两题')
        .layoutWeight(1)
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(this.activeMode === 1 ? Color.White : $r('app.color.text_secondary'))
        .backgroundColor(this.activeMode === 1 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.selectMode(1);
        })
    }
    .width('100%')

    this.locationPanel()

    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text(this.activeMode === 0 ? '现在就帮你挑一个' : '先回答两题，再揭晓答案')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.plateIllustration()

      Text(this.activeMode === 0 ? '从附近营业中的店铺里，挑一种适合现在的口味。' :
        '午餐、晚餐和早餐会使用不同问题，让选择更贴近此刻的心情。')
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .lineHeight(22)
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)

      if (this.nearbyRestaurantCount > 0) {
        Text(`${this.nearbyRestaurantCount} 家附近店铺已加载`)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      }

      if (this.activeMode === 0) {
        Button(this.getMainButtonText())
          .width('100%')
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_SUBTITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .enabled(!this.isLoading)
          .onClick(() => {
            this.drawDirect();
          })
      } else {
        this.questionnairePanel()
      }
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
    .translate({ x: this.modeContentOffsetX })
    .animation({ duration: HomeUiTokens.MODE_SWITCH_TRANSITION_DURATION, curve: Curve.EaseOut })

    this.filterPanel()

    this.statusText()

    Text('模拟数据仅用于首版验证')
      .width('100%')
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor($r('app.color.text_tertiary'))
      .textAlign(TextAlign.Center)
  }

  @Builder
  questionnairePanel() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text(`第 ${this.questionStep + 1} 题 / 共 2 题`)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.brand_primary'))

      Text(this.getCurrentQuestion().title)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      ForEach(this.getCurrentQuestion().options, (option: QuestionnaireOption) => {
        Button(option.label)
          .width('100%')
          .height(HomeUiTokens.QUESTION_OPTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor(this.isQuestionOptionSelected(option) ? Color.White : $r('app.color.text_secondary'))
          .backgroundColor(this.isQuestionOptionSelected(option) ?
            $r('app.color.brand_primary') : $r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .enabled(!this.isLoading && !this.isQuestionTransitioning)
          .onClick(() => {
            this.selectQuestionOption(option);
          })
      }, (option: QuestionnaireOption) => option.id)

      if (this.questionStep > 0) {
        Button('看看结果')
          .width('100%')
          .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.BUTTON_RADIUS)
          .enabled(this.canSubmitQuestionnaire() && !this.isLoading)
          .onClick(() => {
            this.submitQuestionnaire();
          })

        Button('返回修改上一题')
          .width('100%')
          .height(HomeUiTokens.QUESTION_BACK_BUTTON_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.questionStep = 0;
          })
      }
    }
    .width('100%')
    .padding(HomeUiTokens.QUESTION_PANEL_PADDING)
    .backgroundColor($r('app.color.brand_soft'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  flipContent() {
    Column({ space: HomeUiTokens.SECTION_GAP_LARGE }) {
      Text('正在翻牌...')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach(this.flippingCategoryNames, (name: string, index: number) => {
          Column() {
            Text(name)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .fontSize(index === 1 ? HomeUiTokens.FONT_SUBTITLE : HomeUiTokens.FONT_BODY_SMALL)
              .fontWeight(index === 1 ? FontWeight.Bold : FontWeight.Medium)
              .fontColor(index === 1 ? Color.White : $r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
          }
          .layoutWeight(index === 1 ? 2 : 1)
          .height(index === 1 ? HomeUiTokens.FLIP_ACTIVE_CARD_HEIGHT : HomeUiTokens.FLIP_SIDE_CARD_HEIGHT)
          .padding(HomeUiTokens.ITEM_GAP_COMPACT)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(index === 1 ? $r('app.color.brand_primary') : $r('app.color.card_background'))
          .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
          .animation({ duration: HomeUiTokens.FLIP_CARD_TRANSITION_DURATION, curve: Curve.EaseInOut })
        }, (name: string, index: number) => `${index}-${name}`)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('马上揭晓今天的口味')
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.brand_soft'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  plateIllustration() {
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

  @Builder
  locationPanel() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Row() {
        Column({ space: HomeUiTokens.ITEM_GAP_TINY }) {
          Text('当前位置')
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.text_secondary'))
          Text(this.currentLocationLabel)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
        }
        .alignItems(HorizontalAlign.Start)

        Button(this.locationPanelExpanded ? '收起' : '调整')
          .height(HomeUiTokens.TOUCH_MIN_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.locationPanelExpanded = !this.locationPanelExpanded;
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)

      if (this.locationPanelExpanded) {
        this.manualLocationControls()
      }
    }
    .width('100%')
    .padding(HomeUiTokens.SECTION_GAP)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }

  @Builder
  manualLocationControls() {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        ForEach(MANUAL_LOCATION_PRESETS, (preset: LocationPreset) => {
          Button(preset.label)
            .layoutWeight(1)
            .height(HomeUiTokens.FILTER_BUTTON_HEIGHT)
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor(this.currentLocationLabel === preset.label ? Color.White : $r('app.color.text_secondary'))
            .backgroundColor(this.currentLocationLabel === preset.label ?
              $r('app.color.brand_primary') : $r('app.color.brand_soft'))
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .onClick(() => {
              this.continueWithManualLocation(preset.location, preset.label);
            })
        }, (preset: LocationPreset) => preset.id)
      }
      .width('100%')

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        TextInput({ placeholder: '纬度', text: this.manualLatitudeInput })
          .layoutWeight(1)
          .height(HomeUiTokens.FORM_FIELD_HEIGHT)
          .onChange((value: string) => this.manualLatitudeInput = value)
        TextInput({ placeholder: '经度', text: this.manualLongitudeInput })
          .layoutWeight(1)
          .height(HomeUiTokens.FORM_FIELD_HEIGHT)
          .onChange((value: string) => this.manualLongitudeInput = value)
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
          this.applyManualLocationInput();
        })
    }
    .width('100%')
  }

  @Builder
  filterPanel() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Row() {
        Text('筛选条件')
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(this.filtersExpanded ? '收起' : '展开')
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
      .onClick(() => {
        this.filtersExpanded = !this.filtersExpanded;
      })

      if (this.filtersExpanded) {
        Column({ space: HomeUiTokens.ITEM_GAP }) {
          this.filterTitle('距离')
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            this.filterButton('不限', this.selectedDistanceMeters === 0, () => this.selectDistanceFilter(0))
            this.filterButton('500 米', this.selectedDistanceMeters === 500, () => this.selectDistanceFilter(500))
            this.filterButton('1 公里', this.selectedDistanceMeters === 1000, () => this.selectDistanceFilter(1000))
            this.filterButton('3 公里', this.selectedDistanceMeters === 3000, () => this.selectDistanceFilter(3000))
          }
          .width('100%')

          this.filterTitle('人均预算')
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            this.filterButton('不限', this.selectedBudget === BudgetOption.ALL,
              () => this.selectBudgetFilter(BudgetOption.ALL))
            this.filterButton('30 内', this.selectedBudget === BudgetOption.UNDER_30,
              () => this.selectBudgetFilter(BudgetOption.UNDER_30))
            this.filterButton('30-60', this.selectedBudget === BudgetOption.FROM_30_TO_60,
              () => this.selectBudgetFilter(BudgetOption.FROM_30_TO_60))
            this.filterButton('60-100', this.selectedBudget === BudgetOption.FROM_60_TO_100,
              () => this.selectBudgetFilter(BudgetOption.FROM_60_TO_100))
          }
          .width('100%')

          this.filterTitle('辣度')
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            this.filterButton('不限', this.selectedSpice === 'all', () => this.selectSpiceFilter('all'))
            this.filterButton('不辣', this.selectedSpice === SpiceLevel.NOT_SPICY,
              () => this.selectSpiceFilter(SpiceLevel.NOT_SPICY))
            this.filterButton('微辣', this.selectedSpice === SpiceLevel.MILD,
              () => this.selectSpiceFilter(SpiceLevel.MILD))
            this.filterButton('能吃辣', this.selectedSpice === SpiceLevel.SPICY,
              () => this.selectSpiceFilter(SpiceLevel.SPICY))
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

  @Builder
  filterTitle(title: string) {
    Text(title)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_secondary'))
  }

  @Builder
  filterButton(label: string, selected: boolean, onSelect: () => void) {
    Button(label)
      .layoutWeight(1)
      .height(HomeUiTokens.FILTER_BUTTON_HEIGHT)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor(selected ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(selected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
      .borderRadius(HomeUiTokens.PILL_RADIUS)
      .onClick(onSelect)
  }

  @Builder
  resultContent() {
    if (this.selectedCategory !== undefined) {
      Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Text('今天吃')
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontColor($r('app.color.text_secondary'))
        Text(this.selectedCategory.name)
          .fontSize(HomeUiTokens.FONT_RESULT)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.brand_primary'))
        Button(this.isFavoriteCategory(this.selectedCategory.id) ? '取消收藏品类' : '收藏品类')
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.toggleFavoriteCategory(this.selectedCategory?.id ?? '');
          })
      }
      .width('100%')
      .padding({
        top: HomeUiTokens.SECTION_GAP_LARGE,
        bottom: HomeUiTokens.SECTION_GAP_LARGE
      })
      .backgroundColor($r('app.color.card_background'))
      .borderRadius(HomeUiTokens.CARD_RADIUS)

      Text('附近可以去这些店')
        .width('100%')
        .fontSize(HomeUiTokens.FONT_SUBTITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      ForEach(this.resultRestaurants, (item: NearbyRestaurant) => {
        this.restaurantCard(item)
      }, (item: NearbyRestaurant) => item.restaurant.id)

      Button(this.isLoading ? '正在重新挑选...' : '再随机一次')
        .width('100%')
        .height(HomeUiTokens.RESULT_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .enabled(!this.isLoading)
        .onClick(() => {
          this.drawAgain();
        })

      this.statusText()

      this.systemActionNotice()
    }
  }

  @Builder
  restaurantCard(item: NearbyRestaurant) {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Row() {
        Text(item.restaurant.name)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .fontSize(HomeUiTokens.FONT_BODY)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
        Text(item.restaurant.sourceType === RestaurantSourceType.MOCK ? '模拟数据' : '自定义')
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)

      Text(`${this.formatDistance(item.distanceMeters)} · 人均 ${item.restaurant.averagePrice} 元 · ` +
        `${this.formatRating(item.restaurant.rating)} · 营业中`)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.text_secondary'))

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        Button(this.isFavoriteRestaurant(item.restaurant.id) ? '取消收藏' : '收藏')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.toggleFavoriteRestaurant(item.restaurant.id);
          })
        Button('导航')
          .layoutWeight(1)
          .height(HomeUiTokens.LIST_ACTION_HEIGHT)
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.brand_primary'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.openMapNavigation(item.restaurant.name, item.restaurant.latitude, item.restaurant.longitude);
          })
        if (item.restaurant.sourceType === RestaurantSourceType.CUSTOM) {
          Button('编辑')
            .layoutWeight(1)
            .height(HomeUiTokens.LIST_ACTION_HEIGHT)
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.brand_primary'))
            .backgroundColor($r('app.color.brand_soft'))
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .onClick(() => {
              this.openRestaurantForm(item.restaurant);
            })
        }
      }
      .width('100%')
    }
    .width('100%')
    .padding(HomeUiTokens.SECTION_GAP)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }

  @Builder
  favoritesContent() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Row() {
        Text('我的收藏')
          .fontSize(HomeUiTokens.FONT_TITLE)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
        Blank()
        Button('更多')
          .height(HomeUiTokens.MENU_ITEM_HEIGHT)
          .fontSize(HomeUiTokens.FONT_BODY_SMALL)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .onClick(() => {
            this.favoritesMenuExpanded = !this.favoritesMenuExpanded;
          })
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      if (this.favoritesMenuExpanded) {
        Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          Button('添加店铺')
            .width('100%')
            .height(HomeUiTokens.MENU_ITEM_HEIGHT)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
            .onClick(() => {
              this.favoritesMenuExpanded = false;
              this.openRestaurantForm();
            })
          Button('管理自定义品类')
            .width('100%')
            .height(HomeUiTokens.MENU_ITEM_HEIGHT)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.card_background'))
            .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
            .onClick(() => {
              this.favoritesMenuExpanded = false;
              this.currentPage = 'categoryManager';
            })
        }
        .width('100%')
        .padding(HomeUiTokens.ITEM_GAP_COMPACT)
        .backgroundColor($r('app.color.card_background'))
        .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
        .border({
          width: 1,
          color: $r('app.color.border_soft')
        })
        .alignItems(HorizontalAlign.Start)
      }

      Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
        this.filterButton('收藏品类', this.favoriteTab === 0, () => this.favoriteTab = 0)
        this.filterButton('收藏店铺', this.favoriteTab === 1, () => this.favoriteTab = 1)
      }
      .width('100%')

      if (this.favoriteTab === 0) {
        if (this.getFavoriteCategories().length === 0) {
          this.emptyState('还没有收藏品类', '看到喜欢的品类时，点一下收藏就会出现在这里。')
        } else {
          ForEach(this.getFavoriteCategories(), (category: FoodCategory) => {
            this.favoriteCategoryCard(category)
          }, (category: FoodCategory) => category.id)
        }
      } else {
        if (this.getFavoriteNearbyRestaurants().length === 0) {
          this.emptyState('还没有收藏店铺', '看到喜欢的店铺时，点一下收藏就会出现在这里。')
        } else {
          ForEach(this.getFavoriteNearbyRestaurants(), (item: NearbyRestaurant) => {
            this.restaurantCard(item)
          }, (item: NearbyRestaurant) => item.restaurant.id)
        }
      }

      this.systemActionNotice()
    }
    .width('100%')
  }

  @Builder
  favoriteCategoryCard(category: FoodCategory) {
    Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Text(category.name)
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
      if (category.sourceType === CategorySourceType.CUSTOM) {
        Text('自定义')
          .fontSize(HomeUiTokens.FONT_CAPTION)
          .fontColor($r('app.color.brand_primary'))
          .backgroundColor($r('app.color.brand_soft'))
          .borderRadius(HomeUiTokens.PILL_RADIUS)
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
      }
      Button('取消收藏')
        .height(HomeUiTokens.LIST_ACTION_HEIGHT)
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.brand_soft'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.toggleFavoriteCategory(category.id);
        })
    }
    .width('100%')
    .padding(HomeUiTokens.SECTION_GAP)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
  }

  @Builder
  emptyState(title: string, description?: string) {
    Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
      Text(title)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_secondary'))
      if (description !== undefined) {
        Text(description)
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

  @Builder
  restaurantFormContent() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text(this.editingRestaurantId.length === 0 ? '添加店铺' : '编辑店铺')
        .width('100%')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.formSectionTitle('基本信息')
      TextInput({ placeholder: '店铺或路边摊名称', text: this.restaurantNameInput })
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .onChange((value: string) => this.restaurantNameInput = value)
      TextInput({ placeholder: '人均价格', text: this.restaurantPriceInput })
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .type(InputType.Number)
        .onChange((value: string) => this.restaurantPriceInput = value)
      TextInput({ placeholder: '营业时间（选填）', text: this.restaurantHoursInput })
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .onChange((value: string) => this.restaurantHoursInput = value)

      this.formSectionTitle('位置')
      Text('使用当前位置')
        .width('100%')
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.text_secondary'))

      this.formSectionTitle('关联品类')
      Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT), cross: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT) } }) {
        ForEach(this.getAllCategories(), (category: FoodCategory) => {
          this.chipButton(category.name, this.restaurantCategoryIds.indexOf(category.id) !== -1,
            () => this.toggleRestaurantCategory(category.id))
        }, (category: FoodCategory) => category.id)
      }
      .width('100%')

      Button('当场创建新品类')
        .width('100%')
        .height(HomeUiTokens.LIST_ACTION_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor($r('app.color.brand_primary'))
        .backgroundColor($r('app.color.brand_soft'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.openCategoryForm(undefined, 'restaurantForm');
        })

      Button('保存店铺')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.saveRestaurantForm();
        })

      if (this.editingRestaurantId.length > 0) {
        if (this.showDeleteRestaurantConfirm) {
          Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            Text('删除这家店铺？')
              .fontSize(HomeUiTokens.FONT_BODY)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
            Text('删除后将无法恢复，也会从收藏中移除。')
              .fontSize(HomeUiTokens.FONT_CAPTION)
              .fontColor($r('app.color.text_secondary'))
            Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
              Button('取消')
                .layoutWeight(1)
                .height(HomeUiTokens.LIST_ACTION_HEIGHT)
                .fontSize(HomeUiTokens.FONT_BODY_SMALL)
                .fontColor($r('app.color.text_primary'))
                .backgroundColor($r('app.color.brand_soft'))
                .borderRadius(HomeUiTokens.PILL_RADIUS)
                .onClick(() => {
                  this.showDeleteRestaurantConfirm = false;
                })
              Button('确认删除')
                .layoutWeight(1)
                .height(HomeUiTokens.LIST_ACTION_HEIGHT)
                .fontSize(HomeUiTokens.FONT_BODY_SMALL)
                .fontColor(Color.White)
                .backgroundColor($r('app.color.danger'))
                .borderRadius(HomeUiTokens.PILL_RADIUS)
                .onClick(() => {
                  this.showDeleteRestaurantConfirm = false;
                  this.deleteEditingRestaurant();
                })
            }
            .width('100%')
          }
          .width('100%')
          .padding(HomeUiTokens.ITEM_GAP)
          .backgroundColor($r('app.color.danger_soft'))
          .borderRadius(HomeUiTokens.DIALOG_RADIUS)
        } else {
          Button('删除店铺')
            .width('100%')
            .height(HomeUiTokens.LIST_ACTION_HEIGHT)
            .fontSize(HomeUiTokens.FONT_BODY_SMALL)
            .fontColor($r('app.color.danger'))
            .backgroundColor($r('app.color.danger_soft'))
            .borderRadius(HomeUiTokens.PILL_RADIUS)
            .onClick(() => {
              this.showDeleteRestaurantConfirm = true;
            })
        }
      }
      this.statusText()
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
  }

  @Builder
  categoryManagerContent() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text('管理自定义品类')
        .width('100%')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Button('添加自定义品类')
        .width('100%')
        .height(HomeUiTokens.SECONDARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY_SMALL)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.PILL_RADIUS)
        .onClick(() => {
          this.openCategoryForm();
        })
      if (this.customCategories.length === 0) {
        this.emptyState('还没有自定义品类', '在这里添加系统没有收录的餐饮类型。')
      } else {
        ForEach(this.customCategories, (category: FoodCategory) => {
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            Text(category.name)
              .layoutWeight(1)
              .fontSize(HomeUiTokens.FONT_BODY)
              .fontColor($r('app.color.text_primary'))
            Button('编辑')
              .height(HomeUiTokens.LIST_ACTION_HEIGHT)
              .fontSize(HomeUiTokens.FONT_CAPTION)
              .fontColor($r('app.color.brand_primary'))
              .backgroundColor($r('app.color.brand_soft'))
              .borderRadius(HomeUiTokens.PILL_RADIUS)
              .onClick(() => this.openCategoryForm(category))
            Button('删除')
              .height(HomeUiTokens.LIST_ACTION_HEIGHT)
              .fontSize(HomeUiTokens.FONT_CAPTION)
              .fontColor($r('app.color.danger'))
              .backgroundColor($r('app.color.danger_soft'))
              .borderRadius(HomeUiTokens.PILL_RADIUS)
              .onClick(() => this.requestDeleteCategory(category.id))
          }
          .width('100%')
          .padding(HomeUiTokens.SECTION_GAP)
          .backgroundColor($r('app.color.card_background'))
          .borderRadius(HomeUiTokens.CARD_RADIUS_SMALL)
        }, (category: FoodCategory) => category.id)
      }
      Text('删除被使用中的品类时，只会解除关联，不会删除店铺。')
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.text_secondary'))
      this.statusText()

      if (this.pendingDeleteUnusedCategoryId.length > 0) {
        Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          Text('删除这个品类？')
            .fontSize(HomeUiTokens.FONT_BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('删除后将无法恢复。')
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.text_secondary'))
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            Button('取消')
              .layoutWeight(1)
              .height(HomeUiTokens.LIST_ACTION_HEIGHT)
              .fontSize(HomeUiTokens.FONT_BODY_SMALL)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.brand_soft'))
              .borderRadius(HomeUiTokens.PILL_RADIUS)
              .onClick(() => this.pendingDeleteUnusedCategoryId = '')
            Button('确认删除')
              .layoutWeight(1)
              .height(HomeUiTokens.LIST_ACTION_HEIGHT)
              .fontSize(HomeUiTokens.FONT_BODY_SMALL)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.danger'))
              .borderRadius(HomeUiTokens.PILL_RADIUS)
              .onClick(() => {
                const categoryId: string = this.pendingDeleteUnusedCategoryId;
                this.pendingDeleteUnusedCategoryId = '';
                this.deleteCategory(categoryId);
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(HomeUiTokens.ITEM_GAP)
        .backgroundColor($r('app.color.danger_soft'))
        .borderRadius(HomeUiTokens.DIALOG_RADIUS)
      }

      if (this.pendingDeleteCategoryId.length > 0) {
        Column({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
          Text('这个品类仍被店铺使用')
            .fontSize(HomeUiTokens.FONT_BODY)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
          Text('删除后只会解除关联，不会删除店铺。若店铺失去全部品类，需要重新为它选择品类。')
            .fontSize(HomeUiTokens.FONT_CAPTION)
            .fontColor($r('app.color.text_secondary'))
          Row({ space: HomeUiTokens.ITEM_GAP_COMPACT }) {
            Button('取消')
              .layoutWeight(1)
              .height(HomeUiTokens.LIST_ACTION_HEIGHT)
              .fontSize(HomeUiTokens.FONT_BODY_SMALL)
              .fontColor($r('app.color.text_primary'))
              .backgroundColor($r('app.color.brand_soft'))
              .borderRadius(HomeUiTokens.PILL_RADIUS)
              .onClick(() => this.pendingDeleteCategoryId = '')
            Button('仍然删除')
              .layoutWeight(1)
              .height(HomeUiTokens.LIST_ACTION_HEIGHT)
              .fontSize(HomeUiTokens.FONT_BODY_SMALL)
              .fontColor(Color.White)
              .backgroundColor($r('app.color.danger'))
              .borderRadius(HomeUiTokens.PILL_RADIUS)
              .onClick(() => {
                this.deleteCategory(this.pendingDeleteCategoryId);
              })
          }
          .width('100%')
        }
        .width('100%')
        .padding(HomeUiTokens.ITEM_GAP)
        .backgroundColor($r('app.color.danger_soft'))
        .borderRadius(HomeUiTokens.DIALOG_RADIUS)
      }
    }
    .width('100%')
  }

  @Builder
  categoryFormContent() {
    Column({ space: HomeUiTokens.ITEM_GAP }) {
      Text(this.editingCategoryId.length === 0 ? '添加品类' : '编辑品类')
        .width('100%')
        .fontSize(HomeUiTokens.FONT_TITLE)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      this.formSectionTitle('品类名称')
      TextInput({ placeholder: '品类名称', text: this.categoryNameInput })
        .height(HomeUiTokens.FORM_FIELD_HEIGHT)
        .onChange((value: string) => this.categoryNameInput = value)

      this.formSectionTitle('适用餐段')
      Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT), cross: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT) } }) {
        this.chipButton('早餐', this.categoryMealPeriods.indexOf(MealPeriod.BREAKFAST) !== -1,
          () => this.toggleMealPeriod(MealPeriod.BREAKFAST))
        this.chipButton('午餐', this.categoryMealPeriods.indexOf(MealPeriod.LUNCH) !== -1,
          () => this.toggleMealPeriod(MealPeriod.LUNCH))
        this.chipButton('晚餐', this.categoryMealPeriods.indexOf(MealPeriod.DINNER) !== -1,
          () => this.toggleMealPeriod(MealPeriod.DINNER))
      }
      .width('100%')

      this.formSectionTitle('食物感受')
      Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT), cross: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT) } }) {
        this.chipButton('热乎', this.categoryFoodFeelings.indexOf(FoodFeeling.WARM) !== -1,
          () => this.toggleFoodFeeling(FoodFeeling.WARM))
        this.chipButton('清爽', this.categoryFoodFeelings.indexOf(FoodFeeling.REFRESHING) !== -1,
          () => this.toggleFoodFeeling(FoodFeeling.REFRESHING))
      }
      .width('100%')

      this.formSectionTitle('辣度')
      Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT), cross: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT) } }) {
        this.chipButton('不辣', this.categorySpiceLevels.indexOf(SpiceLevel.NOT_SPICY) !== -1,
          () => this.toggleCategorySpice(SpiceLevel.NOT_SPICY))
        this.chipButton('微辣', this.categorySpiceLevels.indexOf(SpiceLevel.MILD) !== -1,
          () => this.toggleCategorySpice(SpiceLevel.MILD))
        this.chipButton('能吃辣', this.categorySpiceLevels.indexOf(SpiceLevel.SPICY) !== -1,
          () => this.toggleCategorySpice(SpiceLevel.SPICY))
      }
      .width('100%')

      this.formSectionTitle('早餐特征（选填）')
      Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT), cross: LengthMetrics.vp(HomeUiTokens.ITEM_GAP_COMPACT) } }) {
        this.chipButton('方便带走', this.categoryBreakfastTraits.indexOf(BreakfastTrait.TAKEAWAY) !== -1,
          () => this.toggleBreakfastTrait(BreakfastTrait.TAKEAWAY))
        this.chipButton('更管饱', this.categoryBreakfastTraits.indexOf(BreakfastTrait.FILLING) !== -1,
          () => this.toggleBreakfastTrait(BreakfastTrait.FILLING))
      }
      .width('100%')

      Button('保存品类')
        .width('100%')
        .height(HomeUiTokens.PRIMARY_BUTTON_HEIGHT)
        .fontSize(HomeUiTokens.FONT_BODY)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.brand_primary'))
        .borderRadius(HomeUiTokens.BUTTON_RADIUS)
        .onClick(() => {
          this.saveCategoryForm();
        })
      this.statusText()
    }
    .width('100%')
    .padding(HomeUiTokens.CARD_PADDING)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(HomeUiTokens.CARD_RADIUS)
  }

  @Builder
  formSectionTitle(title: string) {
    Text(title)
      .width('100%')
      .fontSize(HomeUiTokens.FONT_BODY_SMALL)
      .fontWeight(FontWeight.Medium)
      .fontColor($r('app.color.text_primary'))
  }

  @Builder
  choiceButton(label: string, selected: boolean, onSelect: () => void) {
    Button(label)
      .width('100%')
      .height(HomeUiTokens.FILTER_BUTTON_HEIGHT)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor(selected ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(selected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
      .borderRadius(HomeUiTokens.PILL_RADIUS)
      .onClick(onSelect)
  }

  @Builder
  chipButton(label: string, selected: boolean, onSelect: () => void) {
    Button(label)
      .height(HomeUiTokens.CHOICE_CHIP_HEIGHT)
      .fontSize(HomeUiTokens.FONT_CAPTION)
      .fontColor(selected ? Color.White : $r('app.color.text_secondary'))
      .backgroundColor(selected ? $r('app.color.brand_primary') : $r('app.color.brand_soft'))
      .borderRadius(HomeUiTokens.PILL_RADIUS)
      .padding({ left: 12, right: 12 })
      .onClick(onSelect)
  }

  @Builder
  statusText() {
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

  @Builder
  systemActionNotice() {
    if (this.systemActionMessage.length > 0) {
      Text(this.systemActionMessage)
        .width('100%')
        .fontSize(HomeUiTokens.FONT_CAPTION)
        .fontColor($r('app.color.danger'))
        .backgroundColor($r('app.color.danger_soft'))
        .borderRadius(HomeUiTokens.ITEM_GAP_COMPACT)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
        .textAlign(TextAlign.Center)
    }
  }

  private selectDistanceFilter(distanceMeters: number): void {
    this.selectedDistanceMeters = distanceMeters;
    this.persistUserPreferences();
  }

  private selectBudgetFilter(budget: BudgetOption): void {
    this.selectedBudget = budget;
    this.persistUserPreferences();
  }

  private selectSpiceFilter(spice: string): void {
    this.selectedSpice = spice;
    this.persistUserPreferences();
  }

  private setActiveLocation(location: GeoPoint, label: string): void {
    this.currentLocation = {
      latitude: location.latitude,
      longitude: location.longitude
    };
    this.currentLocationLabel = label;
    this.manualLatitudeInput = `${location.latitude}`;
    this.manualLongitudeInput = `${location.longitude}`;
    this.recommendationService.setLocation(this.currentLocation);
    this.permissionPermanentlyDenied = false;
    this.locationFailed = false;
    this.locationReady = true;
    this.isLocating = false;
  }

  private async continueWithManualLocation(location: GeoPoint, label: string): Promise<void> {
    await this.ensureContentLoaded();
    this.setActiveLocation(location, label);
    this.locationPanelExpanded = false;
    this.notice = `已切换到${label}`;
    await this.persistUserPreferences();
  }

  private async applyManualLocationInput(): Promise<void> {
    const latitude: number = Number(this.manualLatitudeInput);
    const longitude: number = Number(this.manualLongitudeInput);
    if (!this.isValidCoordinate(latitude, longitude)) {
      this.notice = '请输入有效的经纬度';
      this.systemActionMessage = '请输入有效的经纬度';
      return;
    }
    this.systemActionMessage = '';
    await this.continueWithManualLocation({
      latitude: latitude,
      longitude: longitude
    }, '手动位置');
  }

  private isValidCoordinate(latitude: number, longitude: number): boolean {
    return latitude === latitude && longitude === longitude &&
      latitude >= -90 && latitude <= 90 &&
      longitude >= -180 && longitude <= 180;
  }

  private async persistUserPreferences(): Promise<void> {
    if (this.contentService === undefined) {
      return;
    }
    await this.contentService.saveUserPreferences({
      selectedDistanceMeters: this.selectedDistanceMeters,
      selectedBudget: this.selectedBudget,
      selectedSpice: this.selectedSpice,
      locationLabel: this.currentLocationLabel,
      manualLocation: {
        latitude: this.currentLocation.latitude,
        longitude: this.currentLocation.longitude
      }
    });
  }

  private async drawDirect(answerFilters?: CategoryAnswerFilters): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';
    this.notice = '正在看看附近有什么好吃的...';
    const filters: RecommendationFilters = {
      distanceLimitMeters: this.selectedDistanceMeters === 0 ? undefined : this.selectedDistanceMeters,
      budgetOption: this.selectedBudget,
      spiceLevel: this.getSelectedSpice()
    };

    try {
      const result: RecommendationResult =
        await this.recommendationService.drawDirect(filters, this.revealedCategoryIds, answerFilters, {
          favoriteCategoryIds: this.favoriteCategoryIds,
          favoriteRestaurantIds: this.favoriteRestaurantIds
        });
      this.nearbyRestaurantCount = result.nearbyRestaurantCount;

      if (result.status !== RecommendationStatus.SUCCESS || result.category === undefined) {
        this.errorMessage = result.errorMessage;
        return;
      }

      await this.showFlipAnimation(result, result.category);
    } catch (error) {
      this.errorMessage = '附近店铺加载失败，请稍后重试。';
    } finally {
      this.isLoading = false;
    }
  }

  private selectMode(mode: number): void {
    if (this.activeMode === mode || this.isLoading) {
      return;
    }
    this.modeContentOffsetX = mode > this.activeMode ?
      HomeUiTokens.MODE_SWITCH_TRANSLATE_DISTANCE : -HomeUiTokens.MODE_SWITCH_TRANSLATE_DISTANCE;
    this.activeMode = mode;
    this.questionStep = 0;
    this.selectedQuestionOptions = [];
    this.notice = mode === 0 ? '直接抽取模式：点击主按钮即可开始。' : '回答两题，让结果更贴近现在的心情。';
    this.getUIContext().animateTo({ duration: HomeUiTokens.MODE_SWITCH_TRANSITION_DURATION, curve: Curve.EaseOut }, () => {
      this.modeContentOffsetX = 0;
    });
  }

  private handleModeSwipe(offsetX: number): void {
    if (this.currentPage !== 'home' || this.isLoading || Math.abs(offsetX) < HomeUiTokens.MODE_SWIPE_THRESHOLD) {
      return;
    }
    this.selectMode(offsetX < 0 ? 1 : 0);
  }

  private getCurrentQuestion(): QuestionnaireQuestion {
    return getQuestionnaireQuestions(this.recommendationService.getCurrentMealPeriod())[this.questionStep];
  }

  private isQuestionOptionSelected(option: QuestionnaireOption): boolean {
    return this.selectedQuestionOptions.length > this.questionStep &&
      this.selectedQuestionOptions[this.questionStep].id === option.id;
  }

  private async selectQuestionOption(option: QuestionnaireOption): Promise<void> {
    if (this.isQuestionTransitioning) {
      return;
    }
    const nextOptions: QuestionnaireOption[] = this.selectedQuestionOptions.slice(0, this.questionStep);
    nextOptions.push(option);
    this.selectedQuestionOptions = nextOptions;
    if (this.questionStep === 0) {
      this.isQuestionTransitioning = true;
      await this.delay(HomeUiTokens.QUESTION_SELECTION_FEEDBACK_DURATION);
      this.questionStep = 1;
      this.isQuestionTransitioning = false;
      return;
    }
  }

  private canSubmitQuestionnaire(): boolean {
    return this.questionStep === 1 && this.selectedQuestionOptions.length === 2;
  }

  private submitQuestionnaire(): void {
    if (!this.canSubmitQuestionnaire()) {
      return;
    }
    this.drawDirect(mergeAnswerFilters(this.selectedQuestionOptions));
  }

  private drawAgain(): void {
    const answerFilters: CategoryAnswerFilters | undefined = this.activeMode === 1 ?
      mergeAnswerFilters(this.selectedQuestionOptions) : undefined;
    this.drawDirect(answerFilters);
  }

  private async showFlipAnimation(result: RecommendationResult, category: FoodCategory): Promise<void> {
    this.currentPage = 'flip';
    for (let index: number = 0; index < HomeUiTokens.FLIP_STEP_DURATIONS.length - 1; index++) {
      this.flippingCategoryNames = this.getFlipCategoryNames(index);
      await this.delay(HomeUiTokens.FLIP_STEP_DURATIONS[index]);
    }
    const finalNames: string[] = this.getFlipCategoryNames(HomeUiTokens.FLIP_STEP_DURATIONS.length - 1);
    finalNames[1] = category.name;
    this.flippingCategoryNames = finalNames;
    await this.delay(HomeUiTokens.FLIP_STEP_DURATIONS[HomeUiTokens.FLIP_STEP_DURATIONS.length - 1]);

    this.selectedCategory = category;
    this.resultRestaurants = result.restaurants;
    this.currentPage = 'result';
    this.notice = result.notice.length > 0 ? result.notice : '已经为你挑好了。';
    this.revealedCategoryIds = result.cycleReset ? [category.id] : this.revealedCategoryIds.concat(category.id);
  }

  private getFlipCategoryNames(offset: number): string[] {
    const categories: FoodCategory[] = this.getAllCategories();
    const count: number = categories.length;
    return [
      categories[offset % count].name,
      categories[(offset + 1) % count].name,
      categories[(offset + 2) % count].name
    ];
  }

  private delay(milliseconds: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, milliseconds);
    });
  }

  private openAppSettings(): void {
    this.systemActionMessage = '';
    const context: common.UIAbilityContext | undefined =
      this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.systemActionMessage = '无法打开系统设置，请手动前往。';
      return;
    }
    const want: Want = {
      bundleName: 'com.huawei.hmos.settings',
      abilityName: 'com.huawei.hmos.settings.MainAbility',
      uri: 'application_info_entry',
      parameters: {
        pushParams: context.abilityInfo.bundleName
      }
    };
    context.startAbility(want).then(() => {
      // Settings opened
    }).catch(() => {
      this.systemActionMessage = '无法打开系统设置，请手动前往。';
    });
  }

  private openMapNavigation(name: string, latitude: number, longitude: number): void {
    this.systemActionMessage = '';
    const context: common.UIAbilityContext | undefined =
      this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.systemActionMessage = '无法打开地图应用，请稍后重试。';
      return;
    }
    const want: Want = {
      action: 'ohos.want.action.viewData',
      uri: `geo:${latitude},${longitude}?q=${encodeURI(name)}`
    };
    context.startAbility(want).then(() => {
      // Navigation started
    }).catch(() => {
      this.systemActionMessage = '未找到可用的地图应用。';
    });
  }

  private async loadPersistedContent(): Promise<void> {
    const context: common.UIAbilityContext | undefined =
      this.getUIContext().getHostContext() as common.UIAbilityContext | undefined;
    if (context === undefined) {
      this.errorMessage = '本地内容加载失败，请稍后重试';
      return;
    }
    this.contentService = new AppContentService(new PreferencesLocalStorageAdapter(context));
    await this.contentService.load();
    this.refreshContentState();
    this.restoreUserPreferences();
  }

  private async ensureContentLoaded(): Promise<void> {
    if (this.contentService !== undefined) {
      return;
    }
    await this.loadPersistedContent();
  }

  private restoreUserPreferences(): void {
    if (this.contentService === undefined) {
      return;
    }
    const preferences: UserPreferences = this.contentService.getUserPreferences();
    this.selectedDistanceMeters = preferences.selectedDistanceMeters;
    this.selectedBudget = preferences.selectedBudget;
    this.selectedSpice = preferences.selectedSpice;
    if (preferences.manualLocation !== undefined) {
      this.currentLocationLabel = preferences.locationLabel;
      this.manualLatitudeInput = `${preferences.manualLocation.latitude}`;
      this.manualLongitudeInput = `${preferences.manualLocation.longitude}`;
    }
  }

  private refreshContentState(): void {
    if (this.contentService === undefined) {
      return;
    }
    this.favoriteCategoryIds = this.contentService.getFavoriteCategoryIds();
    this.favoriteRestaurantIds = this.contentService.getFavoriteRestaurantIds();
    this.customCategories = this.contentService.getCustomCategories();
    this.customRestaurants = this.contentService.getCustomRestaurants();
  }

  private getAllCategories(): FoodCategory[] {
    return MOCK_FOOD_CATEGORIES.concat(this.customCategories);
  }

  private getAllRestaurants(): Restaurant[] {
    return MOCK_RESTAURANTS.concat(this.customRestaurants);
  }

  private getFavoriteCategories(): FoodCategory[] {
    return this.getAllCategories()
      .filter((category: FoodCategory) => this.favoriteCategoryIds.indexOf(category.id) !== -1);
  }

  private getFavoriteNearbyRestaurants(): NearbyRestaurant[] {
    return this.getAllRestaurants()
      .filter((restaurant: Restaurant) => this.favoriteRestaurantIds.indexOf(restaurant.id) !== -1)
      .map((restaurant: Restaurant): NearbyRestaurant => {
        return {
          restaurant: restaurant,
          distanceMeters: this.calculateDistanceMeters(restaurant.latitude, restaurant.longitude)
        };
      })
      .sort((left: NearbyRestaurant, right: NearbyRestaurant) => left.distanceMeters - right.distanceMeters);
  }

  private isFavoriteCategory(categoryId: string): boolean {
    return this.favoriteCategoryIds.indexOf(categoryId) !== -1;
  }

  private isFavoriteRestaurant(restaurantId: string): boolean {
    return this.favoriteRestaurantIds.indexOf(restaurantId) !== -1;
  }

  private async toggleFavoriteCategory(categoryId: string): Promise<void> {
    if (this.contentService === undefined || categoryId.length === 0) {
      return;
    }
    await this.contentService.toggleFavoriteCategory(categoryId);
    this.refreshContentState();
    this.notice = this.isFavoriteCategory(categoryId) ? '已收藏品类' : '已取消收藏品类';
  }

  private async toggleFavoriteRestaurant(restaurantId: string): Promise<void> {
    if (this.contentService === undefined) {
      return;
    }
    await this.contentService.toggleFavoriteRestaurant(restaurantId);
    this.refreshContentState();
    this.notice = this.isFavoriteRestaurant(restaurantId) ? '已收藏店铺' : '已取消收藏店铺';
  }

  private openRestaurantForm(restaurant?: Restaurant): void {
    this.editingRestaurantId = restaurant?.id ?? '';
    this.restaurantNameInput = restaurant?.name ?? '';
    this.restaurantPriceInput = restaurant === undefined ? '' : `${restaurant.averagePrice}`;
    this.restaurantHoursInput = restaurant?.businessHours ?? '';
    this.restaurantCategoryIds = restaurant?.categoryIds.slice() ?? [];
    this.currentPage = 'restaurantForm';
  }

  private async saveRestaurantForm(): Promise<void> {
    if (this.contentService === undefined) {
      return;
    }
    const price: number = Number(this.restaurantPriceInput);
    if (this.restaurantNameInput.trim().length === 0 || price <= 0 || this.restaurantCategoryIds.length === 0) {
      this.notice = '请填写店铺名称、人均价格，并至少选择一个品类';
      return;
    }
    const isNewRestaurant: boolean = this.editingRestaurantId.length === 0;
    const restaurantId: string =
      isNewRestaurant ? `custom-restaurant-${Date.now()}` : this.editingRestaurantId;
    await this.contentService.saveRestaurant({
      id: restaurantId,
      sourceType: RestaurantSourceType.CUSTOM,
      name: this.restaurantNameInput.trim(),
      latitude: this.currentLocation.latitude,
      longitude: this.currentLocation.longitude,
      categoryIds: this.restaurantCategoryIds.slice(),
      averagePrice: price,
      businessHours: this.restaurantHoursInput.trim(),
      isOpen: true
    });
    this.refreshContentState();
    if (isNewRestaurant) {
      await this.contentService.toggleFavoriteRestaurant(restaurantId);
      this.refreshContentState();
    }
    this.currentPage = 'favorites';
    this.favoriteTab = 1;
    this.notice = '店铺已保存';
  }

  private async deleteEditingRestaurant(): Promise<void> {
    if (this.contentService === undefined || this.editingRestaurantId.length === 0) {
      return;
    }
    await this.contentService.deleteRestaurant(this.editingRestaurantId);
    this.refreshContentState();
    this.currentPage = 'favorites';
    this.favoriteTab = 1;
    this.notice = '店铺已删除';
  }

  private toggleRestaurantCategory(categoryId: string): void {
    this.restaurantCategoryIds = this.toggleArrayValue(this.restaurantCategoryIds, categoryId);
  }

  private openCategoryForm(category?: FoodCategory, returnPage: string = 'categoryManager'): void {
    this.editingCategoryId = category?.id ?? '';
    this.categoryNameInput = category?.name ?? '';
    this.categoryMealPeriods = category?.mealPeriods.slice() ?? [];
    this.categoryFoodFeelings = category?.foodFeelings.slice() ?? [];
    this.categorySpiceLevels = category?.spiceLevels.slice() ?? [];
    this.categoryBreakfastTraits = category?.breakfastTraits.slice() ?? [];
    this.returnAfterCategorySave = returnPage;
    this.currentPage = 'categoryForm';
  }

  private async saveCategoryForm(): Promise<void> {
    if (this.contentService === undefined) {
      return;
    }
    if (this.categoryNameInput.trim().length === 0 || this.categoryMealPeriods.length === 0 ||
      this.categoryFoodFeelings.length === 0 || this.categorySpiceLevels.length === 0) {
      this.notice = '请填写品类名称，并至少选择一个餐段、食物感受和辣度';
      return;
    }
    const categoryId: string =
      this.editingCategoryId.length === 0 ? `custom-category-${Date.now()}` : this.editingCategoryId;
    await this.contentService.saveCategory({
      id: categoryId,
      sourceType: CategorySourceType.CUSTOM,
      name: this.categoryNameInput.trim(),
      mealPeriods: this.categoryMealPeriods.slice(),
      foodFeelings: this.categoryFoodFeelings.slice(),
      spiceLevels: this.categorySpiceLevels.slice(),
      breakfastTraits: this.categoryBreakfastTraits.slice()
    });
    this.refreshContentState();
    if (this.returnAfterCategorySave === 'restaurantForm' &&
      this.restaurantCategoryIds.indexOf(categoryId) === -1) {
      this.restaurantCategoryIds = this.restaurantCategoryIds.concat(categoryId);
    }
    this.currentPage = this.returnAfterCategorySave;
    this.notice = '品类已保存';
  }

  private async deleteCategory(categoryId: string): Promise<void> {
    if (this.contentService === undefined) {
      return;
    }
    const result: DeleteCategoryResult = await this.contentService.deleteCategory(categoryId);
    this.pendingDeleteCategoryId = '';
    this.refreshContentState();
    if (result.affectedRestaurantCount === 0) {
      this.notice = '品类已删除';
      return;
    }
    this.notice = result.orphanRestaurantCount > 0 ?
      `品类已删除，已解除 ${result.affectedRestaurantCount} 家店铺关联；有店铺需要重新选择品类` :
      `品类已删除，已解除 ${result.affectedRestaurantCount} 家店铺关联`;
  }

  private requestDeleteCategory(categoryId: string): void {
    const isUsed: boolean =
      this.customRestaurants.some((restaurant: Restaurant) => restaurant.categoryIds.indexOf(categoryId) !== -1);
    if (isUsed) {
      this.pendingDeleteCategoryId = categoryId;
      return;
    }
    this.pendingDeleteUnusedCategoryId = categoryId;
  }

  private toggleMealPeriod(value: MealPeriod): void {
    this.categoryMealPeriods = this.toggleArrayValue(this.categoryMealPeriods, value);
  }

  private toggleFoodFeeling(value: FoodFeeling): void {
    this.categoryFoodFeelings = this.toggleArrayValue(this.categoryFoodFeelings, value);
  }

  private toggleCategorySpice(value: SpiceLevel): void {
    this.categorySpiceLevels = this.toggleArrayValue(this.categorySpiceLevels, value);
  }

  private toggleBreakfastTrait(value: BreakfastTrait): void {
    this.categoryBreakfastTraits = this.toggleArrayValue(this.categoryBreakfastTraits, value);
  }

  private toggleArrayValue<T>(values: T[], value: T): T[] {
    return values.indexOf(value) === -1 ? values.concat(value) : values.filter((item: T) => item !== value);
  }

  private calculateDistanceMeters(latitude: number, longitude: number): number {
    const earthRadiusMeters: number = 6371000;
    const latitudeDelta: number = this.toRadians(latitude - this.currentLocation.latitude);
    const longitudeDelta: number = this.toRadians(longitude - this.currentLocation.longitude);
    const fromLatitude: number = this.toRadians(this.currentLocation.latitude);
    const toLatitude: number = this.toRadians(latitude);
    const haversine: number = Math.sin(latitudeDelta / 2) * Math.sin(latitudeDelta / 2) +
      Math.cos(fromLatitude) * Math.cos(toLatitude) *
      Math.sin(longitudeDelta / 2) * Math.sin(longitudeDelta / 2);
    return Math.round(earthRadiusMeters * 2 *
      Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine)));
  }

  private toRadians(degrees: number): number {
    return degrees * Math.PI / 180;
  }

  private getSelectedSpice(): SpiceLevel | undefined {
    if (this.selectedSpice === SpiceLevel.NOT_SPICY) {
      return SpiceLevel.NOT_SPICY;
    }
    if (this.selectedSpice === SpiceLevel.MILD) {
      return SpiceLevel.MILD;
    }
    if (this.selectedSpice === SpiceLevel.SPICY) {
      return SpiceLevel.SPICY;
    }
    return undefined;
  }

  private isDistanceExpansionNotice(): boolean {
    return this.notice.indexOf('附近选择不多，已经为你扩大范围') !== -1 ||
      this.notice.indexOf('这个组合附近选择不多，已经为你调整推荐范围') !== -1;
  }

  private getMainButtonText(): string {
    if (this.isLoading) {
      return '正在挑选...';
    }
    return this.activeMode === 0 ? '帮我选一个' : '开始回答';
  }

  private formatDistance(distanceMeters: number): string {
    if (distanceMeters < 1000) {
      return `${distanceMeters} 米`;
    }
    return `${(distanceMeters / 1000).toFixed(1)} 公里`;
  }

  private formatRating(rating?: number): string {
    return rating === undefined ? '暂无评分' : `${rating.toFixed(1)} 分`;
  }

  private backToHome(): void {
    this.currentPage = 'home';
    this.selectedCategory = undefined;
    this.resultRestaurants = [];
    this.revealedCategoryIds = [];
    this.questionStep = 0;
    this.selectedQuestionOptions = [];
    this.flippingCategoryNames = [];
    this.isQuestionTransitioning = false;
    this.filtersExpanded = false;
    this.errorMessage = '';
    this.systemActionMessage = '';
    this.notice = '轻松一点，交给今天的灵感。';
  }

  private goBack(): void {
    this.systemActionMessage = '';
    this.favoritesMenuExpanded = false;
    this.showDeleteRestaurantConfirm = false;
    this.pendingDeleteUnusedCategoryId = '';
    this.pendingDeleteCategoryId = '';
    if (this.currentPage === 'restaurantForm' || this.currentPage === 'categoryManager') {
      this.currentPage = 'favorites';
      return;
    }
    if (this.currentPage === 'categoryForm') {
      this.currentPage = this.returnAfterCategorySave;
      return;
    }
    this.backToHome();
  }
}

```
