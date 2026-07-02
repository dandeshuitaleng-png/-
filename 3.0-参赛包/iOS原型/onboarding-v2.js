const AUTH_STORAGE_KEY_V2 = "eatWhatV2Account";
const AUTH_APP_STATE_KEY_V2 = "eatWhatV2State";
const authStepOrderV2 = ["welcome", "phone", "code", "interests", "profile"];
const authStepLabelsV2 = {
  welcome: "欢迎",
  phone: "手机号登录",
  code: "安全验证",
  interests: "吃饭偏好",
  profile: "个人资料"
};
const interestLabelsV2 = {
  budget15: "15 元内",
  budget20: "20 元内",
  budget30: "30 元内",
  budgetAny: "预算不限",
  distanceDownstairs: "楼下优先",
  distance500: "500m 内",
  distance1000: "1km 内",
  distanceAny: "距离不限",
  fast: "出餐快",
  shortQueue: "排队少",
  takeout: "可外带",
  light: "清淡",
  lessOil: "少油",
  spicy: "能吃辣",
  noSpicy: "不吃辣",
  rice: "米饭",
  noodles: "粉面",
  foodLight: "轻食",
  snack: "小吃",
  drink: "咖啡饮品"
};

const authFlowV2 = document.querySelector("#authFlow");
const authProgressV2 = document.querySelector("#authProgress");
const authStepLabelV2 = document.querySelector("#authStepLabel");
const authScrollV2 = authFlowV2.querySelector(".auth-scroll");
const authToastV2 = document.querySelector("#authToast");
const authPhoneV2 = document.querySelector("#authPhone");
const authAgreementV2 = document.querySelector("#authAgreement");
const authGetCodeButtonV2 = document.querySelector("#authGetCodeButton");
const authCodeV2 = document.querySelector("#authCode");
const authResendButtonV2 = document.querySelector("#authResendButton");
const authAvatarV2 = document.querySelector("#authAvatar");
const authAvatarPreviewV2 = document.querySelector("#authAvatarPreview");
const authNicknameV2 = document.querySelector("#authNickname");
const authSaveInterestsButtonV2 = document.querySelector("#authSaveInterestsButton");
const authSkipInterestsButtonV2 = document.querySelector("#authSkipInterestsButton");
const authInterestBackButtonV2 = document.querySelector('[data-auth-step="interests"] [data-auth-back]');
const authProfileBackButtonV2 = document.querySelector('[data-auth-step="profile"] [data-auth-back]');

let authAccountV2 = loadAuthAccountV2();
let authInterestsV2 = new Set(authAccountV2.interests || []);
let authResendTimerV2 = undefined;
let authResendSecondsV2 = 0;
let authFlowContextV2 = "onboarding";
let authInterestSnapshotV2 = [...authInterestsV2];
let authInterestBackTargetV2 = "welcome";

document.querySelector("#authGuestButton").addEventListener("click", continueAsGuestV2);
document.querySelector("#authAppleButton").addEventListener("click", continueWithAppleV2);
document.querySelector("#authPhoneButton").addEventListener("click", () => showAuthStepV2("phone"));
document.querySelector("#authPhoneAppleButton").addEventListener("click", continueWithAppleV2);
document.querySelectorAll("[data-auth-back]").forEach((button) => {
  button.addEventListener("click", () => {
    if (authFlowContextV2 === "interest-edit" && button === authInterestBackButtonV2) {
      cancelInterestEditV2();
      return;
    }
    if (authFlowContextV2 === "profile-edit" && button === authProfileBackButtonV2) {
      hideAuthFlowV2();
      return;
    }
    showAuthStepV2(button.dataset.authBack);
  });
});
authGetCodeButtonV2.addEventListener("click", requestAuthCodeV2);
document.querySelector("#authVerifyButton").addEventListener("click", verifyAuthCodeV2);
authResendButtonV2.addEventListener("click", resendAuthCodeV2);
document.querySelector("#authSaveProfileButton").addEventListener("click", saveAuthProfileV2);
document.querySelector("#authSaveInterestsButton").addEventListener("click", () => saveAuthInterestsV2(false));
document.querySelector("#authSkipInterestsButton").addEventListener("click", () => saveAuthInterestsV2(true));
document.querySelector("#restartOnboardingButton").addEventListener("click", restartOnboardingV2);
document.querySelector("#editInterestsButton").addEventListener("click", editInterestsV2);
document.querySelector("#completeProfileButton").addEventListener("click", editProfileV2);

