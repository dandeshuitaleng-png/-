const AUTH_STORAGE_KEY_V2 = "eatWhatV2Account";
const AUTH_APP_STATE_KEY_V2 = "eatWhatV2State";
const AUTH_DEMO_CODE_V2 = "246810";

const authStepOrderV2 = ["welcome", "method", "phone", "code", "success", "profile", "interests", "guide"];
const authStepLabelsV2 = {
  welcome: "欢迎",
  method: "注册方式",
  phone: "手机号",
  code: "验证码",
  success: "注册成功",
  profile: "完善资料",
  interests: "兴趣偏好",
  guide: "新手引导"
};
const interestLabelsV2 = {
  fast: "出餐快",
  near: "少走路",
  budget: "20 元内",
  light: "少油轻食",
  spicy: "喜欢吃辣",
  noodles: "粉面"
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
const authPasswordV2 = document.querySelector("#authPassword");
const authBirthdayV2 = document.querySelector("#authBirthday");
const authInterestSummaryV2 = document.querySelector("#authInterestSummary");
const authInterestPreviewV2 = document.querySelector("#authInterestPreview");
const authSaveInterestsButtonV2 = document.querySelector("#authSaveInterestsButton");
const authSkipInterestsButtonV2 = document.querySelector("#authSkipInterestsButton");
const authInterestBackButtonV2 = document.querySelector('[data-auth-step="interests"] [data-auth-back]');

let authAccountV2 = loadAuthAccountV2();
let authGenderV2 = authAccountV2.gender || "保密";
let authInterestsV2 = new Set(authAccountV2.interests || []);
let authResendTimerV2 = undefined;
let authResendSecondsV2 = 0;
let authFlowContextV2 = "onboarding";
let authInterestSnapshotV2 = [...authInterestsV2];
let authInterestBackTargetV2 = "profile";

document.querySelector("#authStartButton").addEventListener("click", () => showAuthStepV2("method"));
document.querySelector("#authGuestButton").addEventListener("click", continueAsGuestV2);
document.querySelectorAll("[data-auth-back]").forEach((button) => {
  button.addEventListener("click", () => {
    if (authFlowContextV2 === "interest-edit" && button === authInterestBackButtonV2) {
      cancelInterestEditV2();
      return;
    }
    showAuthStepV2(button.dataset.authBack);
  });
});
document.querySelectorAll("[data-auth-method]").forEach((button) => {
  button.addEventListener("click", () => chooseAuthMethodV2(button.dataset.authMethod));
});
authGetCodeButtonV2.addEventListener("click", requestAuthCodeV2);
document.querySelector("#authVerifyButton").addEventListener("click", verifyAuthCodeV2);
authResendButtonV2.addEventListener("click", resendAuthCodeV2);
document.querySelector("#authProfileButton").addEventListener("click", () => showAuthStepV2("profile"));
document.querySelector("#authSkipProfileFromSuccessButton").addEventListener("click", () => {
  authInterestBackTargetV2 = "success";
  showAuthStepV2("interests");
});
document.querySelector("#authSaveProfileButton").addEventListener("click", () => saveAuthProfileV2(false));
document.querySelector("#authSkipProfileButton").addEventListener("click", () => saveAuthProfileV2(true));
document.querySelector("#authSaveInterestsButton").addEventListener("click", () => saveAuthInterestsV2(false));
document.querySelector("#authSkipInterestsButton").addEventListener("click", () => saveAuthInterestsV2(true));
document.querySelector("#authEnterHomeButton").addEventListener("click", completeOnboardingV2);
document.querySelector("#restartOnboardingButton").addEventListener("click", restartOnboardingV2);
document.querySelector("#editInterestsButton").addEventListener("click", editInterestsV2);

authPhoneV2.addEventListener("input", () => {
  authPhoneV2.value = authPhoneV2.value.replace(/\D/g, "").slice(0, 11);
  setAuthErrorV2("authPhoneError", "");
  updateAuthGetCodeButtonV2();
});
authAgreementV2.addEventListener("change", updateAuthGetCodeButtonV2);
document.querySelectorAll("[data-auth-legal]").forEach((button) => {
  button.addEventListener("click", (event) => {
    event.preventDefault();
    event.stopPropagation();
    showAuthToastV2(`${button.dataset.authLegal}为原型占位，正式版接入完整文本`);
  });
});
authCodeV2.addEventListener("input", () => {
  authCodeV2.value = authCodeV2.value.replace(/\D/g, "").slice(0, 6);
  setAuthErrorV2("authCodeError", "");
});
document.querySelectorAll("[data-auth-gender]").forEach((button) => {
  button.addEventListener("click", () => {
    authGenderV2 = button.dataset.authGender;
    renderAuthGenderV2();
  });
});
document.querySelectorAll("[data-interest]").forEach((button) => {
  button.addEventListener("click", () => {
    const interest = button.dataset.interest;
    if (authInterestsV2.has(interest)) {
      authInterestsV2.delete(interest);
    } else {
      authInterestsV2.add(interest);
    }
    renderAuthInterestsV2();
  });
});
authAvatarV2.addEventListener("change", previewAuthAvatarV2);

authBirthdayV2.max = new Date().toISOString().slice(0, 10);
hydrateAuthFormV2();
renderAuthGenderV2();
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
  authProgressV2.style.width = step === "welcome" ? "0%" : `${Math.round((index / (authStepOrderV2.length - 1)) * 100)}%`;
  authScrollV2.scrollTo({ top: 0, behavior: "auto" });
  if (step === "profile") hydrateAuthFormV2();
  if (step === "interests") updateInterestContextUiV2();
  if (step === "guide") updateGuideCopyV2();
}

