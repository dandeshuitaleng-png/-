const http = require("node:http");
const fs = require("node:fs");
const path = require("node:path");
const { URL } = require("node:url");

const rootDir = __dirname;
const port = Number(process.env.PORT || 8787);

loadEnvFile(path.join(rootDir, ".env.local"));

const amapKey = process.env.AMAP_WEB_KEY;
const amapJsKey = process.env.AMAP_JS_KEY;
const amapJsSecurityCode = process.env.AMAP_JS_SECURITY_CODE;
const defaultLocation = {
  lng: 113.0826,
  lat: 28.3538,
  address: "长沙市长沙县安沙镇万花园路9号"
};

const server = http.createServer(async (req, res) => {
  try {
    const url = new URL(req.url, `http://${req.headers.host || "127.0.0.1"}`);

    if (req.method === "OPTIONS") {
      sendEmpty(res, 204);
      return;
    }

    if (url.pathname === "/favicon.ico") {
      sendEmpty(res, 204);
      return;
    }

    if (url.pathname === "/api/health") {
      sendJson(res, 200, {
        ok: true,
        hasAmapKey: Boolean(amapKey),
        hasAmapJsConfig: Boolean(amapJsKey && amapJsSecurityCode)
      });
      return;
    }

    if (url.pathname === "/api/map/config") {
      const configured = Boolean(amapJsKey && amapJsSecurityCode);
      sendJson(res, 200, {
        provider: "amap",
        configured,
        key: configured ? amapJsKey : "",
        securityJsCode: configured ? amapJsSecurityCode : ""
      });
      return;
    }

    if (url.pathname === "/api/food/nearby") {
      assertAmapKey();
      const lng = numberOr(url.searchParams.get("lng"), defaultLocation.lng);
      const lat = numberOr(url.searchParams.get("lat"), defaultLocation.lat);
      const radius = numberOr(url.searchParams.get("radius"), 1500);
      const raw = await amapGet("/v5/place/around", {
        location: `${lng},${lat}`,
        radius,
        types: "050000",
        sortrule: "distance",
        show_fields: "business,navi,photos",
        page_size: 20,
        page_num: 1
      });
      const places = normalizeAmapPlaces(raw.pois || raw.data?.pois || []);
      sendJson(res, 200, { places, source: "amap", center: { lng, lat }, count: places.length });
      return;
    }

    if (url.pathname === "/api/route/walking") {
      assertAmapKey();
      const fromLng = requireNumber(url.searchParams.get("fromLng"), "fromLng");
      const fromLat = requireNumber(url.searchParams.get("fromLat"), "fromLat");
      const toLng = requireNumber(url.searchParams.get("toLng"), "toLng");
      const toLat = requireNumber(url.searchParams.get("toLat"), "toLat");
      const raw = await amapGet("/v3/direction/walking", {
        origin: `${fromLng},${fromLat}`,
        destination: `${toLng},${toLat}`,
        output: "JSON"
      });
      sendJson(res, 200, normalizeWalkingRoute(raw));
      return;
    }

    if (url.pathname === "/api/place/search") {
      assertAmapKey();
      const keywords = String(url.searchParams.get("keywords") || "").trim();
      if (!keywords) {
        const error = new Error("请输入地址或地点名称");
        error.statusCode = 400;
        throw error;
      }
      const region = String(url.searchParams.get("region") || "长沙市").trim();
      const raw = await amapGet("/v5/place/text", {
        keywords,
        region,
        city_limit: false,
        show_fields: "business,navi,photos",
        page_size: 10,
        page_num: 1
      });
      const places = normalizeAmapPlaces(raw.pois || raw.data?.pois || []);
      sendJson(res, 200, { places, source: "amap", count: places.length });
      return;
    }

    serveStatic(url.pathname, res);
  } catch (error) {
    sendJson(res, error.statusCode || 500, {
      ok: false,
      error: error.publicMessage || error.message || "服务异常"
    });
  }
});

server.listen(port, "127.0.0.1", () => {
  console.log(`EatWhat prototype running at http://127.0.0.1:${port}`);
});

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const lines = fs.readFileSync(filePath, "utf8").split(/\r?\n/);
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("#")) continue;
    const index = trimmed.indexOf("=");
    if (index === -1) continue;
    const key = trimmed.slice(0, index).trim();
    const value = trimmed.slice(index + 1).trim();
    if (key && process.env[key] === undefined) {
      process.env[key] = value.replace(/^["']|["']$/g, "");
    }
  }
}

function assertAmapKey() {
  if (!amapKey) {
    const error = new Error("缺少 AMAP_WEB_KEY，请在 .env.local 中配置高德 Web 服务 Key");
    error.statusCode = 500;
    error.publicMessage = "高德 Key 未配置";
    throw error;
  }
}

