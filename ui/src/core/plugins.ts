import { bus, logLine } from "./messageBus";

export interface ChernOSPlugin {
  id: string;
  name: string;
  version: string;
  init: () => void;
}

const plugins: ChernOSPlugin[] = [];

export function registerPlugin(p: ChernOSPlugin) {
  plugins.push(p);
  logLine(`Plugin registered: ${p.name} v${p.version}`);
  bus.emit({ type: "plugin:register", payload: { id: p.id } });
  p.init();
}

export function listPlugins() {
  return plugins.slice();
}
