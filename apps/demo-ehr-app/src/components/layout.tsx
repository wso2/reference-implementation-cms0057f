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
import { useContext, useEffect, useLayoutEffect, useRef, useState } from "react";
import DevConsole from "./dev_console";
import { ExpandedContext } from "../utils/expanded_context";
import { useAuth } from "./AuthProvider";

const DEV_CONSOLE_WIDTH_LS = "devConsoleWidthPx";
const DEV_CONSOLE_MIN_WIDTH = 320;
const DEV_CONSOLE_MIN_MAIN_CONTENT = 120;

const getDefaultConsoleWidth = () =>
  Math.max(DEV_CONSOLE_MIN_WIDTH, Math.floor(window.innerWidth * 0.5));

const clampWidth = (width: number, max: number) =>
  Math.min(max, Math.max(DEV_CONSOLE_MIN_WIDTH, Math.round(width)));

export const Layout = () => {
  const { isAuthenticated } = useAuth();
  const { expanded } = useContext(ExpandedContext);
  const containerRef = useRef<HTMLDivElement | null>(null);
  const mainContentRef = useRef<HTMLDivElement | null>(null);
  const chromeColumnRef = useRef<HTMLDivElement | null>(null);
  const devConsolePanelRef = useRef<HTMLDivElement | null>(null);
  const latestWidthRef = useRef(0);
  const dragStartXRef = useRef(0);
  const dragStartWidthRef = useRef(0);
  const [isResizing, setIsResizing] = useState(false);
  const [devConsoleTheme, setDevConsoleTheme] = useState<"dark" | "light">(() => {
    const stored = localStorage.getItem("devConsoleTheme");
    return stored === "dark" ? "dark" : "light";
  });
  const [devConsoleWidthPx, setDevConsoleWidthPx] = useState<number>(() => {
    const stored = localStorage.getItem(DEV_CONSOLE_WIDTH_LS);
    const parsed = stored ? Number(stored) : NaN;
    if (Number.isFinite(parsed) && parsed >= DEV_CONSOLE_MIN_WIDTH) return parsed;
    if (typeof window !== "undefined") {
      return getDefaultConsoleWidth();
    }
    return 560;
  });

  const getMaxConsoleWidth = () => {
    const container = containerRef.current;
    const main = mainContentRef.current;
    const chrome = chromeColumnRef.current;

    if (!container || !main || !chrome) {
      return Math.max(
        DEV_CONSOLE_MIN_WIDTH,
        Math.floor(window.innerWidth * 0.9) - 300
      );
    }

    const containerRect = container.getBoundingClientRect();
    const sidebarWidth = main.getBoundingClientRect().left - containerRect.left;
    const chromeWidth = chrome.getBoundingClientRect().width;
    const maxWidth =
      containerRect.width - sidebarWidth - chromeWidth - DEV_CONSOLE_MIN_MAIN_CONTENT;

    return Math.max(DEV_CONSOLE_MIN_WIDTH, Math.floor(maxWidth));
  };

  const applyConsoleWidth = (width: number, persistToDomOnly = false) => {
    const max = getMaxConsoleWidth();
    const next = clampWidth(width, max);
    latestWidthRef.current = next;

    if (devConsolePanelRef.current) {
      devConsolePanelRef.current.style.width = `${next}px`;
    }

    if (!persistToDomOnly) {
      setDevConsoleWidthPx(next);
    }

    return next;
  };

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

    const storedRaw = localStorage.getItem(DEV_CONSOLE_WIDTH_LS);
    const stored = storedRaw ? Number(storedRaw) : NaN;
    const hasValidStored =
      Number.isFinite(stored) && stored >= DEV_CONSOLE_MIN_WIDTH;

    const initialWidth = hasValidStored ? stored : getDefaultConsoleWidth();
    applyConsoleWidth(initialWidth);

    if (!hasValidStored) {
      localStorage.setItem(DEV_CONSOLE_WIDTH_LS, String(latestWidthRef.current));
    }
  }, [expanded]);

  useEffect(() => {
    latestWidthRef.current = devConsoleWidthPx;
    if (devConsolePanelRef.current && !isResizing) {
      devConsolePanelRef.current.style.width = `${devConsoleWidthPx}px`;
    }
  }, [devConsoleWidthPx, isResizing]);

  useEffect(() => {
    if (!expanded) return;

    const onResize = () => {
      applyConsoleWidth(latestWidthRef.current);
      localStorage.setItem(DEV_CONSOLE_WIDTH_LS, String(latestWidthRef.current));
    };

    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, [expanded]);

  const startResize = (e: React.PointerEvent<HTMLDivElement>) => {
    if (!expanded) return;
    e.preventDefault();
    e.stopPropagation();

    const resizeHandle = e.currentTarget;
    resizeHandle.setPointerCapture(e.pointerId);

    dragStartXRef.current = e.clientX;
    dragStartWidthRef.current = latestWidthRef.current || devConsoleWidthPx;

    setIsResizing(true);
    document.body.style.cursor = "col-resize";
    document.body.style.userSelect = "none";

    if (devConsolePanelRef.current) {
      devConsolePanelRef.current.style.transition = "none";
      devConsolePanelRef.current.style.willChange = "width";
    }

    const onMove = (ev: PointerEvent) => {
      ev.preventDefault();
      const delta = dragStartXRef.current - ev.clientX;
      applyConsoleWidth(dragStartWidthRef.current + delta, true);
    };

    const endResize = (ev: PointerEvent) => {
      if (resizeHandle.hasPointerCapture(ev.pointerId)) {
        resizeHandle.releasePointerCapture(ev.pointerId);
      }

      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", endResize);
      window.removeEventListener("pointercancel", endResize);

      document.body.style.cursor = "";
      document.body.style.userSelect = "";
      setIsResizing(false);

      if (devConsolePanelRef.current) {
        devConsolePanelRef.current.style.transition = "";
        devConsolePanelRef.current.style.willChange = "";
      }

      const finalWidth = latestWidthRef.current;
      setDevConsoleWidthPx(finalWidth);
      localStorage.setItem(DEV_CONSOLE_WIDTH_LS, String(finalWidth));
    };

    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", endResize);
    window.addEventListener("pointercancel", endResize);
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
          minHeight: 0,
          overflow: "hidden",
        }}
      >
        <Sidebar />

        <div
          ref={mainContentRef}
          style={{
            flex: "1 1 auto",
            minWidth: DEV_CONSOLE_MIN_MAIN_CONTENT,
            overflowY: "auto",
            height: "100%",
          }}
        >
          <div style={{ marginTop: "30px", height: "100%" }}>
            <Outlet />
          </div>
        </div>

        <div
          ref={chromeColumnRef}
          style={{
            flexShrink: 0,
            display: "flex",
            alignItems: "stretch",
          }}
        >
          <div style={{ width: "1.5vw", marginLeft: "2vw" }}>
            <DevPortalExpandButton />
          </div>

          <div
            style={{
              flexShrink: 0,
              width: 4,
              marginLeft: "0.5vw",
              backgroundColor: "black",
            }}
          />
        </div>

        <div
          ref={devConsolePanelRef}
          style={{
            position: "relative",
            flexShrink: 0,
            width: expanded ? `${devConsoleWidthPx}px` : "0px",
            height: expanded ? "100%" : "0vh",
            minHeight: 0,
            overflow: "hidden",
            display: expanded ? "flex" : "block",
            flexDirection: "column",
            transition: isResizing
              ? "none"
              : expanded
                ? "opacity 0.25s ease-out"
                : "width 0.25s ease-out, opacity 0.25s ease-out",
            opacity: expanded ? 1 : 0,
            backgroundColor: devConsoleTheme === "light" ? "#f3f4f6" : "#A7B6B8",
            paddingTop: "5px",
            boxSizing: "border-box",
          }}
        >
          {expanded && (
            <div
              onPointerDown={startResize}
              role="separator"
              aria-orientation="vertical"
              aria-label="Resize developer console"
              aria-valuenow={devConsoleWidthPx}
              title="Drag to resize developer console"
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                bottom: 0,
                width: 20,
                transform: "translateX(-50%)",
                cursor: "col-resize",
                touchAction: "none",
                zIndex: 20,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                background: isResizing
                  ? "rgba(0, 107, 117, 0.28)"
                  : "transparent",
              }}
              onMouseEnter={(e) => {
                if (!isResizing) {
                  e.currentTarget.style.background = "rgba(0, 107, 117, 0.16)";
                }
              }}
              onMouseLeave={(e) => {
                if (!isResizing) {
                  e.currentTarget.style.background = "transparent";
                }
              }}
            >
              <div
                aria-hidden="true"
                style={{
                  width: 5,
                  height: 64,
                  borderRadius: 4,
                  background: isResizing
                    ? "#006B75"
                    : "repeating-linear-gradient(to bottom, #64748b 0 5px, transparent 5px 10px)",
                  boxShadow: isResizing ? "0 0 0 1px rgba(0,107,117,0.35)" : "none",
                }}
              />
            </div>
          )}

          <DevConsole />
        </div>
      </div>
    </div>
  ) : (
    <Navigate to="/" replace />
  );
};
