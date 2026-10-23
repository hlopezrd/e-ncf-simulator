type Handler = () => void;
let handler: Handler | null = null;

export function setUnauthorizedHandler(h: Handler | null) {
  handler = h;
}

export function getUnauthorizedHandler(): Handler | null {
  return handler;
}