const { test, expect } = require('@playwright/test');

const VARIANTS = ['tangerineui', 'tangerineui-purple', 'tangerineui-cherry', 'tangerineui-lagoon'];
const SCHEMES = ['light', 'dark'];

const SURFACES = [
  { name: 'home', path: '/home' },
  { name: 'notifications', path: '/notifications' },
  { name: 'direct', path: '/conversations' },
  { name: 'explore', path: '/explore' },
  { name: 'local', path: '/public/local' },
  { name: 'profile', path: '/@admin' },
];

// Located by an option value rather than an id/label so it survives Mastodon version and locale changes.
const themeSelect = (page) =>
  page.locator('select', { has: page.locator('option[value="tangerineui"]') });

async function setTheme(page, theme) {
  await page.goto('/settings/preferences/appearance');
  const select = themeSelect(page);
  if ((await select.inputValue()) === theme) return;
  await select.selectOption(theme);
  await page.locator('form', { has: select }).locator('button[type="submit"]').click();
  await page.waitForLoadState('load');
}

async function settle(page) {
  await page.waitForLoadState('load');
  // Streaming keeps the network busy, so wait on the loaders: the top progress bar (react-redux-loading-bar) and the column spinner both clear once fetches resolve.
  await page.locator('.columns-area, .ui').first().waitFor();
  await expect(page.locator('.loading-bar')).toBeHidden({ timeout: 15000 });
  await expect(page.locator('.loading-indicator')).toHaveCount(0, { timeout: 15000 });
}

test.describe.configure({ mode: 'serial' });

for (const variant of VARIANTS) {
  test.describe(variant, () => {
    for (const scheme of SCHEMES) {
      test.describe(scheme, () => {
        test.use({ colorScheme: scheme });

        for (const surface of SURFACES) {
          test(surface.name, async ({ page }) => {
            await setTheme(page, variant);
            await page.goto(surface.path);
            await settle(page);
            await expect(page).toHaveScreenshot([variant, scheme, `${surface.name}.png`], {
              fullPage: true,
            });
          });
        }
      });
    }
  });
}
