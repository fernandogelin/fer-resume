import { module, test } from 'qunit';
import { setupRenderingTest } from 'fer-resume/tests/helpers';
import { render } from '@ember/test-helpers';
import EducationItem from 'fer-resume/components/education-item';
import type { EducationEntry } from 'fer-resume/types/resume';

module('Integration | Component | education-item', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders education entry', async function (assert) {
    const education: EducationEntry = {
      institution: 'MIT',
      area: 'Computer Science',
      studyType: 'PhD',
      startDate: '2015-09-01',
      endDate: '2020-05-15',
    };

    await render(<template><EducationItem @model={{education}} /></template>);

    assert.dom('h4').hasText(/MIT/);
    assert.dom('p').includesText('Computer Science');
    assert.dom('p').includesText('PhD');
  });

  test('it renders thesis when provided', async function (assert) {
    const education: EducationEntry = {
      institution: 'MIT',
      area: 'Computer Science',
      studyType: 'PhD',
      startDate: '2015-09-01',
      endDate: '2020-05-15',
      thesis: 'On the nature of computation',
    };

    await render(<template><EducationItem @model={{education}} /></template>);

    const text = document.body.textContent ?? '';
    assert.ok(text.includes('On the nature of computation'));
  });
});
