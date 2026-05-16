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

  test('link interaction', async ({ page }) => {
    await page.goto('https://example.com');

    // リンクをクリック
    const link = page.getByRole('link', { name: /more information/i });
    await expect(link).toBeVisible();

    await page.screenshot({
      path: 'test-results/02-link-visible.png',
    });

    // 実際のクリックは外部遷移なので省略
  });

  test.skip('intentionally skipped example', async ({ page }) => {
    // このテストは skip 例
    await page.goto('/');
  });
});
