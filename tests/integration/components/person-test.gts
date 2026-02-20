import { module, test } from 'qunit';
import { setupRenderingTest } from 'fer-resume/tests/helpers';
import { render } from '@ember/test-helpers';
import Person from 'fer-resume/components/person';
import type { Basics } from 'fer-resume/types/resume';

module('Integration | Component | person', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders person info', async function (assert) {
    const person: Basics = {
      name: 'John Doe',
      phonetic_name: 'jɑːn doʊ',
      label: 'Software Engineer',
      location: 'San Francisco, CA',
      email: 'john.doe@example.com',
      profiles: [],
    };

    await render(<template><Person @person={{person}} /></template>);

    assert.dom('h3').hasText('John Doe');
    assert.dom('p').exists({ count: 2 });
    assert.dom('.text-sm.italic').hasText('jɑːn doʊ');
    assert.dom('.text-primary').hasText('Software Engineer');
  });
});