function chooseAuthMethodV2(method) {
  authAccountV2.registrationMethod = method;
  if (method === "guest") {
    continueAsGuestV2();
    return;
  }
  if (method === "apple") {
    authAccountV2.registered = true;
    authAccountV2.phone = "Apple ID";
    saveAuthAccountV2();
    document.querySelector("#authSuccessCopy").textContent = "Apple ID 快捷注册已在原型中完成，现在可以设置昵称和饮食偏好。";
    showAuthStepV2("success");
    return;
  }
  document.querySelector("#authSuccessCopy").textContent = "手机号验证已完成，现在完善资料，推荐会更贴合你的日常习惯。";
  showAuthStepV2("phone");
}

function continueAsGuestV2() {
  authFlowContextV2 = "onboarding";
  authAccountV2.registrationMethod = "guest";
  authAccountV2.registered = false;
  authAccountV2.phone = "";
  authAccountV2.nickname = authAccountV2.nickname || "体验用户";
  saveAuthAccountV2();
  updateAccountSummaryV2();
  showAuthToastV2("已进入游客体验，可先设置偏好");
  authInterestBackTargetV2 = "method";
  showAuthStepV2("interests");
}

function requestAuthCodeV2() {
  const phone = authPhoneV2.value.trim();
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
  document.querySelector("#authCodePhone").textContent = `验证码已发送至 ${maskPhoneV2(phone)}`;
  authCodeV2.value = "";
  setAuthErrorV2("authCodeError", "");
  startAuthCountdownV2();
  showAuthStepV2("code");
  showAuthToastV2("演示验证码已生成");
}

function updateAuthGetCodeButtonV2() {
  authGetCodeButtonV2.disabled = !/^1[3-9]\d{9}$/.test(authPhoneV2.value.trim()) || !authAgreementV2.checked;
}

function verifyAuthCodeV2() {
  if (authCodeV2.value !== AUTH_DEMO_CODE_V2) {
    setAuthErrorV2("authCodeError", "验证码不正确，请输入 246810");
    return;
  }
  authAccountV2.registered = true;
  saveAuthAccountV2();
  setAuthErrorV2("authCodeError", "");
  showAuthStepV2("success");
}

function resendAuthCodeV2() {
  if (authResendSecondsV2 > 0) return;
  authCodeV2.value = "";
  startAuthCountdownV2();
  showAuthToastV2("验证码已重新生成：246810");
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
  authResendButtonV2.textContent = waiting ? `${authResendSecondsV2} 秒后可重新获取` : "重新获取验证码";
}

