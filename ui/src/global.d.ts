declare global {
  interface Window {
    chernosAPI?: {
      onHotkey: (cb: (payload: any) => void) => void;
    };
  }
}
export {};
