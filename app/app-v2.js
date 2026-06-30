const diningDataV2 = [
  { id: "canteen-noodles", name: "北校区食堂二楼粉面档", category: "湖南米粉/面", price: 10, distance: 0.1, spice: "optional", tags: ["低价", "少油可选", "出餐快"], speed: "快", wait: "3-5分钟", hours: "06:30-13:30" },
  { id: "canteen-steamed", name: "北校区食堂二楼蒸菜档", category: "蒸菜/快餐", price: 13, distance: 0.1, spice: "optional", tags: ["少油", "蔬菜多", "热量适中"], speed: "快", wait: "5-8分钟", hours: "10:30-13:30 / 16:30-19:30" },
  { id: "canteen-light", name: "北校区食堂四楼轻食饭", category: "轻食/鸡胸肉饭", price: 20, distance: 0.1, spice: "no", tags: ["低脂", "高蛋白", "控卡"], speed: "快", wait: "6-10分钟", hours: "10:30-19:30" },
  { id: "wanhuayuan-rice-noodle", name: "万花园路拌粉小店", category: "拌粉/汤粉", price: 11, distance: 0.3, spice: "optional", tags: ["低价", "快餐", "早餐"], speed: "快", wait: "3-6分钟", hours: "07:00-14:00 / 17:00-21:00" },
  { id: "wanhuayuan-gaima", name: "万花园路现炒盖码饭", category: "湘菜盖饭", price: 17, distance: 0.4, spice: "yes", tags: ["高蛋白", "现炒", "饱腹"], speed: "中", wait: "8-12分钟", hours: "10:30-21:30" },
  { id: "shuitang-muton", name: "水塘垸社区木桶饭", category: "木桶饭/快餐", price: 16, distance: 0.5, spice: "optional", tags: ["饱腹", "可加青菜", "出餐快"], speed: "快", wait: "6-10分钟", hours: "10:00-21:00" },
  { id: "chunjian-fried", name: "春建路炸串铺", category: "炸串/小吃", price: 14, distance: 0.6, spice: "optional", tags: ["夜宵", "小吃", "热量较高"], speed: "快", wait: "5-8分钟", hours: "15:00-23:30" },
  { id: "chunjian-drypot", name: "春建路麻辣香锅", category: "香锅/自选", price: 24, distance: 0.7, spice: "yes", tags: ["可加蔬菜", "高蛋白", "重口味"], speed: "中", wait: "10-15分钟", hours: "10:30-22:00" },
  { id: "chunjian-dumpling", name: "春建路东北水饺", category: "饺子/简餐", price: 15, distance: 0.8, spice: "no", tags: ["少油", "主食稳定", "清淡"], speed: "中", wait: "8-12分钟", hours: "10:00-21:30" },
  { id: "ansha-beef-noodle", name: "安沙镇兰州牛肉面", category: "牛肉面/拉面", price: 18, distance: 1.0, spice: "optional", tags: ["高蛋白", "汤面", "少油可选"], speed: "中", wait: "8-12分钟", hours: "09:00-22:00" },
  { id: "ansha-tea-light", name: "安沙镇茶饮轻食站", category: "茶饮/三明治", price: 16, distance: 1.2, spice: "no", tags: ["轻食", "下午茶", "低油"], speed: "快", wait: "3-6分钟", hours: "09:00-22:30" },
  { id: "bolin", name: "伯林餐馆", category: "家常菜/炒菜", price: 35, distance: 1.5, spice: "optional", tags: ["聚餐", "现炒", "高蛋白"], speed: "慢", wait: "15-25分钟", hours: "10:30-21:30" }
];

const schoolLocationV2 = {
  name: "长沙师范学院安沙校区",
  fallbackAddress: "长沙市长沙县安沙镇万花园路9号",
  lng: 113.0826,
  lat: 28.3538
};
const apiBaseV2 = window.location.protocol === "file:" ? "http://127.0.0.1:8787" : "";

