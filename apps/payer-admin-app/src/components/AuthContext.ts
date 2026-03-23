import { createContext } from "react";

export interface UserInfo {
  username: string;
  first_name: string;
  last_name: string;
  id: string;
}

export interface AuthContextType {
  isAuthenticated: boolean;
  userInfo: UserInfo | null;
  isLoading: boolean;
  checkAuth: () => Promise<void>;
  logout: () => void;
}

export const AuthContext = createContext<AuthContextType | undefined>(undefined);
