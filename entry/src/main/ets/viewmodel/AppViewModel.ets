import { common, abilityAccessCtrl, PermissionRequestResult, Want } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { HomeUiTokens } from '../components/HomeUiTokens';
import { haversineDistance, toRadians } from '../utils/GeoUtils';
import { ENABLE_DEVICE_LOCATION_ON_STARTUP } from '../config/FeatureFlags';
import { CombinedRestaurantAdapter } from '../data/adapters/CombinedRestaurantAdapter';
import { MockRestaurantAdapter } from '../data/adapters/MockRestaurantAdapter';
import { MOCK_FOOD_CATEGORIES } from '../data/mock/MockFoodCategories';
import { DEFAULT_MOCK_LOCATION } from '../data/mock/MockLocation';
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

@Observed
export class AppViewModel {
  // ── UIContext bridge (set by the owning component in aboutToAppear) ──
  uiContext?: object = undefined;

  // ── Navigation & mode ──
  activeMode: number = 0;
  filtersExpanded: boolean = false;
  currentPage: string = 'home';

  // ── Status UI ──
  isLoading: boolean = false;
  notice: string = '轻松一点，交给今天的灵感。';
  errorMessage: string = '';
  systemActionMessage: string = '';

  // ── Location ──
  locationReady: boolean = false;
  permissionPermanentlyDenied: boolean = false;
  locationFailed: boolean = false;
  isLocating: boolean = true;
  locationPanelExpanded: boolean = false;
  currentLocationLabel: string = '默认位置';
  manualLatitudeInput: string = `${DEFAULT_MOCK_LOCATION.latitude}`;
  manualLongitudeInput: string = `${DEFAULT_MOCK_LOCATION.longitude}`;

  // ── Filters ──
  selectedDistanceMeters: number = 0;
  selectedBudget: BudgetOption = BudgetOption.ALL;
  selectedSpice: string = 'all';

  // ── Random draw state ──
  selectedCategory?: FoodCategory = undefined;
  resultRestaurants: NearbyRestaurant[] = [];
  revealedCategoryIds: string[] = [];
  nearbyRestaurantCount: number = 0;

  // ── Questionnaire ──
  questionStep: number = 0;
  selectedQuestionOptions: QuestionnaireOption[] = [];
  isQuestionTransitioning: boolean = false;

  // ── Flip animation ──
  flippingCategoryNames: string[] = [];
  modeContentOffsetX: number = 0;

  // ── Favorites ──
  favoriteCategoryIds: string[] = [];
  favoriteRestaurantIds: string[] = [];
  favoriteTab: number = 0;
  favoritesMenuExpanded: boolean = false;

  // ── Custom restaurant form ──
  editingRestaurantId: string = '';
  restaurantNameInput: string = '';
  restaurantPriceInput: string = '';
  restaurantHoursInput: string = '';
  restaurantCategoryIds: string[] = [];
  showDeleteRestaurantConfirm: boolean = false;

  // ── Custom category form ──
  editingCategoryId: string = '';
  categoryNameInput: string = '';
  categoryMealPeriods: MealPeriod[] = [];
  categoryFoodFeelings: FoodFeeling[] = [];
  categorySpiceLevels: SpiceLevel[] = [];
  categoryBreakfastTraits: BreakfastTrait[] = [];
  returnAfterCategorySave: string = 'categoryManager';

  // ── Deletion confirmations ──
  pendingDeleteCategoryId: string = '';
  pendingDeleteUnusedCategoryId: string = '';

  // ── User data ──
  customCategories: FoodCategory[] = [];
  customRestaurants: Restaurant[] = [];

  // ── Services ──
  private contentService?: AppContentService = undefined;
  private currentLocation: GeoPoint = DEFAULT_MOCK_LOCATION;
  private readonly combinedAdapter: CombinedRestaurantAdapter =
    new CombinedRestaurantAdapter(new MockRestaurantAdapter(), () => this.customRestaurants);
  private readonly repository: RestaurantRepository = new RestaurantRepository(this.combinedAdapter);
  private readonly recommendationService: RecommendationService =
    new RecommendationService(
      this.repository, DEFAULT_MOCK_LOCATION,
      () => new Date(), () => Math.random(),
      () => MOCK_FOOD_CATEGORIES.concat(this.customCategories)
    );