authPhoneV2.addEventListener("input", () => {
  authPhoneV2.value = formatPhoneInputV2(authPhoneV2.value);
  setAuthErrorV2("authPhoneError", "");
  updateAuthGetCodeButtonV2();
});
authAgreementV2.addEventListener("change", updateAuthGetCodeButtonV2);
document.querySelectorAll("[data-auth-legal]").forEach((button) => {
  button.addEventListener("click", (event) => {
    event.preventDefault();
    event.stopPropagation();
    showAuthToastV2(`${button.dataset.authLegal}内容正在完善`);
  });
});
authCodeV2.addEventListener("input", () => {
  authCodeV2.value = authCodeV2.value.replace(/\D/g, "").slice(0, 6);
  setAuthErrorV2("authCodeError", "");
});
document.querySelectorAll("[data-interest]").forEach((button) => {
  button.addEventListener("click", () => {
    const interest = button.dataset.interest;
    if (authInterestsV2.has(interest)) {
      authInterestsV2.delete(interest);
    } else {
      const group = button.dataset.interestGroup;
      if (group) {
        document.querySelectorAll(`[data-interest-group="${group}"]`).forEach((item) => authInterestsV2.delete(item.dataset.interest));
      }
      authInterestsV2.add(interest);
    }
    renderAuthInterestsV2();
  });
});
authAvatarV2.addEventListener("change", previewAuthAvatarV2);

hydrateAuthFormV2();
renderAuthInterestsV2();
updateAuthGetCodeButtonV2();
updateAccountSummaryV2();
if (authAccountV2.onboardingComplete) {
  hideAuthFlowV2();
} else {
  showAuthStepV2("welcome");
}

window.EatWhatOnboarding = {
  restart: restartOnboardingV2,
  getAccount: () => ({ ...authAccountV2, interests: [...authInterestsV2] }),
  editInterests: editInterestsV2
};

function showAuthStepV2(step) {
  const index = authStepOrderV2.indexOf(step);
  if (index === -1) return;
  authFlowV2.classList.add("show");
  document.querySelectorAll("[data-auth-step]").forEach((screen) => {
    screen.classList.toggle("active", screen.dataset.authStep === step);
  });
  authStepLabelV2.textContent = authStepLabelsV2[step];
  const progressByStep = { welcome: 0, phone: 34, code: 67, interests: 100, profile: 0 };
  authProgressV2.style.width = `${progressByStep[step]}%`;
  authScrollV2.scrollTo({ top: 0, behavior: "auto" });
  if (step === "profile") hydrateAuthFormV2();
  if (step === "interests") updateInterestContextUiV2();
}

function continueWithAppleV2() {
  authFlowContextV2 = "onboarding";
  authAccountV2.registrationMethod = "apple";
  authAccountV2.registered = true;
  authAccountV2.phone = "Apple ID";
  saveAuthAccountV2();
  updateAccountSummaryV2();
  authInterestBackTargetV2 = "welcome";
  showAuthStepV2("interests");
  showAuthToastV2("已使用 Apple 登录");
}

function continueAsGuestV2() {
  authFlowContextV2 = "onboarding";
  authAccountV2.registrationMethod = "guest";
  authAccountV2.registered = false;
  authAccountV2.phone = "";
  authAccountV2.nickname = authAccountV2.nickname || "体验用户";
  saveAuthAccountV2();
  updateAccountSummaryV2();
  showAuthToastV2("无需注册，先设置吃饭偏好");
  authInterestBackTargetV2 = "welcome";
  showAuthStepV2("interests");
}

