import { module, test } from 'qunit';
import { setupTest } from 'ember-qunit';

module('Unit | Route | resume/en', function(hooks) {
  setupTest(hooks);

  test('it exists', function(assert) {
    let route = this.owner.lookup('route:resume/en');
    assert.ok(route);
  });
});
