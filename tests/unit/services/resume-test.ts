import { module, test } from 'qunit';
import { setupTest } from 'fer-resume/tests/helpers';
import type ResumeService from 'fer-resume/services/resume';

module('Unit | Service | resume', function (hooks) {
  setupTest(hooks);

  test('it exists', function (assert) {
    const service = this.owner.lookup('service:resume') as ResumeService;
    assert.ok(service);
  });

  test('it starts with null data', function (assert) {
    const service = this.owner.lookup('service:resume') as ResumeService;
    assert.strictEqual(service.data, null);
    assert.false(service.isLoading);
    assert.strictEqual(service.error, null);
  });
});