function saveAuthProfileV2(skip) {
  const nickname = cleanAuthTextV2(authNicknameV2.value, 16);
  const password = authPasswordV2.value;
  if (!skip && !nickname) {
    setAuthErrorV2("authProfileError", "请填写昵称，其他资料可以稍后设置");
    return;
  }
  if (!skip && password.length > 0 && password.length < 6) {
    setAuthErrorV2("authProfileError", "密码至少需要 6 位");
    return;
  }
  authAccountV2.nickname = nickname || authAccountV2.nickname || "新朋友";
  authAccountV2.hasPassword = password.length >= 6;
  authAccountV2.gender = authGenderV2;
  authAccountV2.birthday = authBirthdayV2.value || "";
  authPasswordV2.value = "";
  setAuthErrorV2("authProfileError", "");
  saveAuthAccountV2();
  updateAccountSummaryV2();
  authInterestBackTargetV2 = "profile";
  showAuthStepV2("interests");
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
  showAuthStepV2("guide");
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
  if (authAccountV2.phone && authAccountV2.phone !== "Apple ID") authPhoneV2.value = authAccountV2.phone;
  authNicknameV2.value = authAccountV2.nickname || "";
  authBirthdayV2.value = authAccountV2.birthday || "";
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

function renderAuthGenderV2() {
  document.querySelectorAll("[data-auth-gender]").forEach((button) => {
    button.classList.toggle("active", button.dataset.authGender === authGenderV2);
  });
}

function renderAuthInterestsV2() {
  document.querySelectorAll("[data-interest]").forEach((button) => {
    button.classList.toggle("active", authInterestsV2.has(button.dataset.interest));
  });
  const preview = buildInterestPreviewV2();
  authInterestSummaryV2.querySelector("strong").textContent = preview.title;
  authInterestSummaryV2.querySelector("small").textContent = preview.copy;
  authInterestPreviewV2.innerHTML = preview.items.map((item) => `<li>${item}</li>`).join("");
  authSaveInterestsButtonV2.textContent = authInterestsV2.size > 0 ? `保存 ${authInterestsV2.size} 项偏好` : "保存偏好";
}

function updateInterestContextUiV2() {
  const editing = authFlowContextV2 === "interest-edit" && authAccountV2.onboardingComplete;
  authInterestBackButtonV2.textContent = editing ? "取消" : "返回";
  authInterestBackButtonV2.dataset.authBack = editing ? "profile" : authInterestBackTargetV2;
  authSkipInterestsButtonV2.textContent = editing ? "恢复默认条件" : "暂不设置";
}

function updateGuideCopyV2() {
  const nickname = authAccountV2.nickname || "新朋友";
  document.querySelector("#authGuideTitle").textContent = `${nickname}，准备好了`;
}

function updateAccountSummaryV2() {
  const accountElement = document.querySelector("#mineAccount");
  const interestsElement = document.querySelector("#mineInterests");
  if (!accountElement || !interestsElement) return;
  const identity = authAccountV2.nickname || (authAccountV2.phone ? maskPhoneV2(authAccountV2.phone) : "游客");
  accountElement.textContent = identity;
  const labels = [...authInterestsV2].map((item) => interestLabelsV2[item]).filter(Boolean);
  interestsElement.textContent = labels.length > 0 ? labels.slice(0, 4).join(" / ") : "暂未设置";
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

function buildInterestPreviewV2() {
  const appPrefs = buildAppPreferencesFromInterestsV2();
  const selected = [...authInterestsV2].map((item) => interestLabelsV2[item]).filter(Boolean);
  if (selected.length === 0) {
    return {
      title: "还没选兴趣",
      copy: "如果先跳过，系统会使用通用默认条件。",
      items: [
        "默认预算保持 20 元内，方便先覆盖校园高频餐饮。",
        "默认距离保持 1km 内，先保证步行可达。",
        "一键推荐会先看营业状态、距离和基础偏好。"
      ]
    };
  }
  const items = [
    `已选兴趣：${selected.join(" / ")}`
  ];
  items.push(`默认预算：${appPrefs.budget === "under20" ? "20 元内" : "不限预算"}`);
  items.push(`默认距离：${appPrefs.distance === "near" ? "0.5km 内" : appPrefs.distance === "walkable" ? "1km 内" : "不限距离"}`);
  items.push(`出餐偏好：${appPrefs.speedPreference === "fast" ? "优先快出餐" : "速度不限"}`);
  items.push(`饮食方向：${appPrefs.diet === "light" ? "少油轻食" : "饮食不限"}`);
  items.push(`辣度策略：${appPrefs.avoidSpicy ? "默认避开重辣" : "辣度不限"}`);
  if (appPrefs.preferredType && appPrefs.preferredType !== "random") {
    items.push(`一键推荐会优先考虑：${interestLabelsV2.noodles}`);
  }
  return {
    title: "这些兴趣会直接影响默认推荐",
    copy: "保存后会同步到首页的一键推荐，不用每次重新选条件。",
    items
  };
}

function buildAppPreferencesFromInterestsV2() {
  return {
    budget: authInterestsV2.has("budget") ? "under20" : "under20",
    distance: authInterestsV2.has("near") ? "near" : "walkable",
    diet: authInterestsV2.has("light") ? "light" : "all",
    speedPreference: authInterestsV2.has("fast") ? "fast" : "all",
    avoidSpicy: !authInterestsV2.has("spicy"),
    preferredType: authInterestsV2.has("noodles") ? "noodles" : "random"
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

function maskPhoneV2(phone) {
  if (phone === "Apple ID") return phone;
  return /^\d{11}$/.test(phone) ? `${phone.slice(0, 3)}****${phone.slice(-4)}` : phone;
}
