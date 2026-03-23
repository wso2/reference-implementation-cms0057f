import {
  useState,
  useEffect,
  useRef,
} from "react";
import { type ReactNode } from "react";
import { useLocation, useNavigate } from "react-router-dom";
import { AuthContext } from "./AuthContext";
import type { UserInfo } from "./AuthContext";

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const capitalizeWords = (str: string): string => {
    return str.split(' ').map(word => 
      word.charAt(0).toUpperCase() + word.slice(1).toLowerCase()
    ).join(' ');
  };

  const location = useLocation();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const navigate = useNavigate();
  const hasCheckedAuth = useRef(false);

  useEffect(() => {
    // Only check auth once on mount
    if (hasCheckedAuth.current) return;
    hasCheckedAuth.current = true;

    const checkAuth = async () => {
      try {
        const response = await fetch("/auth/userinfo");

        if (response.status === 200) {
          const loggedUser = await response.json();
          setUserInfo({
            username: loggedUser.username ?? "User",
            first_name: capitalizeWords(loggedUser.given_name ?? "User"),
            last_name: capitalizeWords(loggedUser.family_name ?? ""),
            id: loggedUser.id ?? "ID-12302",
          });
          setIsAuthenticated(true);
          setIsLoading(false);
          navigate("/", { replace: true });

        } else if (response.status === 401) {
          setIsAuthenticated(false);
          setUserInfo(null);
          setIsLoading(false);
          
          // Only redirect to login if we're not already there
          if (location.pathname !== "/auth/login") {
            navigate("/auth/login", { replace: true });
          }
        }
      } catch (error) {
        console.error("Authentication check failed:", error);
        setIsAuthenticated(false);
        setUserInfo(null);
        setIsLoading(false);
        
        if (location.pathname !== "/auth/login") {
          navigate("/auth/login", { replace: true });
        }
      }
    };

    checkAuth();
  }, [location.pathname, navigate]);

  const manualCheckAuth = async () => {
    try {
      const response = await fetch("/auth/userinfo");

      if (response.status === 200) {
        const loggedUser = await response.json();
        setUserInfo({
          username: loggedUser.username,
          first_name: capitalizeWords(loggedUser.first_name || ""),
          last_name: capitalizeWords(loggedUser.last_name || ""),
          id: loggedUser.id,
        });
        setIsAuthenticated(true);
      } else if (response.status === 401) {
        setIsAuthenticated(false);
        setUserInfo(null);
        navigate("/auth/login", { replace: true });
      }
    } catch (error) {
      console.error("Authentication check failed:", error);
      setIsAuthenticated(false);
      setUserInfo(null);
      navigate("/auth/login", { replace: true });
    }
  };

  const logout = () => {
    setIsAuthenticated(false);
    setUserInfo(null);
    navigate("/auth/login", { replace: true });
  };

  return (
    <AuthContext.Provider value={{ isAuthenticated, userInfo, isLoading, checkAuth: manualCheckAuth, logout }}>
      {children}
    </AuthContext.Provider>
  );
};
