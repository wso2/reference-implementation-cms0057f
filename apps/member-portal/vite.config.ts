import { defineConfig } from 'vite';
import { nodePolyfills } from 'vite-plugin-node-polyfills'
import react from '@vitejs/plugin-react';
import viteTsconfigPaths from 'vite-tsconfig-paths';
import svgrPlugin from 'vite-plugin-svgr';

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react(),
    viteTsconfigPaths(),
    svgrPlugin(),
    nodePolyfills({
      include: ['fs'],
      overrides: {
        // Since `fs` is not supported in browsers, we can use the `memfs` package to polyfill it.
        fs: 'memfs',
      },
    }

    ),
  ],
  server: {
    open: true,
    port: 3000,
  },
  define: {
    'process.env': process.env
  },
});