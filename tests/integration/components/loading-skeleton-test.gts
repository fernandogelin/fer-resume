import { module, test } from 'qunit';
import { setupRenderingTest } from 'fer-resume/tests/helpers';
import { render } from '@ember/test-helpers';
import LoadingSkeleton from 'fer-resume/components/loading-skeleton';

module('Integration | Component | loading-skeleton', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders skeleton placeholders', async function (assert) {
    await render(<template><LoadingSkeleton /></template>);

    assert.dom('[data-slot="skeleton"]').exists({ count: 11 });
  });
});