const amapPlaceMetaV2 = {
  "canteen-noodles": { source: "manual", sourcePoiId: "manual-canteen-noodles", address: "长沙师范学院安沙校区北校区食堂二楼", longitude: 113.0827, latitude: 28.3539, distanceMeters: 100, walkingMinutes: 3, routeSteps: ["从教学楼步行至北校区食堂", "上二楼到达粉面档"], businessArea: "校内食堂", environmentTags: ["校内", "近教学楼"], amapTags: ["食堂", "粉面"], naviPoiId: "manual-canteen" },
  "canteen-steamed": { source: "manual", sourcePoiId: "manual-canteen-steamed", address: "长沙师范学院安沙校区北校区食堂二楼", longitude: 113.0827, latitude: 28.3539, distanceMeters: 100, walkingMinutes: 3, routeSteps: ["从教学楼步行至北校区食堂", "上二楼到达蒸菜档"], businessArea: "校内食堂", environmentTags: ["校内", "正餐"], amapTags: ["食堂", "蒸菜"], naviPoiId: "manual-canteen" },
  "canteen-light": { source: "manual", sourcePoiId: "manual-canteen-light", address: "长沙师范学院安沙校区北校区食堂四楼", longitude: 113.0828, latitude: 28.3540, distanceMeters: 120, walkingMinutes: 4, routeSteps: ["从教学楼步行至北校区食堂", "上四楼到达轻食窗口"], businessArea: "校内食堂", environmentTags: ["校内", "控卡"], amapTags: ["食堂", "轻食"], naviPoiId: "manual-canteen" },
  "wanhuayuan-rice-noodle": { source: "amap", sourcePoiId: "AMAP_DEMO_WANHUAYUAN_FEN", address: "长沙县安沙镇万花园路沿线", longitude: 113.0848, latitude: 28.3542, amapRating: 4.5, amapCost: 11, amapTags: ["拌粉", "早餐"], distanceMeters: 320, walkingMinutes: 5, routeSteps: ["从校门口向东步行", "沿万花园路前行约260米", "到达沿街粉面店"], businessArea: "万花园路", environmentTags: ["校外学生街", "早餐方便"], naviPoiId: "AMAP_DEMO_WANHUAYUAN_FEN" },
  "wanhuayuan-gaima": { source: "amap", sourcePoiId: "AMAP_DEMO_GAIMA", address: "长沙县安沙镇万花园路沿线", longitude: 113.0860, latitude: 28.3545, amapRating: 4.3, amapCost: 17, amapTags: ["盖码饭", "湘菜"], distanceMeters: 420, walkingMinutes: 6, routeSteps: ["从校门口向东步行", "沿万花园路前行约360米", "到达现炒盖码饭"], businessArea: "万花园路", environmentTags: ["校外学生街", "现炒"], naviPoiId: "AMAP_DEMO_GAIMA" },
  "shuitang-muton": { source: "amap", sourcePoiId: "AMAP_DEMO_MUTON", address: "长沙县安沙镇水塘垸社区周边", longitude: 113.0870, latitude: 28.3550, amapRating: 4.2, amapCost: 16, amapTags: ["木桶饭", "快餐"], distanceMeters: 520, walkingMinutes: 7, routeSteps: ["从校门口向东步行", "沿万花园路前行", "转入水塘垸社区方向", "到达木桶饭"], businessArea: "水塘垸社区", environmentTags: ["社区快餐", "管饱"], naviPoiId: "AMAP_DEMO_MUTON" },
  "chunjian-fried": { source: "amap", sourcePoiId: "AMAP_DEMO_FRIED", address: "长沙县安沙镇春建路沿线", longitude: 113.0884, latitude: 28.3557, amapRating: 4.4, amapCost: 14, amapTags: ["炸串", "小吃"], distanceMeters: 650, walkingMinutes: 9, routeSteps: ["从校门口向东步行", "沿万花园路到春建路口", "沿春建路步行约180米", "到达炸串铺"], businessArea: "春建路", environmentTags: ["夜宵", "小吃集中"], naviPoiId: "AMAP_DEMO_FRIED" },
  "chunjian-drypot": { source: "amap", sourcePoiId: "AMAP_DEMO_DRY_POT", address: "长沙县安沙镇春建路学生街", longitude: 113.0890, latitude: 28.3561, amapRating: 4.6, amapCost: 24, amapTags: ["麻辣香锅", "自选"], distanceMeters: 720, walkingMinutes: 9, routeSteps: ["从校门口向东步行", "沿万花园路到春建路口", "沿春建路步行约260米", "到达麻辣香锅"], businessArea: "春建路", environmentTags: ["校外学生街", "附近茶饮多"], naviPoiId: "AMAP_DEMO_DRY_POT" },
  "chunjian-dumpling": { source: "amap", sourcePoiId: "AMAP_DEMO_DUMPLING", address: "长沙县安沙镇春建路沿线", longitude: 113.0897, latitude: 28.3566, amapRating: 4.1, amapCost: 15, amapTags: ["水饺", "简餐"], distanceMeters: 820, walkingMinutes: 10, routeSteps: ["从校门口向东步行", "沿万花园路到春建路口", "沿春建路步行约350米", "到达水饺店"], businessArea: "春建路", environmentTags: ["简餐", "清淡"], naviPoiId: "AMAP_DEMO_DUMPLING" },
  "ansha-beef-noodle": { source: "amap", sourcePoiId: "AMAP_DEMO_BEEF_NOODLE", address: "长沙县安沙镇主街周边", longitude: 113.0920, latitude: 28.3580, amapRating: 4.2, amapCost: 18, amapTags: ["牛肉面", "拉面"], distanceMeters: 1050, walkingMinutes: 14, routeSteps: ["从校门口向东步行", "沿万花园路到安沙镇方向", "到达牛肉面店"], businessArea: "安沙镇", environmentTags: ["镇区", "汤面"], naviPoiId: "AMAP_DEMO_BEEF_NOODLE" },
  "ansha-tea-light": { source: "amap", sourcePoiId: "AMAP_DEMO_TEA_LIGHT", address: "长沙县安沙镇茶饮轻食集中区", longitude: 113.0940, latitude: 28.3590, amapRating: 4.5, amapCost: 16, amapTags: ["茶饮", "三明治"], distanceMeters: 1200, walkingMinutes: 16, routeSteps: ["从校门口向东步行", "沿万花园路到安沙镇方向", "到达茶饮轻食站"], businessArea: "安沙镇", environmentTags: ["下午茶", "外带方便"], naviPoiId: "AMAP_DEMO_TEA_LIGHT" },
  "bolin": { source: "amap", sourcePoiId: "AMAP_DEMO_BOLIN", address: "长沙县安沙镇伯林餐馆周边", longitude: 113.0970, latitude: 28.3602, amapRating: 4.4, amapCost: 35, amapTags: ["炒菜", "家常菜"], distanceMeters: 1500, walkingMinutes: 20, routeSteps: ["从校门口向东步行", "沿万花园路到安沙镇方向", "进入镇区餐饮街", "到达伯林餐馆"], businessArea: "安沙镇", environmentTags: ["聚餐", "正餐"], naviPoiId: "AMAP_DEMO_BOLIN" }
};

