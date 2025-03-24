// <reference types="vite/client" />

interface ImportMetaEnv {
    readonly VITE_APP_TITLE: string
    readonly VITE_APP_AUTH_CLIENT_ID: string
    readonly VITE_APP_AUTH_BASE_URL: string
    readonly VITE_APP_AUTH_REDIRECT_URL: string
    readonly RANDOM: string

  }
  
  interface ImportMeta {
    readonly env: ImportMetaEnv
  }
