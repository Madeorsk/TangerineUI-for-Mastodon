const { test: setup } = require('@playwright/test');

const EMAIL = process.env.VISUAL_EMAIL || 'admin@localhost';
const PASSWORD = process.env.VISUAL_PASSWORD || 'mastodonadmin';

setup('authenticate', async ({ page }) => {
  await page.goto('/auth/sign_in');
  await page.fill('input[name="user[email]"]', EMAIL);
  await page.fill('input[name="user[password]"]', PASSWORD);
  await page.click('button[type="submit"]');
  await page.waitForURL('**/home');
  await page.context().storageState({ path: '.auth/admin.json' });
});