diningDataV2.forEach((item) => {
  Object.assign(item, {
    source: "manual",
    sourcePoiId: `manual-${item.id}`,
    address: schoolLocationV2.fallbackAddress,
    longitude: schoolLocationV2.lng,
    latitude: schoolLocationV2.lat,
    distanceMeters: Math.round(item.distance * 1000),
    walkingMinutes: Math.max(2, Math.round(item.distance * 12)),
    routeSteps: ["从当前位置出发", "步行至推荐餐厅"],
    amapTags: [],
    environmentTags: []
  }, amapPlaceMetaV2[item.id] || {});
});
const manualFallbackDataV2 = diningDataV2.slice();

const labelsV2 = {
  people: { one: "一个人", two: "两个人", many: "多人" },
  type: { random: "随便", noodles: "粉面", rice: "米饭", snack: "小吃", light: "轻食", midnight: "夜宵" },
  taste: { light: "清淡点", normal: "正常", spicy: "想吃辣", heavy: "重口味" },
  need: { fast: "赶时间", filling: "想吃饱", nearby: "不想走远", treat: "奖励自己" },
  mealMode: { dinein: "堂食", takeout: "打包", delivery: "外卖", any: "都可以" },
  budget: { all: "不限预算", under10: "10 元内", under20: "20 元内", under30: "30 元内", over30: "30 元以上" },
  distance: { all: "不限距离", near: "0.5km 内", walkable: "1km 内", town: "2km 内" }
};

const stateV2 = {
  tab: "eat",
  people: "one",
  type: "noodles",
  taste: "normal",
  need: "fast",
  mealMode: "dinein",
  budget: "under20",
  distance: "walkable",
  avoidSpicy: true,
  result: null,
  shownIds: [],
  favorites: new Set(["canteen-noodles", "chunjian-drypot", "ansha-tea-light"]),
  favoriteFilter: "all",
  history: []
};

const currentTimeV2 = "12:30";
const mainScrollV2 = document.querySelector("#mainScroll");
const flipCardV2 = document.querySelector("#flipCard");
const resultCardV2 = document.querySelector("#resultCard");
const toastV2 = document.querySelector("#toast");
const sheetsV2 = {
  prefsSheet: document.querySelector("#prefsSheet"),
  detailSheet: document.querySelector("#detailSheet"),
  routeSheet: document.querySelector("#routeSheet")
};

document.querySelector("#startFlipButton").addEventListener("click", () => startFlipV2(true));
document.querySelector("#againButton").addEventListener("click", () => startFlipV2(false));
document.querySelector("#favoriteButton").addEventListener("click", toggleCurrentFavoriteV2);
document.querySelector("#detailButton").addEventListener("click", () => {
  if (stateV2.result) openDetailV2(stateV2.result.main);
});
document.querySelector("#goButton").addEventListener("click", () => {
  if (stateV2.result) openRouteV2(stateV2.result.main);
});
document.querySelector("#openPrefsButton").addEventListener("click", () => openSheetV2("prefsSheet"));
document.querySelector("#minePrefsButton").addEventListener("click", () => openSheetV2("prefsSheet"));
document.querySelector("#jumpFavoritesButton").addEventListener("click", () => setTabV2("favorites"));
document.querySelector("#prefsCancelButton").addEventListener("click", () => closeSheetV2("prefsSheet"));
document.querySelector("#prefsSaveButton").addEventListener("click", savePreferencesV2);
document.querySelector("#resetButton").addEventListener("click", resetTodayQuestionsV2);
document.querySelector("#spiceSwitch").addEventListener("click", () => {
  stateV2.avoidSpicy = !stateV2.avoidSpicy;
  renderAllV2();
});

document.querySelectorAll("[data-tab]").forEach((button) => {
  button.addEventListener("click", () => setTabV2(button.dataset.tab));
});
document.querySelectorAll("[data-close]").forEach((button) => {
  button.addEventListener("click", () => closeSheetV2(button.dataset.close));
});
document.querySelectorAll(".sheet").forEach((sheet) => {
  sheet.addEventListener("click", (event) => {
    if (event.target === sheet) closeSheetV2(sheet.id);
  });
});
document.querySelectorAll("[data-group]").forEach((group) => {
  group.addEventListener("click", (event) => {
    const button = event.target.closest("button[data-value]");
    if (!button) return;
    stateV2[group.dataset.group] = button.dataset.value;
    stateV2.shownIds = [];
    renderAllV2();
  });
});
document.querySelectorAll("[data-favorite-filter]").forEach((button) => {
  button.addEventListener("click", () => {
    stateV2.favoriteFilter = button.dataset.favoriteFilter;
    renderFavoritesV2();
  });
});

