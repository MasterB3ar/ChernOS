const KEY = "chernos-2.0-state";

export interface ChernOSState {
  theme: "green" | "amber" | "redline" | "blackchamber" | "night";
  lastReactor?: any;
  profiles: {
    active: string;
    byId: Record<string, { name: string; rank: string }>;
  };
  soundscape: {
    master: number;
    hum: number;
    alarms: number;
    music: number;
  };
}

const defaultState: ChernOSState = {
  theme: "green",
  profiles: {
    active: "default",
    byId: {
      default: { name: "ANON", rank: "TECHNICIAN" }
    }
  },
  soundscape: {
    master: 0.7,
    hum: 0.5,
    alarms: 0.7,
    music: 0.4
  }
};

export function loadState(): ChernOSState {
  try {
    const raw = localStorage.getItem(KEY);
    if (!raw) return defaultState;
    const parsed = JSON.parse(raw);
    return { ...defaultState, ...parsed };
  } catch {
    return defaultState;
  }
}

export function saveState(state: ChernOSState) {
  try {
    localStorage.setItem(KEY, JSON.stringify(state));
  } catch {
    // ignore
  }
}