function requestAuthCodeV2() {
  const phone = normalizePhoneV2(authPhoneV2.value);
  if (!/^1[3-9]\d{9}$/.test(phone)) {
    setAuthErrorV2("authPhoneError", "请输入有效的 11 位中国大陆手机号");
    return;
  }
  if (!authAgreementV2.checked) {
    setAuthErrorV2("authPhoneError", "请先阅读并同意用户协议与隐私政策");
    return;
  }
  authAccountV2.phone = phone;
  authAccountV2.registrationMethod = "phone";
  saveAuthAccountV2();
  document.querySelector("#authCodePhone").textContent = `验证码已发送至 ${formatPhoneInputV2(phone)}`;
  authCodeV2.value = "";
  setAuthErrorV2("authCodeError", "");
  startAuthCountdownV2();
  showAuthStepV2("code");
  showAuthToastV2("验证码已发送");
}

function updateAuthGetCodeButtonV2() {
  authGetCodeButtonV2.disabled = !/^1[3-9]\d{9}$/.test(normalizePhoneV2(authPhoneV2.value)) || !authAgreementV2.checked;
}

function verifyAuthCodeV2() {
  if (!/^\d{6}$/.test(authCodeV2.value)) {
    setAuthErrorV2("authCodeError", "请输入 6 位验证码");
    return;
  }
  authAccountV2.registered = true;
  saveAuthAccountV2();
  setAuthErrorV2("authCodeError", "");
  updateAccountSummaryV2();
  authInterestBackTargetV2 = "phone";
  showAuthStepV2("interests");
  showAuthToastV2("账号已创建");
}

function resendAuthCodeV2() {
  if (authResendSecondsV2 > 0) return;
  authCodeV2.value = "";
  startAuthCountdownV2();
  showAuthToastV2("验证码已重新发送");
}

function startAuthCountdownV2() {
  if (authResendTimerV2 !== undefined) window.clearInterval(authResendTimerV2);
  authResendSecondsV2 = 30;
  updateAuthResendButtonV2();
  authResendTimerV2 = window.setInterval(() => {
    authResendSecondsV2 -= 1;
    updateAuthResendButtonV2();
    if (authResendSecondsV2 <= 0) {
      window.clearInterval(authResendTimerV2);
      authResendTimerV2 = undefined;
    }
  }, 1000);
}

function updateAuthResendButtonV2() {
  const waiting = authResendSecondsV2 > 0;
  authResendButtonV2.disabled = waiting;
  authResendButtonV2.textContent = waiting ? `重新发送 ${authResendSecondsV2}s` : "重新发送验证码";
}

function saveAuthProfileV2() {
  const nickname = cleanAuthTextV2(authNicknameV2.value, 16);
  if (!nickname) {
    setAuthErrorV2("authProfileError", "请填写昵称");
    return;
  }
  authAccountV2.nickname = nickname;
  setAuthErrorV2("authProfileError", "");
  saveAuthAccountV2();
  updateAccountSummaryV2();
  hideAuthFlowV2();
  showAuthToastV2("个人资料已保存");
}

function saveAuthInterestsV2(skip) {
  if (skip) authInterestsV2.clear();
  authAccountV2.interests = [...authInterestsV2];
  saveAuthAccountV2();
  persistAuthPreferencesToAppV2();
  updateAccountSummaryV2();
  if (authAccountV2.onboardingComplete && authFlowContextV2 === "interest-edit") {
    dispatchInterestUpdateV2("interest-edit");
    hideAuthFlowV2();
    showAuthToastV2(skip ? "已恢复通用默认条件" : "兴趣偏好已更新");
    return;
  }
  completeOnboardingV2();
}