function setTabV2(tab) {
  stateV2.tab = tab;
  document.querySelectorAll(".tab-page").forEach((page) => {
    page.classList.toggle("active", page.dataset.page === tab);
  });
  document.querySelectorAll("[data-tab]").forEach((button) => {
    button.classList.toggle("active", button.dataset.tab === tab);
  });
  if (tab === "favorites") renderFavoritesV2();
  if (tab === "mine") renderMineV2();
  mainScrollV2.scrollTo({ top: 0, behavior: "smooth" });
}

function openSheetV2(id) {
  renderAllV2();
  sheetsV2[id].classList.add("show");
}

function closeSheetV2(id) {
  sheetsV2[id].classList.remove("show");
}

function savePreferencesV2() {
  closeSheetV2("prefsSheet");
  renderAllV2();
  showToastV2("长期偏好已保存，会作为默认推荐条件");
}

function resetTodayQuestionsV2() {
  stateV2.people = "one";
  stateV2.type = "noodles";
  stateV2.taste = "normal";
  stateV2.need = "fast";
  stateV2.mealMode = "dinein";
  stateV2.result = null;
  stateV2.shownIds = [];
  flipCardV2.classList.remove("flipped");
  renderAllV2();
  showToastV2("今日问题已重置");
}

function startFlipV2(resetCycle) {
  flipCardV2.classList.remove("flipped");
  stateV2.result = buildRecommendationV2(resetCycle);
  renderResultV2();
  addHistoryV2(stateV2.result.main);
  window.setTimeout(() => flipCardV2.classList.add("flipped"), 120);
  window.setTimeout(() => flipCardV2.scrollIntoView({ behavior: "smooth", block: "start" }), 180);
  showToastV2("已根据今日问题翻出推荐");
}

function buildRecommendationV2(resetCycle) {
  if (resetCycle) stateV2.shownIds = [];
  const pool = candidatePoolV2();
  let ranked = pool.options.slice().sort((a, b) => scoreV2(b) - scoreV2(a));
  const unseen = ranked.filter((item) => !stateV2.shownIds.includes(item.id));
  let notice = pool.notice;
  if (unseen.length === 0) {
    stateV2.shownIds = [];
    notice = appendNoticeV2(notice, "已换完一轮，重新开始推荐");
  } else {
    ranked = unseen;
  }
  const main = ranked[0];
  stateV2.shownIds.push(main.id);
  return {
    main,
    alternatives: pool.options.filter((item) => item.id !== main.id).sort((a, b) => scoreV2(b) - scoreV2(a)).slice(0, 3),
    notice
  };
}

function candidatePoolV2() {
  const openItems = diningDataV2.filter(isOpenNowV2);
  let pool = openItems.filter((item) => matchesLongPrefsV2(item) && matchesTypeV2(item) && matchesTasteV2(item));
  if (pool.length > 0) return { options: pool, notice: "" };
  pool = openItems.filter((item) => matchesLongPrefsV2(item) && matchesTasteV2(item));
  if (pool.length > 0) return { options: pool, notice: "今天想吃的类型较少，已先保留预算、距离和口味" };
  pool = openItems.filter((item) => matchesTypeV2(item) && matchesTasteV2(item) && matchesSpiceV2(item));
  if (pool.length > 0) return { options: pool, notice: "默认预算或距离较窄，已优先保留今日问题" };
  if (openItems.length > 0) return { options: openItems, notice: "当前条件过窄，已优先推荐营业中的选择" };
  return { options: diningDataV2, notice: "当前样本里没有营业中的选择，已展示全部数据" };
}

function matchesLongPrefsV2(item) {
  return matchesBudgetV2(item) && matchesDistanceV2(item) && matchesSpiceV2(item);
}

function matchesBudgetV2(item) {
  if (stateV2.budget === "all") return true;
  if (stateV2.budget === "under10") return avgPriceV2(item) <= 10;
  if (stateV2.budget === "under20") return avgPriceV2(item) <= 20;
  if (stateV2.budget === "under30") return avgPriceV2(item) <= 30;
  return avgPriceV2(item) > 30;
}

function matchesDistanceV2(item) {
  const limits = { all: Infinity, near: 0.5, walkable: 1, town: 2 };
  return distanceKmV2(item) <= limits[stateV2.distance];
}

function matchesSpiceV2(item) {
  return !stateV2.avoidSpicy || item.spice !== "yes";
}

function matchesTypeV2(item) {
  return matchesTypeValueV2(item, stateV2.type);
}

