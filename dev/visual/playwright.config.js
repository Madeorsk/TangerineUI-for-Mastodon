const { defineConfig, devices } = require('@playwright/test');

const BASE_URL = process.env.VISUAL_BASE_URL || 'http://localhost:3000';

module.exports = defineConfig({
  testDir: '.',
  fullyParallel: false,
  // Theme is a server-side per-user setting, so tests must not race on it.
  workers: 1,
  reporter: [['html', { open: 'never' }], ['list']],
  use: {
    baseURL: BASE_URL,
    viewport: { width: 1280, height: 900 },
    deviceScaleFactor: 1,
  },
  expect: {
    toHaveScreenshot: { animations: 'disabled', maxDiffPixelRatio: 0.01 },
  },
  snapshotPathTemplate: '__screenshots__/{arg}{ext}',
  projects: [
    { name: 'setup', testMatch: /auth\.setup\.js/ },
    {
      name: 'chromium',
      use: { ...devices['Desktop Chrome'], storageState: '.auth/admin.json' },
      dependencies: ['setup'],
    },
  ],
});