  // ── Draw-direct reentrancy guard (fixes double-tap race) ──
  private drawDirectLock: boolean = false;
  private isMutating: boolean = false;

  // ═══════════════════════════════════════════
  // LIFECYCLE
  // ═══════════════════════════════════════════

  async initialize(): Promise<void> {
    if (ENABLE_DEVICE_LOCATION_ON_STARTUP) {
      await this.requestLocationPermission();
    } else {
      this.isLocating = false;
      this.locationReady = false;
    }
  }

  async requestLocationPermission(): Promise<void> {
    if (this.isLocating) {
      this.permissionPermanentlyDenied = false;
    }
    try {
      const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
      const permissions: Array<Permissions> = ['ohos.permission.APPROXIMATELY_LOCATION'];
      const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(
        this.getHostContext(), permissions
      );
      const permanentlyDenied: boolean =
        result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED &&
        result.dialogShownResults[0] === false;
      if (permanentlyDenied) {
        this.permissionPermanentlyDenied = true;
        this.isLocating = false;
      } else if (result.authResults[0] === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        await this.getDeviceLocation();
      } else {
        // Permission denied but not permanently — user can try again
        this.permissionPermanentlyDenied = true;
        this.isLocating = false;
      }
    } catch (error) {
      this.isLocating = false;
      this.locationFailed = true;
    }
  }