function matchesTypeValueV2(item, type) {
  const text = searchTextV2(item);
  if (type === "random") return true;
  if (type === "noodles") return /粉|面|拉面|米粉|汤粉/.test(text);
  if (type === "rice") return /饭|快餐|盖饭|蒸菜|木桶/.test(text);
  if (type === "snack") return /小吃|炸串|烧烤|茶饮|果汁/.test(text);
  if (type === "light") return /轻食|少油|低脂|控卡|低油|蔬菜多|清淡/.test(text);
  if (type === "midnight") return /夜宵|烧烤|炸串|粥/.test(text) || closesLateV2(item);
  return true;
}

function matchesTasteV2(item) {
  const text = searchTextV2(item);
  if (stateV2.taste === "normal") return true;
  if (stateV2.taste === "light") return item.spice !== "yes" && /清淡|少油|低脂|控卡|低油|轻食|蔬菜/.test(text);
  if (stateV2.taste === "spicy") return item.spice !== "no";
  if (stateV2.taste === "heavy") return item.spice === "yes" || /重口味|香锅|烧烤|湘菜/.test(text);
  return true;
}

function scoreV2(item) {
  let value = 78 - Math.round(distanceKmV2(item) * 8) - Math.floor(avgPriceV2(item) / 3);
  if (isOpenNowV2(item)) value += 12;
  if (stateV2.favorites.has(item.id)) value += 7;
  if (matchesTypeV2(item)) value += 16;
  if (matchesTasteV2(item)) value += 9;
  if (matchesLongPrefsV2(item)) value += 12;
  if (stateV2.need === "fast" && item.speed === "快") value += 18;
  if (stateV2.need === "nearby" && distanceKmV2(item) <= 0.5) value += 22;
  if (stateV2.need === "filling") value += tagScoreV2(item, ["饱腹", "高蛋白", "主食稳定"]);
  if (stateV2.need === "treat") value += tagScoreV2(item, ["聚餐", "夜宵", "现炒", "重口味"]);
  if (stateV2.people === "many") value += tagScoreV2(item, ["聚餐", "多人用餐"]);
  if (stateV2.mealMode === "takeout" && item.speed === "快") value += 8;
  if (stateV2.mealMode === "delivery" && distanceKmV2(item) <= 1.2) value += 8;
  return Math.max(55, Math.min(99, value));
}

function tagScoreV2(item, keywords) {
  return allTagsV2(item).reduce((total, tag) => total + (keywords.some((keyword) => tag.includes(keyword)) ? 6 : 0), 0);
}

function renderResultV2() {
  if (!stateV2.result) return;
  const main = stateV2.result.main;
  resultCardV2.classList.add("show");
  document.querySelector("#resultName").textContent = main.name;
  document.querySelector("#resultSummary").textContent = `${main.category} · ${spiceTextV2(main)} · ${openStatusTextV2(main)} · ${dataSourceTextV2(main)}`;
  document.querySelector("#resultHours").textContent = `营业：${businessHoursV2(main)} · ${main.businessArea || "安沙校区周边"}`;
  document.querySelector("#price").textContent = `¥${avgPriceV2(main)}`;
  document.querySelector("#distance").textContent = walkingTextV2(main);
  document.querySelector("#spiceValue").textContent = spiceTextV2(main);
  document.querySelector("#speed").textContent = main.wait;
  const notice = document.querySelector("#notice");
  notice.textContent = stateV2.result.notice || "";
  notice.classList.toggle("show", Boolean(stateV2.result.notice));
  document.querySelector("#healthTags").innerHTML = allTagsV2(main).slice(0, 6).map((tag) => `<span class="health-tag">${tag}</span>`).join("");
  document.querySelector("#reasons").innerHTML = buildReasonsV2(main).map((reason) => `<div class="reason">${reason}</div>`).join("");
  document.querySelector("#alternatives").innerHTML = stateV2.result.alternatives.map((item) => `<button class="shop" data-alt-id="${item.id}"><span>${item.name}<small>${item.category} · ¥${avgPriceV2(item)} · ${walkingTextV2(item)} · ${spiceTextV2(item)}</small></span><span>${item.wait}</span></button>`).join("");
  document.querySelector("#alternatives").querySelectorAll("[data-alt-id]").forEach((button) => {
    button.addEventListener("click", () => {
      const item = diningDataV2.find((target) => target.id === button.dataset.altId);
      if (!item) return;
      stateV2.result = buildManualRecommendationV2(item, "已切换到这个选择");
      renderResultV2();
    });
  });
  const favoriteButton = document.querySelector("#favoriteButton");
  favoriteButton.textContent = stateV2.favorites.has(main.id) ? "♥" : "♡";
  favoriteButton.setAttribute("aria-label", stateV2.favorites.has(main.id) ? "取消收藏" : "收藏推荐");
  renderFavoritesV2();
  renderMineV2();
}

function buildReasonsV2(item) {
  const reasons = [];
  if (stateV2.type !== "random") reasons.push(`符合你今天选择的「${labelsV2.type[stateV2.type]}」`);
  reasons.push(`匹配「${labelsV2.need[stateV2.need]}」「${labelsV2.people[stateV2.people]}」`);
  if (matchesDistanceV2(item)) reasons.push(`默认距离内：${walkingTextV2(item)}，约 ${distanceTextV2(item)}`);
  if (matchesBudgetV2(item)) reasons.push(`默认预算内：人均约 ${avgPriceV2(item)} 元`);
  if (item.speed === "快") reasons.push(`出餐快：约 ${item.wait}`);
  if (item.source === "amap") reasons.push("店名、地址、距离来自高德 POI，自有标签负责口味匹配");
  if (stateV2.avoidSpicy && item.spice !== "yes") reasons.push(item.spice === "no" ? "长期偏好：不辣" : "长期偏好：可选少辣");
  return reasons.slice(0, 4);
}

