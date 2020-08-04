import { helper } from '@ember/component/helper';

export default helper(function lower(params/*, hash*/) {
  return params[0].toLowerCase();
});
