/// <reference types="vitest/config" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { fileURLToPath, URL } from 'node:url'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url)),
    },
  },
  server: {
    port: 5173,
    // ล้มไปเลยถ้า port ไม่ว่าง — กันกรณี dev server เก่าค้างแล้วตัวใหม่ย้ายไป 5174
    // (ซึ่งชนกับ vantive-web) ทำให้ E2E ยิงไปโดนของเก่า
    strictPort: true,
    watch: {
      // ผล Robot เขียนทับบ่อย ไม่ต้อง reload ตาม
      ignored: ['**/tests/robot/results/**', '**/.venv/**'],
    },
    // dev: proxy /api → NestJS เพื่อเลี่ยง CORS (prod ให้ nginx/ingress ทำแทน)
    proxy: {
      '/api': {
        target: 'http://localhost:3001',
        changeOrigin: true,
      },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./src/tests/setup.ts'],
    css: false,
    include: ['src/**/*.{test,spec}.{ts,tsx}'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
    },
  },
})
