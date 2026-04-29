// Copyright (c) 2024-2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import NavBar from "./nav_bar";
import Sidebar from "./sidebar";
import { DevPortalExpandButton } from "./cds_button";
import { Navigate, Outlet } from "react-router-dom";
import { useContext, useEffect, useLayoutEffect, useMemo, useRef, useState } from "react";
import DevConsole from "./dev_console";
import { ExpandedContext } from "../utils/expanded_context";
import { useAuth } from "./AuthProvider";

const DEV_CONSOLE_WIDTH_LS = "devConsoleWidthPx";

export const Layout = () => {
  const { isAuthenticated } = useAuth();
  const { expanded } = useContext(ExpandedContext);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const latestWidthRef = useRef(0);
  const [isResizing, setIsResizing] = useState(false);
  const [devConsoleTheme, setDevConsoleTheme] = useState<"dark" | "light">(() => {
    const stored = localStorage.getItem("devConsoleTheme");
    return stored === "dark" ? "dark" : "light";
  });
  const [devConsoleWidthPx, setDevConsoleWidthPx] = useState<number>(() => {
    const stored = localStorage.getItem(DEV_CONSOLE_WIDTH_LS);
    const parsed = stored ? Number(stored) : NaN;
    if (Number.isFinite(parsed) && parsed >= 320) return parsed;
    if (typeof window !== "undefined") {
      return Math.max(360, Math.floor(window.innerWidth * 0.5));
    }
    return 560;
  });

  const clampDevConsoleWidth = useMemo(() => {
    return (next: number, safeMax: number) => {
      const min = 320;
      const hardMax = Math.min(1600, safeMax);
      return Math.min(hardMax, Math.max(min, next));
    };
  }, []);

  useEffect(() => {
    const onStorage = (e: StorageEvent) => {
      if (e.key !== "devConsoleTheme") return;
      setDevConsoleTheme(e.newValue === "dark" ? "dark" : "light");
    };

    const onThemeChanged = () => {
      const stored = localStorage.getItem("devConsoleTheme");
      setDevConsoleTheme(stored === "dark" ? "dark" : "light");
    };

    window.addEventListener("storage", onStorage);
    window.addEventListener("devConsoleThemeChanged", onThemeChanged as EventListener);
    return () => {
      window.removeEventListener("storage", onStorage);
      window.removeEventListener("devConsoleThemeChanged", onThemeChanged as EventListener);
    };
  }, []);

  useLayoutEffect(() => {
    if (!expanded) return;

    const el = containerRef.current;
    if (!el) return;

    const rect = el.getBoundingClientRect();
    const safeMax = Math.max(360, Math.floor(rect.width * 0.92));
    const storedRaw = localStorage.getItem(DEV_CONSOLE_WIDTH_LS);
    const stored = storedRaw ? Number(storedRaw) : NaN;
    const hasValidStored = Number.isFinite(stored) && stored >= 320;

    if (!hasValidStored) {
      const half = clampDevConsoleWidth(Math.floor(rect.width * 0.5), safeMax);
      setDevConsoleWidthPx(half);
      latestWidthRef.current = half;
      localStorage.setItem(DEV_CONSOLE_WIDTH_LS, String(half));
      return;
    }

    setDevConsoleWidthPx((w) => clampDevConsoleWidth(w, safeMax));
  }, [expanded, clampDevConsoleWidth]);

  useEffect(() => {
    latestWidthRef.current = devConsoleWidthPx;
  }, [devConsoleWidthPx]);

  const startResize = (e: React.MouseEvent<HTMLDivElement>) => {
    if (!expanded) return;
    e.preventDefault();
    setIsResizing(true);

    const onMove = (ev: MouseEvent) => {
      const el = containerRef.current;
      if (!el) return;
      const r = el.getBoundingClientRect();
      const safeMax = Math.max(360, Math.floor(r.width * 0.92));
      const fromRight = r.right - ev.clientX;
      const next = clampDevConsoleWidth(fromRight, safeMax);
      latestWidthRef.current = next;
      setDevConsoleWidthPx(next);
    };

    const onUp = () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
      document.body.style.cursor = "";
      document.body.style.userSelect = "";
      setIsResizing(false);
      localStorage.setItem(DEV_CONSOLE_WIDTH_LS, String(latestWidthRef.current));
    };

    document.body.style.cursor = "col-resize";
    document.body.style.userSelect = "none";
    window.addEventListener("mousemove", onMove, { passive: true });
    window.addEventListener("mouseup", onUp);
  };

  return isAuthenticated ? (
    <div
      style={{
        height: "100vh",
        width: "100vw",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          position: "sticky",
          top: 0,
          zIndex: 1000,
          color: "white",
        }}
      >
        <NavBar />
      </div>

      <div
        ref={containerRef}
        style={{
          display: "flex",
          flexDirection: "row",
          backgroundColor: "white",
          flexGrow: 1,
        }}
      >
        <Sidebar />

        <div
          style={{
            flex: "1 1 auto",
            minWidth: 0,
            overflowY: "auto", // Allowing internal scrolling
            height: "100%",
          }}
        >
          <div style={{ marginTop: "30px", height: "100%" }}>
            <Outlet />
          </div>
        </div>

        <div style={{ width: "1.5vw", marginLeft: "2vw" }}>
          <DevPortalExpandButton />
        </div>

        <div
          style={{
            backgroundColor: "black",
            marginLeft: "1vw",
          }}
        />

        {expanded && (
          <div
            onMouseDown={startResize}
            role="separator"
            aria-orientation="vertical"
            aria-label="Resize developer console"
            title="Drag to resize"
            style={{
              flexShrink: 0,
              width: 16,
              marginLeft: -4,
              marginRight: -4,
              paddingLeft: 4,
              paddingRight: 4,
              cursor: "col-resize",
              touchAction: "none",
              zIndex: 5,
              background:
                "linear-gradient(90deg, rgba(0,0,0,0.0), rgba(0,0,0,0.12) 40%, rgba(0,0,0,0.12) 60%, rgba(0,0,0,0.0))",
            }}
          />
        )}

        <div
          style={{
            width: expanded ? `${devConsoleWidthPx}px` : "0px",
            height: expanded ? "100%" : "0vh",
            minHeight: 0,
            overflowY: "auto",
            display: expanded ? "flex" : "block",
            flexDirection: "column",
            transition: isResizing
              ? "none"
              : "width 0.35s ease-out, opacity 0.35s ease-out",
            opacity: expanded ? 1 : 0,
            backgroundColor: devConsoleTheme === "light" ? "#f3f4f6" : "#A7B6B8",
            paddingTop: "5px",
            boxSizing: "border-box",
          }}
        >
          <DevConsole />
        </div>
      </div>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
};
