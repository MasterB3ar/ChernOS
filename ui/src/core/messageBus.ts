export type BusEvent =
  | { type: "reactor:update"; payload: any }
  | { type: "reactor:fault"; payload: { kind: string } }
  | { type: "audio:play"; payload: { id: string } }
  | { type: "audio:stop"; payload: { id: string } }
  | { type: "theme:set"; payload: { theme: string } }
  | { type: "net:update"; payload: any }
  | { type: "log:append"; payload: { line: string } }
  | { type: "plugin:register"; payload: { id: string } }
  | { type: "fault:simulate"; payload: { kind: string } }
  | { type: "containment:update"; payload: any };

type Listener = (event: BusEvent) => void;

class MessageBus {
  private listeners: Listener[] = [];

  subscribe(fn: Listener): () => void {
    this.listeners.push(fn);
    return () => {
      this.listeners = this.listeners.filter((l) => l !== fn);
    };
  }

  emit(event: BusEvent) {
    for (const l of this.listeners) l(event);
  }
}

export const bus = new MessageBus();

export function logLine(msg: string) {
  const now = new Date().toISOString().slice(11, 19);
  bus.emit({ type: "log:append", payload: { line: `[${now}] ${msg}` } });
}