async function amapGet(pathname, params) {
  const target = new URL(`https://restapi.amap.com${pathname}`);
  target.searchParams.set("key", amapKey);
  for (const [key, value] of Object.entries(params)) {
    target.searchParams.set(key, String(value));
  }
  const response = await fetch(target, { headers: { Accept: "application/json" } });
  if (!response.ok) {
    const error = new Error(`高德接口 HTTP ${response.status}`);
    error.statusCode = 502;
    throw error;
  }
  const data = await response.json();
  if (data.status && data.status !== "1") {
    const error = new Error(data.info || "高德接口返回失败");
    error.statusCode = 502;
    error.publicMessage = data.info || "高德接口返回失败";
    throw error;
  }
  return data;
}

function normalizeAmapPlaces(pois) {
  const seen = new Set();
  return pois
    .filter((poi) => poi && poi.id && poi.name && poi.location)
    .map(normalizeAmapPlace)
    .filter((place) => {
      const key = place.sourcePoiId || `${place.name}-${place.address}`;
      if (seen.has(key)) return false;
      seen.add(key);
      return true;
    });
}

function normalizeAmapPlace(poi) {
  const business = poi.business || {};
  const navi = poi.navi || {};
  const [longitude, latitude] = parseLocation(poi.location);
  const distanceMeters = numberOr(poi.distance, 0);
  const amapTags = splitTags(business.tag || poi.tag);
  const typeRaw = poi.type || "";
  const category = inferCategory(typeRaw, poi.name, amapTags);
  const avgPrice = numberOr(business.cost, estimatePrice(category, poi.name));
  const spicyLevel = inferSpicyLevel(category, poi.name, amapTags);
  const speedLevel = inferSpeedLevel(category, poi.name);

  return {
    id: `amap-${poi.id}`,
    source: "amap",
    sourcePoiId: poi.id,
    name: poi.name,
    address: stringifyAddress(poi.address),
    longitude,
    latitude,
    province: poi.pname,
    city: poi.cityname,
    district: poi.adname,
    adcode: poi.adcode,
    citycode: poi.citycode,
    typeRaw,
    typecode: poi.typecode,
    amapRating: numberOrNull(business.rating),
    amapCost: numberOrNull(business.cost),
    amapTags,
    amapTodayOpenTime: business.opentime_today,
    amapWeekOpenTime: business.opentime_week,
    tel: business.tel,
    photoUrl: firstPhotoUrl(poi.photos),
    businessArea: business.business_area,
    distanceMeters,
    walkingMinutes: estimateWalkingMinutes(distanceMeters),
    entranceLongitude: parseLocation(navi.entr_location)[0],
    entranceLatitude: parseLocation(navi.entr_location)[1],
    naviPoiId: navi.navi_poiid || poi.id,
    category,
    avgPrice,
    spicyLevel,
    healthTags: inferHealthTags(category, poi.name, amapTags),
    speedLevel,
    speedText: speedText(speedLevel),
    environmentTags: inferEnvironmentTags(business.business_area, category),
    suitableScenes: inferScenes(category, spicyLevel, speedLevel),
    businessHours: business.opentime_today || business.opentime_week || "营业时间待确认",
    routeSteps: ["从校门口出发", "按高德步行路线前往店铺"]
  };
}

function normalizeWalkingRoute(raw) {
  const pathData = raw.route?.paths?.[0] || {};
  const distanceMeters = numberOr(pathData.distance, 0);
  const durationSeconds = numberOr(pathData.duration, 0);
  return {
    distanceMeters,
    durationSeconds,
    walkingMinutes: Math.max(1, Math.ceil(durationSeconds / 60)),
    steps: (pathData.steps || []).map((step) => step.instruction).filter(Boolean)
  };
}

function inferCategory(typeRaw, name, tags) {
  const text = `${typeRaw} ${name} ${tags.join(" ")}`;
  if (/冷饮|茶饮|奶茶|果饮/.test(text)) return "茶饮/果饮";
  if (/咖啡|轻食|三明治|沙拉/.test(text)) return "咖啡/轻食";
  if (/烧烤|烤肉|夜宵/.test(text)) return "烧烤/夜宵";
  if (/粉|面|米线|小吃快餐/.test(text)) return "小吃/粉面";
  if (/快餐|盖饭|木桶饭|煲仔饭/.test(text)) return "快餐/盖饭";
  if (/外国|西餐|韩式|日式/.test(text)) return "韩式/西式/其他";
  if (/中餐|湘菜|炒菜|家常菜/.test(text)) return "湘菜/家常菜";
  return "餐饮/简餐";
}

function inferSpicyLevel(category, name, tags) {
  const text = `${category} ${name} ${tags.join(" ")}`;
  if (/麻辣|香锅|湘菜|烧烤|辣/.test(text)) return "辣";
  if (/茶饮|轻食|沙拉|三明治|水饺|咖啡/.test(text)) return "不辣";
  return "可选";
}

