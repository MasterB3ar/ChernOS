export type ThemeName = "green" | "amber" | "redline" | "blackchamber" | "night";

export function applyTheme(theme: ThemeName) {
  const root = document.documentElement;
  root.dataset.theme = theme;

  switch (theme) {
    case "green":
      root.style.setProperty("--ch-accent", "#22c55e");
      root.style.setProperty("--ch-bg", "#020806");
      break;
    case "amber":
      root.style.setProperty("--ch-accent", "#facc6b");
      root.style.setProperty("--ch-bg", "#1a1208");
      break;
    case "redline":
      root.style.setProperty("--ch-accent", "#fb7185");
      root.style.setProperty("--ch-bg", "#050009");
      break;
    case "blackchamber":
      root.style.setProperty("--ch-accent", "#38bdf8");
      root.style.setProperty("--ch-bg", "#020617");
      break;
    case "night":
      root.style.setProperty("--ch-accent", "#a5b4fc");
      root.style.setProperty("--ch-bg", "#020617");
      break;
  }
}