function completeOnboardingV2() {
  authAccountV2.onboardingComplete = true;
  authAccountV2.interests = [...authInterestsV2];
  saveAuthAccountV2();
  persistAuthPreferencesToAppV2();
  updateAccountSummaryV2();
  dispatchInterestUpdateV2("onboarding");
  hideAuthFlowV2();
}

function restartOnboardingV2() {
  authFlowContextV2 = "onboarding";
  authInterestSnapshotV2 = [...authInterestsV2];
  authAccountV2.onboardingComplete = false;
  saveAuthAccountV2();
  showAuthStepV2("welcome");
}

function editInterestsV2() {
  authInterestSnapshotV2 = [...authInterestsV2];
  authFlowContextV2 = "interest-edit";
  showAuthStepV2("interests");
}

function editProfileV2() {
  authFlowContextV2 = "profile-edit";
  showAuthStepV2("profile");
}

function cancelInterestEditV2() {
  authInterestsV2 = new Set(authInterestSnapshotV2);
  renderAuthInterestsV2();
  hideAuthFlowV2();
  showAuthToastV2("已取消本次兴趣修改");
}

function hideAuthFlowV2() {
  authFlowContextV2 = "onboarding";
  authFlowV2.classList.remove("show");
}

function hydrateAuthFormV2() {
  if (authAccountV2.phone && authAccountV2.phone !== "Apple ID") authPhoneV2.value = formatPhoneInputV2(authAccountV2.phone);
  authNicknameV2.value = authAccountV2.nickname || "";
  if (authAccountV2.avatarDataUrl) {
    authAvatarPreviewV2.src = authAccountV2.avatarDataUrl;
    authAvatarPreviewV2.classList.add("show");
  }
}

function previewAuthAvatarV2() {
  const file = authAvatarV2.files?.[0];
  if (!file) return;
  if (file.size > 1024 * 1024) {
    setAuthErrorV2("authProfileError", "头像文件请控制在 1MB 以内");
    authAvatarV2.value = "";
    return;
  }
  const reader = new FileReader();
  reader.addEventListener("load", () => {
    authAccountV2.avatarDataUrl = String(reader.result || "");
    authAvatarPreviewV2.src = authAccountV2.avatarDataUrl;
    authAvatarPreviewV2.classList.add("show");
    saveAuthAccountV2();
  });
  reader.readAsDataURL(file);
}

function renderAuthInterestsV2() {
  document.querySelectorAll("[data-interest]").forEach((button) => {
    button.classList.toggle("active", authInterestsV2.has(button.dataset.interest));
  });
  authSaveInterestsButtonV2.textContent = authFlowContextV2 === "interest-edit"
    ? "保存修改"
    : "保存并看推荐";
}

function updateInterestContextUiV2() {
  const editing = authFlowContextV2 === "interest-edit" && authAccountV2.onboardingComplete;
  authInterestBackButtonV2.textContent = editing ? "取消" : "返回";
  authInterestBackButtonV2.dataset.authBack = editing ? "mine" : authInterestBackTargetV2;
  authSkipInterestsButtonV2.textContent = editing ? "恢复默认条件" : "跳过，使用默认推荐";
  renderAuthInterestsV2();
}

function updateAccountSummaryV2() {
  const accountElement = document.querySelector("#mineAccount");
  const interestsElement = document.querySelector("#mineInterests");
  const profileStatusElement = document.querySelector("#mineProfileStatus");
  if (!accountElement || !interestsElement || !profileStatusElement) return;
  const identity = authAccountV2.nickname || (authAccountV2.phone ? maskPhoneV2(authAccountV2.phone) : "游客");
  accountElement.textContent = identity;
  const labels = [...authInterestsV2].map((item) => interestLabelsV2[item]).filter(Boolean);
  interestsElement.textContent = labels.length > 0 ? labels.slice(0, 4).join(" / ") : "暂未设置";
  profileStatusElement.textContent = authAccountV2.nickname && authAccountV2.nickname !== "体验用户" ? "已完善" : "去完善";
}