function inferHealthTags(category, name, tags) {
  const text = `${category} ${name} ${tags.join(" ")}`;
  const result = [];
  if (/轻食|沙拉|三明治|咖啡/.test(text)) result.push("低油", "轻食");
  if (/粉|面|汤|水饺/.test(text)) result.push("主食稳定");
  if (/盖饭|木桶饭|快餐|中餐|湘菜/.test(text)) result.push("饱腹");
  if (/鸡|牛|肉|蛋|豆/.test(text)) result.push("高蛋白");
  if (result.length === 0) result.push("餐饮服务");
  return [...new Set(result)].slice(0, 4);
}

function inferSpeedLevel(category, name) {
  const text = `${category} ${name}`;
  if (/茶饮|粉|面|小吃|快餐/.test(text)) return "快";
  if (/炒菜|中餐|烧烤|香锅/.test(text)) return "中";
  return "中";
}

function speedText(level) {
  if (level === "快") return "5-8分钟";
  if (level === "慢") return "15-25分钟";
  return "8-15分钟";
}

function inferEnvironmentTags(businessArea, category) {
  const tags = [];
  if (businessArea) tags.push(businessArea);
  if (/茶饮|小吃|粉面|快餐/.test(category)) tags.push("适合学生日常");
  if (/烧烤|夜宵/.test(category)) tags.push("夜宵");
  if (/湘菜|家常菜/.test(category)) tags.push("适合多人");
  return [...new Set(tags)].slice(0, 3);
}

function inferScenes(category, spicyLevel, speedLevel) {
  const scenes = [];
  if (speedLevel === "快") scenes.push("赶时间");
  if (/快餐|盖饭|粉面/.test(category)) scenes.push("想吃饱");
  if (/茶饮|轻食/.test(category)) scenes.push("清淡");
  if (spicyLevel === "辣") scenes.push("想吃辣");
  return [...new Set(scenes)];
}

function estimatePrice(category, name) {
  const text = `${category} ${name}`;
  if (/茶饮/.test(text)) return 12;
  if (/粉|面|小吃/.test(text)) return 14;
  if (/快餐|盖饭/.test(text)) return 18;
  if (/湘菜|家常菜|烧烤/.test(text)) return 30;
  return 20;
}

function estimateWalkingMinutes(distanceMeters) {
  if (!distanceMeters) return undefined;
  return Math.max(2, Math.ceil(distanceMeters / 80));
}

function splitTags(value) {
  if (!value || Array.isArray(value)) return Array.isArray(value) ? value : [];
  return String(value).split(/[;,，、\s]+/).map((tag) => tag.trim()).filter(Boolean);
}

function parseLocation(location) {
  if (!location || typeof location !== "string") return [undefined, undefined];
  const [lng, lat] = location.split(",").map(Number);
  return [Number.isFinite(lng) ? lng : undefined, Number.isFinite(lat) ? lat : undefined];
}

function firstPhotoUrl(photos) {
  return Array.isArray(photos) && photos[0] ? photos[0].url : undefined;
}

function stringifyAddress(address) {
  if (Array.isArray(address)) return address.filter(Boolean).join("");
  return address || "";
}

function numberOr(value, fallback) {
  const number = Number(value);
  return Number.isFinite(number) ? number : fallback;
}

function numberOrNull(value) {
  const number = Number(value);
  return Number.isFinite(number) ? number : undefined;
}

function requireNumber(value, name) {
  const number = Number(value);
  if (!Number.isFinite(number)) {
    const error = new Error(`缺少或错误的参数：${name}`);
    error.statusCode = 400;
    throw error;
  }
  return number;
}

function serveStatic(pathname, res) {
  const safePath = pathname === "/" ? "/index.html" : pathname;
  const filePath = path.normalize(path.join(rootDir, decodeURIComponent(safePath)));
  if (!filePath.startsWith(rootDir)) {
    sendEmpty(res, 403);
    return;
  }
  fs.readFile(filePath, (error, data) => {
    if (error) {
      sendEmpty(res, 404);
      return;
    }
    res.writeHead(200, {
      "Content-Type": contentType(filePath),
      "Cache-Control": "no-store",
      "Access-Control-Allow-Origin": "*"
    });
    res.end(data);
  });
}

function contentType(filePath) {
  if (filePath.endsWith(".html")) return "text/html; charset=utf-8";
  if (filePath.endsWith(".js")) return "text/javascript; charset=utf-8";
  if (filePath.endsWith(".css")) return "text/css; charset=utf-8";
  if (filePath.endsWith(".json")) return "application/json; charset=utf-8";
  return "application/octet-stream";
}

function sendJson(res, statusCode, data) {
  res.writeHead(statusCode, {
    "Content-Type": "application/json; charset=utf-8",
    "Cache-Control": "no-store",
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  });
  res.end(JSON.stringify(data));
}

function sendEmpty(res, statusCode) {
  res.writeHead(statusCode, {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Methods": "GET,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type"
  });
  res.end();
}