  async getDeviceLocation(): Promise<void> {
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

  private getHostContext(): common.UIAbilityContext {
    return (this.uiContext as Record<string, Function>)['getHostContext']() as common.UIAbilityContext;
  }

  private getUIContextInstance(): object {
    return this.uiContext!;
  }

  // ═══════════════════════════════════════════
  // LOCATION
  // ═══════════════════════════════════════════

  setActiveLocation(location: GeoPoint, label: string): void {
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

  async continueWithManualLocation(location: GeoPoint, label: string): Promise<void> {
    await this.ensureContentLoaded();
    this.setActiveLocation(location, label);
    this.locationPanelExpanded = false;
    this.notice = `已切换到${label}`;
    await this.persistUserPreferences();
  }

  async applyManualLocationInput(): Promise<void> {
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

  isValidCoordinate(latitude: number, longitude: number): boolean {
    return latitude === latitude && longitude === longitude &&
      latitude >= -90 && latitude <= 90 &&
      longitude >= -180 && longitude <= 180;
  }

  // ═══════════════════════════════════════════
  // PERSISTENCE
  // ═══════════════════════════════════════════

  async persistUserPreferences(): Promise<void> {
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

  async loadPersistedContent(): Promise<void> {
    const context: common.UIAbilityContext = this.getHostContext();
    if (context === undefined) {
      this.errorMessage = '本地内容加载失败，请稍后重试';
      return;
    }
    this.contentService = new AppContentService(new PreferencesLocalStorageAdapter(context));
    await this.contentService.load();
    this.refreshContentState();
    this.restoreUserPreferences();
  }

  async ensureContentLoaded(): Promise<void> {
    if (this.contentService !== undefined) {
      return;
    }
    await this.loadPersistedContent();
  }

  restoreUserPreferences(): void {
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

  refreshContentState(): void {
    if (this.contentService === undefined) {
      return;
    }
    this.favoriteCategoryIds = this.contentService.getFavoriteCategoryIds();
    this.favoriteRestaurantIds = this.contentService.getFavoriteRestaurantIds();
    this.customCategories = this.contentService.getCustomCategories();
    this.customRestaurants = this.contentService.getCustomRestaurants();
  }

  // ═══════════════════════════════════════════
  // FILTERS
  // ═══════════════════════════════════════════

  selectDistanceFilter(distanceMeters: number): void {
    this.selectedDistanceMeters = distanceMeters;
    this.persistUserPreferences();
  }

  selectBudgetFilter(budget: BudgetOption): void {
    this.selectedBudget = budget;
    this.persistUserPreferences();
  }

  selectSpiceFilter(spice: string): void {
    this.selectedSpice = spice;
    this.persistUserPreferences();
  }

  getSelectedSpice(): SpiceLevel | undefined {
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

  // ═══════════════════════════════════════════
  // RANDOM DRAW
  // ═══════════════════════════════════════════

  async drawDirect(answerFilters?: CategoryAnswerFilters): Promise<void> {
    if (this.drawDirectLock) {
      return;
    }
    this.drawDirectLock = true;
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
      this.drawDirectLock = false;
      this.isLoading = false;
    }
  }

  drawAgain(): void {
    const answerFilters: CategoryAnswerFilters | undefined = this.activeMode === 1 ?
      mergeAnswerFilters(this.selectedQuestionOptions) : undefined;
    this.drawDirect(answerFilters);
  }

  // ═══════════════════════════════════════════
  // MODE SWITCHING
  // ═══════════════════════════════════════════

  selectMode(mode: number): void {
    if (this.activeMode === mode || this.isLoading) {
      return;
    }
    this.modeContentOffsetX = mode > this.activeMode ?
      HomeUiTokens.MODE_SWITCH_TRANSLATE_DISTANCE : -HomeUiTokens.MODE_SWITCH_TRANSLATE_DISTANCE;
    this.activeMode = mode;
    this.questionStep = 0;
    this.selectedQuestionOptions = [];
    this.notice = mode === 0 ? '直接抽取模式：点击主按钮即可开始。' : '回答两题，让结果更贴近现在的心情。';
    const ctx = this.getUIContextInstance() as Record<string, Function>;
    ctx['animateTo']({ duration: HomeUiTokens.MODE_SWITCH_TRANSITION_DURATION, curve: Curve.EaseOut }, () => {
      this.modeContentOffsetX = 0;
    });
  }

  handleModeSwipe(offsetX: number): void {
    if (this.currentPage !== 'home' || this.isLoading || Math.abs(offsetX) < HomeUiTokens.MODE_SWIPE_THRESHOLD) {
      return;
    }
    this.selectMode(offsetX < 0 ? 1 : 0);
  }

  // ═══════════════════════════════════════════
  // QUESTIONNAIRE
  // ═══════════════════════════════════════════

  getCurrentQuestion(): QuestionnaireQuestion {
    return getQuestionnaireQuestions(this.recommendationService.getCurrentMealPeriod())[this.questionStep];
  }

  isQuestionOptionSelected(option: QuestionnaireOption): boolean {
    return this.selectedQuestionOptions.length > this.questionStep &&
      this.selectedQuestionOptions[this.questionStep].id === option.id;
  }

  async selectQuestionOption(option: QuestionnaireOption): Promise<void> {
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

  canSubmitQuestionnaire(): boolean {
    return this.questionStep === 1 && this.selectedQuestionOptions.length === 2;
  }

  submitQuestionnaire(): void {
    if (!this.canSubmitQuestionnaire()) {
      return;
    }
    this.drawDirect(mergeAnswerFilters(this.selectedQuestionOptions));
  }

  // ═══════════════════════════════════════════
  // FLIP ANIMATION
  // ═══════════════════════════════════════════

  async showFlipAnimation(result: RecommendationResult, category: FoodCategory): Promise<void> {
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

  getFlipCategoryNames(offset: number): string[] {
    const categories: FoodCategory[] = this.getAllCategories();
    const count: number = categories.length;
    return [
      categories[offset % count].name,
      categories[(offset + 1) % count].name,
      categories[(offset + 2) % count].name
    ];
  }

  delay(milliseconds: number): Promise<void> {
    return new Promise<void>((resolve: () => void) => {
      setTimeout(resolve, milliseconds);
    });
  }

  // ═══════════════════════════════════════════
  // SYSTEM ACTIONS
  // ═══════════════════════════════════════════

  openAppSettings(): void {
    this.systemActionMessage = '';
    const context: common.UIAbilityContext = this.getHostContext();
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

  openMapNavigation(name: string, latitude: number, longitude: number): void {
    this.systemActionMessage = '';
    const context: common.UIAbilityContext = this.getHostContext();
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

  // ═══════════════════════════════════════════
  // DATA ACCESSORS
  // ═══════════════════════════════════════════

  getAllCategories(): FoodCategory[] {
    return MOCK_FOOD_CATEGORIES.concat(this.customCategories);
  }

  getAllRestaurants(): Restaurant[] {
    return MOCK_RESTAURANTS.concat(this.customRestaurants);
  }

  getFavoriteCategories(): FoodCategory[] {
    return this.getAllCategories()
      .filter((category: FoodCategory) => this.favoriteCategoryIds.indexOf(category.id) !== -1);
  }

  getFavoriteNearbyRestaurants(): NearbyRestaurant[] {
    return this.getAllRestaurants()
      .filter((restaurant: Restaurant) => this.favoriteRestaurantIds.indexOf(restaurant.id) !== -1)
      .map((restaurant: Restaurant): NearbyRestaurant => {
        return {
          restaurant: restaurant,
          distanceMeters: haversineDistance(this.currentLocation, {
            latitude: restaurant.latitude,
            longitude: restaurant.longitude
          })
        };
      })
      .sort((left: NearbyRestaurant, right: NearbyRestaurant) => left.distanceMeters - right.distanceMeters);
  }

  isFavoriteCategory(categoryId: string): boolean {
    return this.favoriteCategoryIds.indexOf(categoryId) !== -1;
  }

  isFavoriteRestaurant(restaurantId: string): boolean {
    return this.favoriteRestaurantIds.indexOf(restaurantId) !== -1;
  }

  // ═══════════════════════════════════════════
  // TOGGLE FAVORITES
  // ═══════════════════════════════════════════

  async toggleFavoriteCategory(categoryId: string): Promise<void> {
    if (this.contentService === undefined || categoryId.length === 0 || this.isMutating) {
      return;
    }
    this.isMutating = true;
    try {
      await this.contentService.toggleFavoriteCategory(categoryId);
      this.refreshContentState();
      this.notice = this.isFavoriteCategory(categoryId) ? '已收藏品类' : '已取消收藏品类';
    } finally {
      this.isMutating = false;
    }
  }

  async toggleFavoriteRestaurant(restaurantId: string): Promise<void> {
    if (this.contentService === undefined || this.isMutating) {
      return;
    }
    this.isMutating = true;
    try {
      await this.contentService.toggleFavoriteRestaurant(restaurantId);
      this.refreshContentState();
      this.notice = this.isFavoriteRestaurant(restaurantId) ? '已收藏店铺' : '已取消收藏店铺';
    } finally {
      this.isMutating = false;
    }
  }

  // ═══════════════════════════════════════════
  // RESTAURANT FORM
  // ═══════════════════════════════════════════

  openRestaurantForm(restaurant?: Restaurant): void {
    this.editingRestaurantId = restaurant?.id ?? '';
    this.restaurantNameInput = restaurant?.name ?? '';
    this.restaurantPriceInput = restaurant === undefined ? '' : `${restaurant.averagePrice}`;
    this.restaurantHoursInput = restaurant?.businessHours ?? '';
    this.restaurantCategoryIds = restaurant?.categoryIds.slice() ?? [];
    this.currentPage = 'restaurantForm';
  }

  async saveRestaurantForm(): Promise<void> {
    if (this.contentService === undefined || this.isMutating) {
      return;
    }
    this.isMutating = true;
    try {
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
    } finally {
      this.isMutating = false;
    }
  }

  async deleteEditingRestaurant(): Promise<void> {
    if (this.contentService === undefined || this.editingRestaurantId.length === 0 || this.isMutating) {
      return;
    }
    this.isMutating = true;
    try {
      await this.contentService.deleteRestaurant(this.editingRestaurantId);
      this.refreshContentState();
      this.currentPage = 'favorites';
      this.favoriteTab = 1;
      this.notice = '店铺已删除';
    } finally {
      this.isMutating = false;
    }
  }

  toggleRestaurantCategory(categoryId: string): void {
    this.restaurantCategoryIds = this.toggleArrayValue(this.restaurantCategoryIds, categoryId);
  }

  // ═══════════════════════════════════════════
  // CATEGORY FORM
  // ═══════════════════════════════════════════

  openCategoryForm(category?: FoodCategory, returnPage: string = 'categoryManager'): void {
    this.editingCategoryId = category?.id ?? '';
    this.categoryNameInput = category?.name ?? '';
    this.categoryMealPeriods = category?.mealPeriods.slice() ?? [];
    this.categoryFoodFeelings = category?.foodFeelings.slice() ?? [];
    this.categorySpiceLevels = category?.spiceLevels.slice() ?? [];
    this.categoryBreakfastTraits = category?.breakfastTraits.slice() ?? [];
    this.returnAfterCategorySave = returnPage;
    this.currentPage = 'categoryForm';
  }

  async saveCategoryForm(): Promise<void> {
    if (this.contentService === undefined || this.isMutating) {
      return;
    }
    this.isMutating = true;
    try {
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
    } finally {
      this.isMutating = false;
    }
  }

  async deleteCategory(categoryId: string): Promise<void> {
    if (this.contentService === undefined || this.isMutating) {
      return;
    }
    this.isMutating = true;
    try {
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
    } finally {
      this.isMutating = false;
    }
  }

  requestDeleteCategory(categoryId: string): void {
    const isUsed: boolean =
      this.customRestaurants.some((restaurant: Restaurant) => restaurant.categoryIds.indexOf(categoryId) !== -1);
    if (isUsed) {
      this.pendingDeleteCategoryId = categoryId;
      return;
    }
    this.pendingDeleteUnusedCategoryId = categoryId;
  }

  // ═══════════════════════════════════════════
  // CATEGORY ATTRIBUTE TOGGLES
  // ═══════════════════════════════════════════

  toggleMealPeriod(value: MealPeriod): void {
    this.categoryMealPeriods = this.toggleArrayValue(this.categoryMealPeriods, value);
  }

  toggleFoodFeeling(value: FoodFeeling): void {
    this.categoryFoodFeelings = this.toggleArrayValue(this.categoryFoodFeelings, value);
  }

  toggleCategorySpice(value: SpiceLevel): void {
    this.categorySpiceLevels = this.toggleArrayValue(this.categorySpiceLevels, value);
  }

  toggleBreakfastTrait(value: BreakfastTrait): void {
    this.categoryBreakfastTraits = this.toggleArrayValue(this.categoryBreakfastTraits, value);
  }

  toggleArrayValue<T>(values: T[], value: T): T[] {
    return values.indexOf(value) === -1 ? values.concat(value) : values.filter((item: T) => item !== value);
  }

  // ═══════════════════════════════════════════
  // FORMATTERS
  // ═══════════════════════════════════════════

  isDistanceExpansionNotice(): boolean {
    return this.notice.indexOf('附近选择不多，已经为你扩大范围') !== -1 ||
      this.notice.indexOf('这个组合附近选择不多，已经为你调整推荐范围') !== -1;
  }

  getMainButtonText(): string {
    if (this.isLoading) {
      return '正在挑选...';
    }
    return this.activeMode === 0 ? '帮我选一个' : '开始回答';
  }

  formatDistance(distanceMeters: number): string {
    if (distanceMeters < 1000) {
      return `${distanceMeters} 米`;
    }
    return `${(distanceMeters / 1000).toFixed(1)} 公里`;
  }

  formatRating(rating?: number): string {
    return rating === undefined ? '暂无评分' : `${rating.toFixed(1)} 分`;
  }

  // ═══════════════════════════════════════════
  // NAVIGATION
  // ═══════════════════════════════════════════

  backToHome(): void {
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

  goBack(): void {
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
