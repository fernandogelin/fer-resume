import { module, test } from 'qunit';
import { setupTest } from 'fer-resume/tests/helpers';
import type ResumeService from 'fer-resume/services/resume';

module('Unit | Service | resume', function (hooks) {
  setupTest(hooks);

  test('it exists', function (assert) {
    const service = this.owner.lookup('service:resume') as ResumeService;
    assert.ok(service);
  });

  test('it has resume data loaded', function (assert) {
    const service = this.owner.lookup('service:resume') as ResumeService;
    assert.ok(service.data);
    assert.strictEqual(service.data.basics.name, 'Fernando Gelin');
    assert.ok(service.data.work.length > 0);
    assert.ok(service.data.skills.length > 0);
    assert.ok(service.data.publications.length > 0);
  });
});
