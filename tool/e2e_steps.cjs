// Drives the demo under each fake WebUI tier, for the SDK's
// tools/e2e/webui_tiers.cjs:
//
//   NODE_PATH=$(npm root -g) node ../aera-flutter-sdk/tools/e2e/webui_tiers.cjs . build/e2e --script tool/e2e_steps.cjs

module.exports = async (page, h) => {
  const seen = {};
  const scrollTo = async (label) => {
    for (let i = 0; i < 12; i++) {
      if ((await h.text()).includes(label)) return;
      await page.mouse.move(200, 500);
      await page.mouse.wheel(0, 350);
      await page.waitForTimeout(400);
    }
  };
  const top = async () => {
    for (let i = 0; i < 6; i++) { await page.mouse.move(200, 400); await page.mouse.wheel(0, -2000); }
    await page.waitForTimeout(400);
  };
  const open = async (summary) => {
    await top();
    await scrollTo(summary);
    await h.tap(summary);
    await page.waitForTimeout(700);
  };

  await h.waitText('Surfaces Demo');
  seen.home = (await h.text()).slice(0, 400);

  await open('What this host is and offers');
  await h.waitText('Capabilities');
  await h.shot('host');
  seen.host = (await h.text()).match(/(\d+) of 24/)?.[0];
  await h.back();

  await open('Rust as root');
  if (h.tier === 'browser') {
    await h.waitText('Not here');
  } else {
    await h.tap('sys.info');
    seen.sysInfo = (await h.waitText('sys.info in')).match(/sys\.info in [^|]*/)?.[0];
    await h.tap('Count primes');
    seen.primes = (await h.waitText('demo.primes done', 60000)).match(/demo\.primes done[^|]*/)?.[0];
  }
  await h.shot('ops');
  await h.back();

  await open('Commands, and how long');
  await h.tap('sleep 1; echo done');
  seen.shell = (await h.waitText('Exit ', 20000)).match(/Exit \d+[^|]*/)?.[0];
  await h.shot('shell');
  await h.back();

  await open('The Rust core drawing pixels');
  seen.fractal = (await h.waitText('Rust ', 30000).catch(() => 'no timing')).match(/Rust \d+ ms[^|]*/)?.[0];
  await h.shot('fractal');
  await h.back();

  await open('Safe area, keyboard');
  await h.shot('window');
  await h.back();

  await open('colours and dark mode');
  await h.shot('theme');
  await h.back();

  await open('Host toasts, or in-app');
  await h.tap('Show a toast');
  await h.shot('toast');
  await h.back();

  // Back from the first page leaves the app where the host allows it.
  await top();
  await h.back();
  seen.closedAfterBack = await h.closed();
  return seen;
};
