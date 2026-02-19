import { defineConfig } from 'vite';
import { extensions, classicEmberSupport, ember } from '@embroider/vite';
import { babel } from '@rollup/plugin-babel';
import { loadTranslations } from '@ember-intl/vite';
import tailwindcss from '@tailwindcss/vite';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const projectRoot = dirname(fileURLToPath(import.meta.url));

export default defineConfig({
  resolve: {
    alias: [
      {
        find: /^@ember\/application$/,
        replacement: resolve(
          projectRoot,
          'node_modules/ember-source/dist/packages/@ember/application/index.js',
        ),
      },
    ],
  },
  plugins: [
    classicEmberSupport(),
    ember(),
    tailwindcss(),
    babel({
      babelHelpers: 'runtime',
      extensions,
    }),
    loadTranslations(),
  ],
  build: {
    chunkSizeWarningLimit: 1100, // three.js and html2pdf are intentionally lazy-loaded
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.includes('html2pdf') || id.includes('jspdf') || id.includes('html2canvas')) {
            return undefined; // let Vite handle these as dynamic imports
          }
          if (id.includes('/three/')) {
            return 'three';
          }
          if (id.includes('node_modules')) {
            return 'vendor';
          }
        },
      },
    },
  },
});
