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

const useQuery = () => {
  return new URLSearchParams(useLocation().search);
};

export const AuthProvider = ({ children }: { children: ReactNode }) => {
  const location = useLocation();
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>(false);
  const navigate = useNavigate();
  const originalPath = location.pathname;

  const query = useQuery();

  const getAuthenticationIfo = async () => {
    const response = await fetch("/auth/userinfo");

    if (response.status == 200) {
      setIsAuthenticated(true);
      const redirectTo = originalPath || "/";
      navigate(redirectTo, { replace: true });
    } else if (response.status == 401) {
      setIsAuthenticated(false);
      const coverageId = query.get("coverageId") || "";
      const medicationRequestId = query.get("medicationRequestId") || "";
      const patientId = query.get("patientId") || "";

      localStorage.setItem("coverageId", coverageId);
      localStorage.setItem("medicationRequestId", medicationRequestId);
      localStorage.setItem("patientId", patientId);

      console.log("Patient ID (Auth): ", patientId);

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
