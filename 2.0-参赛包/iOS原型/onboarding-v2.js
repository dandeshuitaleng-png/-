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

let authAccountV2 = loadAuthAccountV2();
let authGenderV2 = authAccountV2.gender || "保密";
let authInterestsV2 = new Set(authAccountV2.interests || []);
let authResendTimerV2 = undefined;
let authResendSecondsV2 = 0;

document.querySelector("#authStartButton").addEventListener("click", () => showAuthStepV2("method"));
document.querySelectorAll("[data-auth-back]").forEach((button) => {
  button.addEventListener("click", () => showAuthStepV2(button.dataset.authBack));
});
document.querySelectorAll("[data-auth-method]").forEach((button) => {
  button.addEventListener("click", () => chooseAuthMethodV2(button.dataset.authMethod));
});
authGetCodeButtonV2.addEventListener("click", requestAuthCodeV2);
document.querySelector("#authVerifyButton").addEventListener("click", verifyAuthCodeV2);
authResendButtonV2.addEventListener("click", resendAuthCodeV2);
document.querySelector("#authProfileButton").addEventListener("click", () => showAuthStepV2("profile"));
document.querySelector("#authSaveProfileButton").addEventListener("click", () => saveAuthProfileV2(false));
document.querySelector("#authSkipProfileButton").addEventListener("click", () => saveAuthProfileV2(true));
document.querySelector("#authSaveInterestsButton").addEventListener("click", () => saveAuthInterestsV2(false));
document.querySelector("#authSkipInterestsButton").addEventListener("click", () => saveAuthInterestsV2(true));
document.querySelector("#authEnterHomeButton").addEventListener("click", completeOnboardingV2);
document.querySelector("#restartOnboardingButton").addEventListener("click", restartOnboardingV2);

authPhoneV2.addEventListener("input", () => {
  authPhoneV2.value = authPhoneV2.value.replace(/\D/g, "").slice(0, 11);
  setAuthErrorV2("authPhoneError", "");
  updateAuthGetCodeButtonV2();
});
authAgreementV2.addEventListener("change", updateAuthGetCodeButtonV2);
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
  getAccount: () => ({ ...authAccountV2, interests: [...authInterestsV2] })
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
  if (step === "guide") updateGuideCopyV2();
}

function chooseAuthMethodV2(method) {
  authAccountV2.registrationMethod = method;
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
  showAuthStepV2("interests");
}

function saveAuthInterestsV2(skip) {
  if (skip) authInterestsV2.clear();
  authAccountV2.interests = [...authInterestsV2];
  saveAuthAccountV2();
  updateAccountSummaryV2();
  showAuthStepV2("guide");
}

function completeOnboardingV2() {
  authAccountV2.onboardingComplete = true;
  authAccountV2.interests = [...authInterestsV2];
  saveAuthAccountV2();
  persistAuthPreferencesToAppV2();
  updateAccountSummaryV2();
  hideAuthFlowV2();
  window.dispatchEvent(new CustomEvent("eatwhat:onboarding-complete", {
    detail: { interests: [...authInterestsV2], account: { ...authAccountV2 } }
  }));
}

function restartOnboardingV2() {
  authAccountV2.onboardingComplete = false;
  saveAuthAccountV2();
  showAuthStepV2("welcome");
}

function hideAuthFlowV2() {
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
  interestsElement.textContent = labels.length > 0 ? labels.slice(0, 3).join(" / ") : "暂未设置";
}

function persistAuthPreferencesToAppV2() {
  try {
    const appState = JSON.parse(localStorage.getItem(AUTH_APP_STATE_KEY_V2) || "{}");
    if (authInterestsV2.has("fast")) appState.speedPreference = "fast";
    if (authInterestsV2.has("near")) appState.distance = "walkable";
    if (authInterestsV2.has("budget")) appState.budget = "under20";
    if (authInterestsV2.has("light")) appState.diet = "light";
    if (authInterestsV2.has("spicy")) appState.avoidSpicy = false;
    if (authInterestsV2.has("noodles")) appState.type = "noodles";
    localStorage.setItem(AUTH_APP_STATE_KEY_V2, JSON.stringify(appState));
  } catch (error) {
    // 存储受限时，仍可在当前会话完成引导。
  }
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
