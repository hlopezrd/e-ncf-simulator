export interface AuthResponse {
  token: string;
  expiresIn: number;
  tokenType: string;
}

export interface AuthCredentials {
  rnc: string;
  usuario: string;
  password: string;
}

export interface AuthState {
  token: string | null;
  isAuthenticated: boolean;
}