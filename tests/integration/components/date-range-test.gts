import { module, test } from 'qunit';
import { setupRenderingTest } from 'fer-resume/tests/helpers';
import { render } from '@ember/test-helpers';
import DateRange from 'fer-resume/components/date-range';

module('Integration | Component | date-range', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders a date range with start and end', async function (assert) {
    await render(<template><DateRange @startDate='2020-01-15' @endDate='2023-06-30' /></template>);

    assert.dom('span').exists();
    const text = document.body.textContent?.trim() ?? '';
    assert.ok(text.includes('2020'), 'contains start year');
    assert.ok(text.includes('2023'), 'contains end year');
    assert.ok(text.includes('–'), 'contains separator');
  });

  test('it preserves the month for first-of-month dates', async function (assert) {
    await render(<template><DateRange @startDate='2007-12-01' @endDate='2009-05-01' /></template>);

    assert.dom('span').hasText('Dec 2007 – May 2009');
  });

  test('it renders "present" when endDate is null', async function (assert) {
    await render(<template><DateRange @startDate='2020-01-15' @endDate={{null}} /></template>);

    const text = document.body.textContent?.trim() ?? '';
    assert.ok(text.includes('present'), 'shows present for null end date');
  });
});
