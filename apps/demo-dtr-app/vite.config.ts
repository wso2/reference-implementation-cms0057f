import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const devShims = {
  name: 'dev-auth-shim',
  configureServer(server: any) {
    server.middlewares.use('/auth/userinfo', (_req: any, res: any) => {
      res.setHeader('Content-Type', 'application/json')
      res.end(JSON.stringify({ username: 'drsmith', first_name: 'Sarah', last_name: 'Smith', given_name: 'Sarah', family_name: 'Smith', id: '456' }))
    })
    const redir = (_req: any, res: any) => { res.writeHead(302, { Location: '/' }); res.end() }
    server.middlewares.use('/auth/login', redir); server.middlewares.use('/auth/logout', redir)
  },
}
export default defineConfig({
  plugins: [react(), devShims],
  server: {
    port: 5174,
    proxy: { '/fhirapi': { target: 'http://localhost:8080/fhir/r4', changeOrigin: true, rewrite: (p: string) => p.replace(/^\/fhirapi/, '') } },
  },
})
