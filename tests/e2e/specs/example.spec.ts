import { test, expect } from '@playwright/test';

/**
 * E2E サンプルテスト
 *
 * このテストは「動作確認用」のサンプルです。
 * 実プロジェクトでは、このファイルを削除して自分のテストを書いてください。
 *
 * 重要:
 * - CI では video: 'on' で全実行が録画される
 * - 録画は test-results/ に保存され、artifact として PR コメントに貼られる
 * - スクショは `page.screenshot()` で明示的に取れる
 */

test.describe('Example E2E', () => {
  test('basic page load (example.com)', async ({ page }) => {
    await page.goto('https://example.com');
    await expect(page).toHaveTitle(/Example Domain/);

    // 明示スクショ（PR コメントに表示する用）
    await page.screenshot({
      path: 'test-results/01-home-loaded.png',
      fullPage: true,
    });

    const heading = page.locator('h1');
    await expect(heading).toHaveText('Example Domain');
  });

  test('paragraph and link present', async ({ page }) => {
    await page.goto('https://example.com');

    // ページ内に少なくとも1つのリンクと段落が存在することを確認
    const link = page.locator('a').first();
    await expect(link).toBeVisible();

    const paragraph = page.locator('p').first();
    await expect(paragraph).toBeVisible();

    await page.screenshot({
      path: 'test-results/02-page-content.png',
      fullPage: true,
    });
  });

  test.skip('intentionally skipped example', async ({ page }) => {
    // このテストは skip 例
    await page.goto('/');
  });
});
