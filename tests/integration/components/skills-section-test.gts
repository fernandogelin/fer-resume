import { module, test } from 'qunit';
import { setupRenderingTest } from 'fer-resume/tests/helpers';
import { render } from '@ember/test-helpers';
import SkillsSection from 'fer-resume/components/skills-section';
import type { Skill } from 'fer-resume/types/resume';

module('Integration | Component | skills-section', function (hooks) {
  setupRenderingTest(hooks);

  test('it renders skills with keywords', async function (assert) {
    const skills: Skill[] = [
      { name: 'Frontend', keywords: ['React', 'TypeScript'] },
      { name: 'Backend', keywords: ['Node.js', 'Python'] },
    ];

    await render(
      <template><SkillsSection @skills={{skills}} /></template>,
    );

    assert.dom('[data-slot="card"]').exists();
    assert.dom('.text-sm.font-medium').exists({ count: 2 });
    assert.dom('[data-slot="badge"]').exists({ count: 4 });
  });
});