function persistAuthPreferencesToAppV2() {
  try {
    const appState = JSON.parse(localStorage.getItem(AUTH_APP_STATE_KEY_V2) || "{}");
    Object.assign(appState, buildAppPreferencesFromInterestsV2());
    localStorage.setItem(AUTH_APP_STATE_KEY_V2, JSON.stringify(appState));
  } catch (error) {
    // 存储受限时，仍可在当前会话完成引导。
  }
}

function buildAppPreferencesFromInterestsV2() {
  let budget = "under20";
  if (authInterestsV2.has("budget15")) budget = "under15";
  if (authInterestsV2.has("budget30")) budget = "under30";
  if (authInterestsV2.has("budgetAny")) budget = "all";

  let distance = "walkable";
  if (authInterestsV2.has("distanceDownstairs")) distance = "downstairs";
  if (authInterestsV2.has("distance500") || authInterestsV2.has("near")) distance = "near";
  if (authInterestsV2.has("distanceAny")) distance = "all";

  let preferredType = "random";
  if (authInterestsV2.has("rice")) preferredType = "rice";
  if (authInterestsV2.has("noodles")) preferredType = "noodles";
  if (authInterestsV2.has("foodLight")) preferredType = "light";
  if (authInterestsV2.has("snack")) preferredType = "snack";
  if (authInterestsV2.has("drink")) preferredType = "drink";

  return {
    budget,
    distance,
    diet: authInterestsV2.has("light") || authInterestsV2.has("lessOil") || authInterestsV2.has("foodLight") ? "light" : "all",
    speedPreference: authInterestsV2.has("fast") || authInterestsV2.has("shortQueue") ? "fast" : "all",
    avoidSpicy: authInterestsV2.has("spicy") ? false : true,
    preferredType,
    mealMode: authInterestsV2.has("takeout") ? "takeout" : "any"
  };
}

function dispatchInterestUpdateV2(source = authFlowContextV2) {
  window.dispatchEvent(new CustomEvent("eatwhat:onboarding-complete", {
    detail: {
      interests: [...authInterestsV2],
      account: { ...authAccountV2 },
      appPreferences: buildAppPreferencesFromInterestsV2(),
      source
    }
  }));
}

function loadAuthAccountV2() {
  try {
    const stored = JSON.parse(localStorage.getItem(AUTH_STORAGE_KEY_V2) || "null");
    return stored && typeof stored === "object" ? stored : { interests: [] };
  } catch (error) {
    localStorage.removeItem(AUTH_STORAGE_KEY_V2);
    return { interests: [] };
  }
}

function saveAuthAccountV2() {
  try {
    localStorage.setItem(AUTH_STORAGE_KEY_V2, JSON.stringify(authAccountV2));
  } catch (error) {
    showAuthToastV2("当前浏览器无法保存资料，仍可继续体验");
  }
}

function setAuthErrorV2(id, message) {
  document.querySelector(`#${id}`).textContent = message;
}

function showAuthToastV2(message) {
  authToastV2.textContent = message;
  authToastV2.classList.add("show");
  window.clearTimeout(showAuthToastV2.timer);
  showAuthToastV2.timer = window.setTimeout(() => authToastV2.classList.remove("show"), 1800);
}

function cleanAuthTextV2(value, limit) {
  return String(value || "").replace(/[<>]/g, "").trim().slice(0, limit);
}

function normalizePhoneV2(value) {
  return String(value || "").replace(/\D/g, "").slice(0, 11);
}

function formatPhoneInputV2(value) {
  const digits = normalizePhoneV2(value);
  if (digits.length <= 3) return digits;
  if (digits.length <= 7) return `${digits.slice(0, 3)} ${digits.slice(3)}`;
  return `${digits.slice(0, 3)} ${digits.slice(3, 7)} ${digits.slice(7)}`;
}

function maskPhoneV2(phone) {
  if (phone === "Apple ID") return phone;
  return /^\d{11}$/.test(phone) ? `${phone.slice(0, 3)}****${phone.slice(-4)}` : phone;
}
