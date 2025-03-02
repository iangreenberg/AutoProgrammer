import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    strictPort: false, // Allow fallback to next available port
    cors: true,
    hmr: {
      overlay: true // Show errors as overlay in browser
    }
  }
})
