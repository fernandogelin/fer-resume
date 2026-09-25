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
      pronunciation_english: 'john doh',
      label: 'Software Engineer',
      location: 'San Francisco, CA',
      email: 'john.doe@example.com',
      profiles: [],
    };

    await render(<template><Person @person={{person}} /></template>);

    assert.dom('h3').hasText('John Doe');
    assert.dom('p').exists({ count: 3 });
    assert.dom('p').hasText('jɑːn doʊ');
    assert.dom('p[lang="en"]').hasText('john doh');
    assert.dom('button[aria-label="Hear name pronunciation"]').exists();
    assert.dom('audio[src="/audio/fernando-gelin.wav"]').exists();
    assert.dom('.text-primary').hasText('Software Engineer');
  });
});
