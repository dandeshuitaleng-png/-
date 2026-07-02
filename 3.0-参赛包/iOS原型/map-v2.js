(() => {
  const elements = {
    canvas: document.querySelector("#mapCanvas"),
    status: document.querySelector("#mapStatus"),
    loading: document.querySelector("#mapLoadingState"),
    error: document.querySelector("#mapErrorState"),
    errorTitle: document.querySelector("#mapErrorTitle"),
    errorCopy: document.querySelector("#mapErrorCopy"),
    permission: document.querySelector("#mapPermissionState"),
    permissionCopy: document.querySelector("#mapPermissionCopy"),
    retry: document.querySelector("#mapRetryButton"),
    permissionRetry: document.querySelector("#mapPermissionRetryButton"),
    useCampus: document.querySelector("#mapUseCampusButton"),
    relocate: document.querySelector("#mapRelocateButton"),
    searchForm: document.querySelector("#mapSearchForm"),
    searchInput: document.querySelector("#mapSearchInput"),
    summary: document.querySelector("#mapSummary"),
    card: document.querySelector("#mapPlaceCard"),
    cardClose: document.querySelector("#mapCardCloseButton"),
    placeStatus: document.querySelector("#mapPlaceStatus"),
    placeName: document.querySelector("#mapPlaceName"),
    placeAddress: document.querySelector("#mapPlaceAddress"),
    placeDistance: document.querySelector("#mapPlaceDistance"),
    placePrice: document.querySelector("#mapPlacePrice"),
    placeCategory: document.querySelector("#mapPlaceCategory"),
    go: document.querySelector("#mapGoButton")
  };

  const mapState = {
    map: null,
    currentMarker: null,
    placeMarkers: [],
    places: [],
    selectedPlace: null,
    center: currentCenter(),
    initializePromise: null,
    sdkPromise: null
  };

  elements.retry.addEventListener("click", retryMap);
  elements.permissionRetry.addEventListener("click", requestUserLocation);
  elements.useCampus.addEventListener("click", useCampusLocation);
  elements.relocate.addEventListener("click", requestUserLocation);
  elements.searchForm.addEventListener("submit", searchAddress);
  elements.cardClose.addEventListener("click", closePlaceCard);
  elements.go.addEventListener("click", () => {
    if (!mapState.selectedPlace) return;
    if (typeof openRouteV2 === "function") openRouteV2(mapState.selectedPlace);
  });

  window.NearBiteMap = { activate };

  async function activate() {
    if (mapState.map) {
      window.setTimeout(() => mapState.map.resize(), 0);
      return;
    }
    await initializeMap();
  }

  async function initializeMap() {
    if (mapState.initializePromise) return mapState.initializePromise;
    mapState.initializePromise = (async () => {
      showState("loading");
      setStatus("正在加载地图");
      try {
        const config = await fetchMapJson("/api/map/config");
        if (!config.configured) {
          const error = new Error("需要配置高德 JS API Key 和 securityJsCode 后才能加载交互地图。");
          error.code = "MAP_CONFIG_MISSING";
          throw error;
        }
        await loadAmapSdk(config);
        mapState.map = new window.AMap.Map(elements.canvas, {
          center: [mapState.center.lng, mapState.center.lat],
          zoom: 15,
          viewMode: "2D",
          resizeEnable: true
        });
        mapState.map.addControl(new window.AMap.Scale());
        mapState.map.addControl(new window.AMap.ToolBar({ position: "LT" }));
        showState("ready");
        await loadNearbyAt(mapState.center, "当前校园位置");
      } catch (error) {
        const title = error.code === "MAP_CONFIG_MISSING" ? "地图组件待配置" : "地图加载失败";
        showError(title, error.message || "请检查网络后重新加载。");
      } finally {
        mapState.initializePromise = null;
      }
    })();
    return mapState.initializePromise;
  }

  function loadAmapSdk(config) {
    if (window.AMap) return Promise.resolve(window.AMap);
    if (mapState.sdkPromise) return mapState.sdkPromise;
    window._AMapSecurityConfig = { securityJsCode: config.securityJsCode };
    mapState.sdkPromise = new Promise((resolve, reject) => {
      const script = document.createElement("script");
      const timeout = window.setTimeout(() => reject(new Error("高德地图 SDK 加载超时。")), 12000);
      script.src = `https://webapi.amap.com/maps?v=2.0&key=${encodeURIComponent(config.key)}&plugin=AMap.Scale,AMap.ToolBar`;
      script.async = true;
      script.dataset.nearbiteAmap = "true";
      script.onload = () => {
        window.clearTimeout(timeout);
        if (window.AMap) resolve(window.AMap);
        else reject(new Error("高德地图 SDK 初始化失败。"));
      };
      script.onerror = () => {
        window.clearTimeout(timeout);
        reject(new Error("无法连接高德地图 SDK。"));
      };
      document.head.appendChild(script);
    });
    return mapState.sdkPromise;
  }

  async function loadNearbyAt(center, label) {
    if (!mapState.map) return;
    setStatus("正在加载周边餐饮");
    closePlaceCard();
    try {
      const data = await fetchMapJson("/api/food/nearby", {
        lng: center.lng,
        lat: center.lat,
        radius: 1500
      });
      const places = (data.places || []).map(normalizePlace).filter(hasCoordinates);
      mapState.center = center;
      mapState.places = places;
      renderCurrentMarker(center);
      renderPlaceMarkers(places);
      syncRecommendationData(places);
      fitVisibleMarkers();
      setStatus(`${label} · ${places.length} 家餐饮`);
      elements.summary.textContent = places.length
        ? `已加载 ${places.length} 家高德周边餐饮，点击地图标记查看详情。`
        : "当前位置附近暂未找到餐饮，可搜索其他地址。";
      showState("ready");
    } catch (error) {
      showError("周边餐饮加载失败", error.message || "请检查网络后重试。");
    }
  }

  function renderCurrentMarker(center) {
    if (mapState.currentMarker) mapState.map.remove(mapState.currentMarker);
    mapState.currentMarker = new window.AMap.CircleMarker({
      center: [center.lng, center.lat],
      radius: 8,
      strokeColor: "#ffffff",
      strokeWeight: 3,
      fillColor: "#1d8f61",
      fillOpacity: 1,
      zIndex: 120
    });
    mapState.map.add(mapState.currentMarker);
    mapState.map.setCenter([center.lng, center.lat]);
  }

  function renderPlaceMarkers(places) {
    if (mapState.placeMarkers.length) mapState.map.remove(mapState.placeMarkers);
    mapState.placeMarkers = places.map((place) => {
      const marker = new window.AMap.Marker({
        position: [place.longitude, place.latitude],
        title: place.name,
        anchor: "bottom-center"
      });
      marker.on("click", () => selectPlace(place, marker));
      return marker;
    });
    if (mapState.placeMarkers.length) mapState.map.add(mapState.placeMarkers);
  }

  function fitVisibleMarkers() {
    const overlays = [mapState.currentMarker, ...mapState.placeMarkers].filter(Boolean);
    if (overlays.length > 1) {
      mapState.map.setFitView(overlays, false, [56, 44, 190, 44], 16);
    } else {
      mapState.map.setZoomAndCenter(15, [mapState.center.lng, mapState.center.lat]);
    }
  }

  function selectPlace(place, marker) {
    mapState.selectedPlace = place;
    elements.placeStatus.textContent = openText(place);
    elements.placeName.textContent = place.name;
    elements.placeAddress.textContent = place.address || "地址待确认";
    elements.placeDistance.textContent = walkingText(place);
    elements.placePrice.textContent = `人均约 ¥${Math.round(Number(place.price || place.avgPrice || 20))}`;
    elements.placeCategory.textContent = place.category || "餐饮服务";
    elements.card.hidden = false;
    if (marker?.getPosition) mapState.map.panTo(marker.getPosition());
  }

  function closePlaceCard() {
    mapState.selectedPlace = null;
    elements.card.hidden = true;
  }

  async function requestUserLocation() {
    if (!navigator.geolocation) {
      showPermission("当前浏览器不支持系统定位，请使用校园位置或更换浏览器。");
      return;
    }
    elements.relocate.disabled = true;
    setStatus("正在获取当前位置");
    try {
      const position = await new Promise((resolve, reject) => {
        navigator.geolocation.getCurrentPosition(resolve, reject, {
          enableHighAccuracy: true,
          timeout: 10000,
          maximumAge: 30000
        });
      });
      const center = {
        lng: position.coords.longitude,
        lat: position.coords.latitude
      };
      if (typeof schoolLocationV2 !== "undefined") {
        Object.assign(schoolLocationV2, {
          name: "系统定位位置",
          fallbackAddress: "系统定位位置",
          lng: center.lng,
          lat: center.lat
        });
      }
      if (typeof stateV2 !== "undefined") stateV2.currentLocationKey = "system";
      if (typeof renderAllV2 === "function") renderAllV2();
      await loadNearbyAt(center, "当前位置");
    } catch (error) {
      if (error?.code === 1) {
        showPermission("位置权限未开启。请在浏览器站点设置中允许位置权限，然后点击“再次定位”。");
      } else if (error?.code === 3) {
        showError("定位超时", "暂时无法获取当前位置，请检查系统定位服务后重试。");
      } else {
        showError("定位失败", "暂时无法获取当前位置，可先使用校园位置。");
      }
    } finally {
      elements.relocate.disabled = false;
    }
  }

  async function useCampusLocation() {
    showState("ready");
    const center = currentCenter();
    await loadNearbyAt(center, "当前校园位置");
  }

  async function searchAddress(event) {
    event.preventDefault();
    const keywords = elements.searchInput.value.trim();
    if (!keywords) {
      elements.searchInput.focus();
      setStatus("请输入地址或地点名称");
      return;
    }
    if (!mapState.map) {
      showError("地图尚未就绪", "请先完成地图 JS API 配置并重新加载。");
      return;
    }
    setStatus("正在搜索地点");
    try {
      const data = await fetchMapJson("/api/place/search", { keywords, region: "长沙市" });
      const places = (data.places || []).map(normalizePlace).filter(hasCoordinates);
      if (!places.length) {
        setStatus("未找到匹配地点");
        elements.summary.textContent = "换一个更具体的地址或地点名称再试。";
        return;
      }
      mapState.places = places;
      renderPlaceMarkers(places);
      fitVisibleMarkers();
      const firstMarker = mapState.placeMarkers[0];
      selectPlace(places[0], firstMarker);
      setStatus(`找到 ${places.length} 个地点`);
      elements.summary.textContent = `已展示“${keywords}”的搜索结果。`;
      showState("ready");
    } catch (error) {
      showError("地址搜索失败", error.message || "请稍后重试。");
    }
  }

  async function retryMap() {
    if (mapState.map) {
      showState("ready");
      await loadNearbyAt(mapState.center, "当前位置");
      return;
    }
    mapState.sdkPromise = null;
    document.querySelector("script[data-nearbite-amap]")?.remove();
    await initializeMap();
  }

  function showState(state) {
    elements.loading.classList.toggle("show", state === "loading");
    elements.error.classList.toggle("show", state === "error");
    elements.permission.classList.toggle("show", state === "permission");
  }

  function showError(title, copy) {
    elements.errorTitle.textContent = title;
    elements.errorCopy.textContent = copy;
    showState("error");
    setStatus(title);
  }

  function showPermission(copy) {
    elements.permissionCopy.textContent = copy;
    showState("permission");
    setStatus("位置权限未开启");
  }

  function setStatus(text) {
    elements.status.textContent = text;
  }

  function currentCenter() {
    if (typeof schoolLocationV2 !== "undefined") {
      return { lng: schoolLocationV2.lng, lat: schoolLocationV2.lat };
    }
    return { lng: 113.0826, lat: 28.3538 };
  }

  function normalizePlace(place) {
    if (typeof normalizeRemotePlaceV2 === "function") return normalizeRemotePlaceV2(place);
    return {
      ...place,
      price: Number(place.avgPrice || place.amapCost || 20),
      longitude: place.entranceLongitude || place.longitude,
      latitude: place.entranceLatitude || place.latitude,
      walkingMinutes: place.walkingMinutes,
      category: place.category || "餐饮服务"
    };
  }

  function hasCoordinates(place) {
    return Number.isFinite(Number(place?.longitude)) && Number.isFinite(Number(place?.latitude));
  }

  function syncRecommendationData(places) {
    if (typeof diningDataV2 === "undefined") return;
    const localPlaces = diningDataV2.filter((place) => place.source !== "amap");
    const merged = typeof dedupePlacesV2 === "function"
      ? dedupePlacesV2([...localPlaces, ...places])
      : [...localPlaces, ...places];
    diningDataV2.splice(0, diningDataV2.length, ...merged);
    if (typeof renderAllV2 === "function") renderAllV2();
  }

  function walkingText(place) {
    if (place.walkingMinutes) return `步行约 ${place.walkingMinutes} 分钟`;
    if (place.distanceMeters) return `约 ${place.distanceMeters} 米`;
    if (place.distance) return `约 ${place.distance.toFixed(1)} km`;
    return "距离待确认";
  }

  function openText(place) {
    if (typeof isOpenNowV2 === "function") return isOpenNowV2(place) ? "当前营业" : "当前未营业";
    return "营业状态待确认";
  }

  async function fetchMapJson(path, params) {
    const url = new URL(path, window.location.origin);
    Object.entries(params || {}).forEach(([key, value]) => url.searchParams.set(key, value));
    const response = await fetch(url.toString(), { headers: { Accept: "application/json" } });
    const data = await response.json();
    if (!response.ok || data.ok === false) throw new Error(data.error || `请求失败：${response.status}`);
    return data;
  }
})();
