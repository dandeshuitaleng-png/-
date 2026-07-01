import { Restaurant, RestaurantSourceType } from '../../models/Restaurant';

// M5 will generate these offsets around the device location. M1 keeps stable
// coordinates so the data foundation can be exercised without system access.
export const MOCK_RESTAURANTS: Restaurant[] = [
  { id: 'mock-01', sourceType: RestaurantSourceType.MOCK, name: '晨光包子铺', latitude: 31.2308, longitude: 121.4742, categoryIds: ['baozi-porridge', 'soy-milk-fritter'], averagePrice: 12, rating: 4.6, businessHours: '06:00-10:30', isOpen: true },
  { id: 'mock-02', sourceType: RestaurantSourceType.MOCK, name: '巷口豆浆油条', latitude: 31.2311, longitude: 121.4750, categoryIds: ['soy-milk-fritter'], averagePrice: 9, rating: 4.4, businessHours: '06:00-11:00', isOpen: true },
  { id: 'mock-03', sourceType: RestaurantSourceType.MOCK, name: '阿婆馄饨', latitude: 31.2320, longitude: 121.4748, categoryIds: ['dumpling-wonton'], averagePrice: 18, rating: 4.7, businessHours: '06:30-21:00', isOpen: true },
  { id: 'mock-04', sourceType: RestaurantSourceType.MOCK, name: '一碗好面', latitude: 31.2298, longitude: 121.4738, categoryIds: ['noodles'], averagePrice: 24, rating: 4.5, businessHours: '07:00-22:00', isOpen: true },
  { id: 'mock-05', sourceType: RestaurantSourceType.MOCK, name: '邻里小炒', latitude: 31.2295, longitude: 121.4756, categoryIds: ['home-cooking'], averagePrice: 42, rating: 4.3, businessHours: '10:30-21:30', isOpen: true },
  { id: 'mock-06', sourceType: RestaurantSourceType.MOCK, name: '红炉火锅', latitude: 31.2289, longitude: 121.4761, categoryIds: ['hotpot'], averagePrice: 88, rating: 4.8, businessHours: '11:00-23:30', isOpen: true },
  { id: 'mock-07', sourceType: RestaurantSourceType.MOCK, name: '热辣串串香', latitude: 31.2325, longitude: 121.4768, categoryIds: ['hotpot', 'malatang'], averagePrice: 56, rating: 4.6, businessHours: '11:00-23:00', isOpen: true },
  { id: 'mock-08', sourceType: RestaurantSourceType.MOCK, name: '炭火小院', latitude: 31.2282, longitude: 121.4729, categoryIds: ['barbecue'], averagePrice: 72, rating: 4.5, businessHours: '16:30-01:00', isOpen: true },
  { id: 'mock-09', sourceType: RestaurantSourceType.MOCK, name: '湘味人家', latitude: 31.2332, longitude: 121.4732, categoryIds: ['sichuan-hunan', 'home-cooking'], averagePrice: 58, rating: 4.7, businessHours: '10:30-22:00', isOpen: true },
  { id: 'mock-10', sourceType: RestaurantSourceType.MOCK, name: '清远粤味馆', latitude: 31.2274, longitude: 121.4771, categoryIds: ['cantonese'], averagePrice: 76, rating: 4.4, businessHours: '10:30-21:30', isOpen: true },
  { id: 'mock-11', sourceType: RestaurantSourceType.MOCK, name: '砂锅食堂', latitude: 31.2338, longitude: 121.4778, categoryIds: ['claypot-rice'], averagePrice: 32, rating: 4.5, businessHours: '10:00-22:00', isOpen: true },
  { id: 'mock-12', sourceType: RestaurantSourceType.MOCK, name: '快享便当', latitude: 31.2268, longitude: 121.4722, categoryIds: ['quick-meal'], averagePrice: 28, rating: 4.2, businessHours: '10:00-20:30', isOpen: true },
  { id: 'mock-13', sourceType: RestaurantSourceType.MOCK, name: '老街牛肉面', latitude: 31.2343, longitude: 121.4718, categoryIds: ['noodles'], averagePrice: 30, rating: 4.6, businessHours: '07:30-22:30', isOpen: true },
  { id: 'mock-14', sourceType: RestaurantSourceType.MOCK, name: '锅气小馆', latitude: 31.2260, longitude: 121.4780, categoryIds: ['home-cooking', 'sichuan-hunan'], averagePrice: 48, rating: 4.3, businessHours: '10:30-21:30', isOpen: true },
  { id: 'mock-15', sourceType: RestaurantSourceType.MOCK, name: '岭南烧味', latitude: 31.2351, longitude: 121.4788, categoryIds: ['cantonese', 'quick-meal'], averagePrice: 38, rating: 4.5, businessHours: '10:00-21:00', isOpen: true },
  { id: 'mock-16', sourceType: RestaurantSourceType.MOCK, name: '麻辣一锅', latitude: 31.2252, longitude: 121.4710, categoryIds: ['malatang'], averagePrice: 35, rating: 4.4, businessHours: '10:30-23:00', isOpen: true },
  { id: 'mock-17', sourceType: RestaurantSourceType.MOCK, name: '北方饺子馆', latitude: 31.2358, longitude: 121.4703, categoryIds: ['dumpling-wonton'], averagePrice: 33, rating: 4.5, businessHours: '09:30-21:30', isOpen: true },
  { id: 'mock-18', sourceType: RestaurantSourceType.MOCK, name: '小桌家常菜', latitude: 31.2244, longitude: 121.4792, categoryIds: ['home-cooking'], averagePrice: 45, rating: 4.1, businessHours: '10:30-21:00', isOpen: true },
  { id: 'mock-19', sourceType: RestaurantSourceType.MOCK, name: '围炉涮肉', latitude: 31.2366, longitude: 121.4798, categoryIds: ['hotpot'], averagePrice: 96, rating: 4.7, businessHours: '11:00-23:00', isOpen: true },
  { id: 'mock-20', sourceType: RestaurantSourceType.MOCK, name: '烟火烧烤档', latitude: 31.2236, longitude: 121.4698, categoryIds: ['barbecue'], averagePrice: 62, rating: 4.3, businessHours: '17:00-02:00', isOpen: true },
  { id: 'mock-21', sourceType: RestaurantSourceType.MOCK, name: '瓦罐煲仔饭', latitude: 31.2372, longitude: 121.4690, categoryIds: ['claypot-rice'], averagePrice: 36, rating: 4.6, businessHours: '10:00-21:30', isOpen: true },
  { id: 'mock-22', sourceType: RestaurantSourceType.MOCK, name: '午间简餐', latitude: 31.2228, longitude: 121.4805, categoryIds: ['quick-meal'], averagePrice: 26, rating: 4.0, businessHours: '10:00-20:00', isOpen: true },
  { id: 'mock-23', sourceType: RestaurantSourceType.MOCK, name: '山城小面', latitude: 31.2380, longitude: 121.4812, categoryIds: ['noodles', 'malatang'], averagePrice: 29, rating: 4.5, businessHours: '08:00-23:00', isOpen: true },
  { id: 'mock-24', sourceType: RestaurantSourceType.MOCK, name: '清粥早点', latitude: 31.2219, longitude: 121.4682, categoryIds: ['baozi-porridge'], averagePrice: 15, rating: 4.2, businessHours: '06:00-10:00', isOpen: true }
];