function renderFavoritesV2() {
  document.querySelectorAll("[data-favorite-filter]").forEach((button) => {
    button.classList.toggle("active", button.dataset.favoriteFilter === stateV2.favoriteFilter);
  });
  const list = document.querySelector("#favoritesList");
  const favorites = diningDataV2.filter((item) => stateV2.favorites.has(item.id)).filter(matchesFavoriteFilterV2);
  if (favorites.length === 0) {
    list.innerHTML = `<p class="empty">还没有符合当前筛选的收藏。翻牌后点击右上角的“♡”，收藏会进入这里。</p>`;
    return;
  }
  list.innerHTML = favorites.map((item) => `
    <article class="favorite-item">
      <div class="favorite-main">
        <div>
          <strong>${item.name}</strong>
          <small>¥${avgPriceV2(item)} · ${walkingTextV2(item)} · ${item.wait} · ${spiceTextV2(item)}</small>
        </div>
        <button class="favorite-toggle" data-remove-favorite="${item.id}" aria-label="取消收藏">♥</button>
      </div>
      <div class="mini-actions">
        <button class="mini-action" data-detail-id="${item.id}">详情</button>
        <button class="mini-action" data-similar-id="${item.id}">相似</button>
        <button class="mini-action" data-remove-favorite="${item.id}">取消</button>
      </div>
    </article>`).join("");
  list.querySelectorAll("[data-remove-favorite]").forEach((button) => {
    button.addEventListener("click", () => removeFavoriteV2(button.dataset.removeFavorite));
  });
  list.querySelectorAll("[data-detail-id]").forEach((button) => {
    button.addEventListener("click", () => {
      const item = diningDataV2.find((target) => target.id === button.dataset.detailId);
      if (item) openDetailV2(item);
    });
  });
  list.querySelectorAll("[data-similar-id]").forEach((button) => {
    button.addEventListener("click", () => recommendSimilarV2(button.dataset.similarId));
  });
}

function matchesFavoriteFilterV2(item) {
  if (stateV2.favoriteFilter === "near") return distanceKmV2(item) <= 1;
  if (stateV2.favoriteFilter === "under20") return avgPriceV2(item) <= 20;
  if (stateV2.favoriteFilter === "noodles") return matchesTypeValueV2(item, "noodles");
  if (stateV2.favoriteFilter === "light") return matchesTypeValueV2(item, "light");
  return true;
}

function toggleCurrentFavoriteV2() {
  if (!stateV2.result) return;
  const id = stateV2.result.main.id;
  if (stateV2.favorites.has(id)) {
    stateV2.favorites.delete(id);
    showToastV2("已取消收藏");
  } else {
    stateV2.favorites.add(id);
    showToastV2("已加入收藏，可在「收藏」中查看");
  }
  renderResultV2();
}

function removeFavoriteV2(id) {
  stateV2.favorites.delete(id);
  renderAllV2();
  showToastV2("已取消收藏");
}

function recommendSimilarV2(id) {
  const item = diningDataV2.find((target) => target.id === id);
  if (!item) return;
  stateV2.type = inferTypeV2(item);
  stateV2.result = buildManualRecommendationV2(item, "已按收藏内容推荐相似餐厅");
  renderAllV2();
  renderResultV2();
  setTabV2("eat");
  flipCardV2.classList.add("flipped");
}

function buildManualRecommendationV2(item, notice) {
  const type = inferTypeV2(item);
  return {
    main: item,
    alternatives: diningDataV2.filter((target) => target.id !== item.id && matchesTypeValueV2(target, type)).slice(0, 3),
    notice
  };
}

function inferTypeV2(item) {
  if (matchesTypeValueV2(item, "noodles")) return "noodles";
  if (matchesTypeValueV2(item, "rice")) return "rice";
  if (matchesTypeValueV2(item, "light")) return "light";
  if (matchesTypeValueV2(item, "midnight")) return "midnight";
  if (matchesTypeValueV2(item, "snack")) return "snack";
  return "random";
}

function openDetailV2(item) {
  document.querySelector("#detailContent").innerHTML = `
    <div class="list-item">
      <strong>${item.name}</strong>
      <small>${item.category} · ¥${avgPriceV2(item)} · ${walkingTextV2(item)} · ${spiceTextV2(item)}</small>
      <small>地址：${item.address}</small>
      <small>高德 POI：${item.sourcePoiId}；评分：${ratingTextV2(item)}</small>
      <small>健康/环境标签：${allTagsV2(item).join(" / ")}</small>
      <small>出餐速度：${item.wait}；营业时段：${businessHoursV2(item)}</small>
      <small>字段来源：店名、地址、距离、评分、人均优先来自高德；辣度、健康标签、出餐速度由 App 自维护。</small>
    </div>`;
  openSheetV2("detailSheet");
}

