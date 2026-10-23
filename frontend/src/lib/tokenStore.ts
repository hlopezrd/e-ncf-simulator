const KEY = "ecf_token";

export function setToken(t: string | null) {
  if (t) sessionStorage.setItem(KEY, t);
  else sessionStorage.removeItem(KEY);
}

export function getToken(): string | null {
  return sessionStorage.getItem(KEY);
}