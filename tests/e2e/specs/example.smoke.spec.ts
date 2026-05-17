import { test, expect } from '@playwright/test';

/**
 * @smoke タグ付きの UI スモークテスト。
 *
 * scripts/smoke-ui.sh が `--grep @smoke` でこのファイル群を実行する。
 *
 * 書き方:
 *   test('description @smoke', async ({ page }) => { ... });
 *
 * 実プロジェクトではこの example を削除して、自分のプロダクトの
 * 「壊れていたら即気付くべき golden path」をスモークとして書く。
 */

test.describe('Smoke', () => {
  test('home page loads @smoke', async ({ page }) => {
    await page.goto('/');
    await expect(page).toHaveTitle(/.+/);
  });
});
