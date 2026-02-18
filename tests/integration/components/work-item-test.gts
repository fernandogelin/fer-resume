import { module, test } from 'qunit';
import { setupRenderingTest } from 'fer-resume/tests/helpers';
import { render } from '@ember/test-helpers';
import WorkItem from 'fer-resume/components/work-item';
import type { WorkEntry } from 'fer-resume/types/resume';

module('Integration | Component | work-item', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders work entry details', async function (assert) {
    const work: WorkEntry = {
      company: 'Acme Corp',
      position: 'Senior Engineer',
      startDate: '2020-01-01',
      endDate: '2023-12-31',
      summary: 'Built amazing things',
    };

    await render(<template><WorkItem @model={{work}} /></template>);

    assert.dom('h4').hasText(/Acme Corp/);
    assert.dom('p').includesText('Senior Engineer');
    assert.dom('.text-sm.mt-2').hasText('Built amazing things');
  });
});