function openRouteV2(item) {
  renderRouteV2(item, "正在准备步行路线");
  openSheetV2("routeSheet");
  refreshRouteFromAmapV2(item);
}

function renderRouteV2(item, statusText) {
  document.querySelector("#routeContent").innerHTML = `
    <div class="list-item">
      <strong>去这里：${item.name}</strong>
      <small>起点：${schoolLocationV2.name}</small>
      <small>终点：${item.address}</small>
      <small>步行距离：${distanceTextV2(item)}；预计 ${walkingTextV2(item).replace("步行约", "")}</small>
      <small>导航目的地：${item.naviPoiId || item.sourcePoiId}</small>
      <small>后端接口：GET /api/route/walking?fromLng=${schoolLocationV2.lng}&fromLat=${schoolLocationV2.lat}&toLng=${item.longitude}&toLat=${item.latitude}</small>
      <small>${statusText}</small>
    </div>
    ${item.routeSteps.map((step, index) => `<div class="history-item">${index + 1}. ${step}</div>`).join("")}`;
}

async function refreshRouteFromAmapV2(item) {
  if (!item.longitude || !item.latitude) return;
  try {
    const route = await fetchJsonV2("/api/route/walking", {
      fromLng: schoolLocationV2.lng,
      fromLat: schoolLocationV2.lat,
      toLng: item.longitude,
      toLat: item.latitude
    });
    if (!route || (!route.walkingMinutes && !route.distanceMeters)) return;
    item.distanceMeters = route.distanceMeters || item.distanceMeters;
    item.walkingMinutes = route.walkingMinutes || item.walkingMinutes;
    item.routeSteps = route.steps && route.steps.length ? route.steps : item.routeSteps;
    renderRouteV2(item, "已同步高德步行路线");
  } catch (error) {
    renderRouteV2(item, "暂时无法连接高德路线，已显示本地估算路线");
  }
}

function addHistoryV2(item) {
  stateV2.history.unshift(`${item.name} · ${labelsV2.type[stateV2.type]} · ${labelsV2.need[stateV2.need]}`);
  stateV2.history = stateV2.history.slice(0, 4);
  renderMineV2();
}

function renderMineV2() {
  document.querySelector("#mineBudget").textContent = labelsV2.budget[stateV2.budget];
  document.querySelector("#mineDistance").textContent = labelsV2.distance[stateV2.distance];
  document.querySelector("#mineTaste").textContent = `${stateV2.avoidSpicy ? "不吃重辣" : "可吃辣"} / 少油优先`;
  document.querySelector("#mineFavoriteCount").textContent = `${stateV2.favorites.size} 个`;
  const historyList = document.querySelector("#historyList");
  historyList.innerHTML = stateV2.history.length === 0
    ? `<p class="empty">最近翻牌和最近吃过会显示在这里。</p>`
    : stateV2.history.map((item) => `<div class="history-item">${item}</div>`).join("");
}

function renderAllV2() {
  document.querySelectorAll("[data-group]").forEach((group) => {
    const value = stateV2[group.dataset.group];
    group.querySelectorAll("[data-value]").forEach((button) => {
      button.classList.toggle("active", button.dataset.value === String(value));
    });
  });
  document.querySelector("#spiceSwitch").classList.toggle("off", !stateV2.avoidSpicy);
  document.querySelector("#todaySummary").textContent = `${labelsV2.people[stateV2.people]} · ${labelsV2.type[stateV2.type]} · ${labelsV2.taste[stateV2.taste]} · ${labelsV2.need[stateV2.need]} · ${labelsV2.mealMode[stateV2.mealMode]}`;
  renderFavoritesV2();
  renderMineV2();
}

async function loadNearbyPlacesV2() {
  try {
    const data = await fetchJsonV2("/api/food/nearby", {
      lng: schoolLocationV2.lng,
      lat: schoolLocationV2.lat,
      radius: 1500
    });
    const remotePlaces = (data.places || []).map(normalizeRemotePlaceV2).filter(Boolean);
    if (remotePlaces.length === 0) return;
    const campusPlaces = manualFallbackDataV2.filter((item) => item.source === "manual");
    const merged = dedupePlacesV2([...campusPlaces, ...remotePlaces]);
    diningDataV2.splice(0, diningDataV2.length, ...merged);
    stateV2.result = null;
    stateV2.shownIds = [];
    flipCardV2.classList.remove("flipped");
    renderAllV2();
    showToastV2(`已同步 ${remotePlaces.length} 家高德周边餐饮`);
  } catch (error) {
    // 静态打开或后端未启动时保留本地样本，不打断翻牌体验。
  }
}

