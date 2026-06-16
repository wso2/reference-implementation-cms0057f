import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// DEV-ONLY shims for local browser testing (not for prod/Choreo):
//  - mock Choreo managed-auth /auth/userinfo
//  - same-origin proxy to the local Ballerina services (avoids backend CORS)
const devShims = {
  name: 'dev-auth-shim',
  configureServer(server: any) {
    server.middlewares.use('/auth/userinfo', (_req: any, res: any) => {
      res.setHeader('Content-Type', 'application/json')
      res.end(JSON.stringify({ username: 'umadmin', given_name: 'UM', family_name: 'Admin', id: 'ADMIN-001' }))
    })
    const redir = (_req: any, res: any) => { res.writeHead(302, { Location: '/' }); res.end() }
    server.middlewares.use('/auth/login', redir)
    server.middlewares.use('/auth/logout', redir)
  },
}

export default defineConfig({
  plugins: [react({ babel: { plugins: [['babel-plugin-react-compiler']] } }), devShims],
  server: {
    proxy: {
      '/bff':  { target: 'http://localhost:6091', changeOrigin: true, rewrite: (p: string) => p.replace(/^\/bff/, '') },
      '/pdex': { target: 'http://localhost:8091', changeOrigin: true },
      '/qgen': { target: 'http://localhost:6080', changeOrigin: true, rewrite: (p: string) => p.replace(/^\/qgen/, '') },
    },
  },
})
