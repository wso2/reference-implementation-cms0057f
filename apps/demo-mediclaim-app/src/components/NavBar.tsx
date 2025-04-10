
import React from "react";
import { Link, useNavigate } from "react-router-dom";
import { Button } from "@/components/ui/button";
import { LogOut, Database } from "lucide-react";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { useToast } from "@/hooks/use-toast";

interface NavBarProps {
  userName?: string;
  isLoggedIn?: boolean;
  onLogout?: () => void;
}

const NavBar: React.FC<NavBarProps> = ({ 
  userName = "User", 
  isLoggedIn = false,
  onLogout 
}) => {
  const navigate = useNavigate();
  const { toast } = useToast();

  const handleLogout = () => {
    // Clear all session storage data
    sessionStorage.clear();
    
    // Show toast notification
    toast({
      title: "Logged out successfully",
      description: "You have been logged out.",
      variant: "default",
    });
    
    // Navigate to home page
    navigate("/");
    
    // Call the onLogout prop if provided
    if (onLogout) {
      onLogout();
    }
  };

  return (
    <nav className="w-full bg-gradient-to-r from-orange-700 to-orange-600 text-white border-b border-orange-800 shadow-md">
      <div className="container mx-auto px-4 py-2 flex justify-between items-center">
        <Link to="/" className="flex items-center gap-2 no-underline text-white">
          <Database className="h-6 w-6 text-white" />
          <h1 className="text-lg font-semibold">MediClaim</h1>
        </Link>

        <div className="flex items-center gap-2">
          {isLoggedIn && (
            <>
              <Button
                variant="ghost"
                size="sm"
                onClick={handleLogout}
                className="text-white hover:bg-orange-500/30"
              >
                <LogOut className="h-4 w-4 mr-2" />
                <span className="hidden sm:inline-block">Logout</span>
              </Button>
            </>
          )}
        </div>
      </div>
    </nav>
  );
};

export default NavBar;