function normalizeRemotePlaceV2(place) {
  if (!place || !place.name) return null;
  const price = Number(place.avgPrice || place.amapCost || place.price || 20);
  const distanceMeters = Number(place.distanceMeters || 0);
  return {
    id: place.id || `amap-${place.sourcePoiId}`,
    name: place.name,
    category: place.category || "餐饮/简餐",
    price,
    distance: distanceMeters ? distanceMeters / 1000 : 1,
    spice: spiceFromRemoteV2(place.spicyLevel),
    tags: place.healthTags && place.healthTags.length ? place.healthTags : ["餐饮服务"],
    speed: place.speedLevel || "中",
    wait: place.speedText || "8-15分钟",
    hours: place.businessHours || place.amapTodayOpenTime || "营业时间待确认",
    source: "amap",
    sourcePoiId: place.sourcePoiId,
    address: place.address || "地址待确认",
    longitude: place.entranceLongitude || place.longitude,
    latitude: place.entranceLatitude || place.latitude,
    amapRating: place.amapRating,
    amapCost: place.amapCost || price,
    amapTags: place.amapTags || [],
    amapTodayOpenTime: place.amapTodayOpenTime,
    amapWeekOpenTime: place.amapWeekOpenTime,
    tel: place.tel,
    photoUrl: place.photoUrl,
    businessArea: place.businessArea,
    distanceMeters,
    walkingMinutes: place.walkingMinutes,
    entranceLongitude: place.entranceLongitude,
    entranceLatitude: place.entranceLatitude,
    naviPoiId: place.naviPoiId || place.sourcePoiId,
    environmentTags: place.environmentTags || [],
    suitableScenes: place.suitableScenes || [],
    routeSteps: place.routeSteps || ["从校门口出发", "按高德步行路线前往店铺"]
  };
}

function spiceFromRemoteV2(value) {
  if (value === "不辣") return "no";
  if (value === "辣" || value === "重辣") return "yes";
  return "optional";
}

function dedupePlacesV2(places) {
  const seen = new Set();
  return places.filter((place) => {
    const key = place.sourcePoiId || `${place.name}-${place.address}`;
    if (seen.has(key)) return false;
    seen.add(key);
    return true;
  });
}

async function fetchJsonV2(path, params) {
  const url = new URL(path, apiBaseV2 || window.location.origin);
  Object.entries(params || {}).forEach(([key, value]) => url.searchParams.set(key, value));
  const response = await fetch(url.toString(), { headers: { Accept: "application/json" } });
  const data = await response.json();
  if (!response.ok || data.ok === false) {
    throw new Error(data.error || `请求失败：${response.status}`);
  }
  return data;
}

function isOpenNowV2(item) {
  const now = minutesFromTextV2(currentTimeV2);
  const hours = businessHoursV2(item);
  if (!/\d{1,2}:\d{2}/.test(hours)) return true;
  return hours.split("/").some((period) => {
    const parts = period.trim().split("-");
    if (parts.length !== 2) return false;
    const start = minutesFromTextV2(parts[0]);
    const end = minutesFromTextV2(parts[1]);
    if (end < start) return now >= start || now <= end;
    return now >= start && now <= end;
  });
}

function closesLateV2(item) {
  return businessHoursV2(item).split("/").some((period) => {
    const parts = period.trim().split("-");
    if (parts.length !== 2) return false;
    const start = minutesFromTextV2(parts[0]);
    const end = minutesFromTextV2(parts[1]);
    return end >= 22 * 60 || end < start;
  });
}

function minutesFromTextV2(text) {
  const [hour, minute] = text.trim().split(":").map(Number);
  return hour * 60 + minute;
}

function distanceTextV2(item) {
  const meters = distanceMetersV2(item);
  return meters < 1000 ? `${meters}m` : `${(meters / 1000).toFixed(1)}km`;
}

function distanceMetersV2(item) {
  return item.distanceMeters || Math.round(item.distance * 1000);
}

function distanceKmV2(item) {
  return distanceMetersV2(item) / 1000;
}

function avgPriceV2(item) {
  return Number(item.amapCost || item.price);
}

function businessHoursV2(item) {
  return item.businessHours || item.amapTodayOpenTime || item.hours || "营业时间待确认";
}

function walkingTextV2(item) {
  return item.walkingMinutes ? `步行约${item.walkingMinutes}分钟` : distanceTextV2(item);
}

function allTagsV2(item) {
  return [...new Set([...(item.tags || []), ...(item.amapTags || []), ...(item.environmentTags || [])])];
}

function searchTextV2(item) {
  return `${item.name} ${item.category} ${allTagsV2(item).join(" ")}`;
}

function ratingTextV2(item) {
  return item.amapRating ? `${item.amapRating.toFixed(1)} 分` : "暂无评分";
}

function dataSourceTextV2(item) {
  return item.source === "amap" ? "高德 POI" : "校内维护";
}

function spiceTextV2(item) {
  if (item.spice === "no") return "不辣";
  if (item.spice === "optional") return "可少辣";
  return "偏辣";
}

function openStatusTextV2(item) {
  return isOpenNowV2(item) ? "营业中" : "未营业";
}

function appendNoticeV2(left, right) {
  return left ? `${left}；${right}` : right;
}

function showToastV2(message) {
  toastV2.textContent = message;
  toastV2.classList.add("show");
  window.clearTimeout(showToastV2.timer);
  showToastV2.timer = window.setTimeout(() => toastV2.classList.remove("show"), 1800);
}

renderAllV2();
loadNearbyPlacesV2();
