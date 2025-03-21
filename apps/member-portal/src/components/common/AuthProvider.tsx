import {
  createContext,
  useContext,
  useState,
  ReactNode,
  useEffect,
} from "react";
import { useLocation, useNavigate } from "react-router-dom";

interface AuthContextType {
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const location = useLocation();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const navigate = useNavigate();
  const originalPath = location.pathname;

  const getAuthenticationIfo = async () => {
    const response = await fetch("/auth/userinfo");

    if (response.status == 200) {
      setIsAuthenticated(true);
      const redirectTo = originalPath || "/";
      navigate(redirectTo, { replace: true });
    } else if (response.status == 401) {
      setIsAuthenticated(false);
      navigate("/login");
    }
  };

  useEffect(() => {
    getAuthenticationIfo();
  }, []);

  return (
    <AuthContext.Provider value={{ isAuthenticated }}>
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error("useAuth must be used within an AuthProvider");
  }
  return context;
};
