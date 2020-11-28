import Model, { attr } from '@ember-data/model';

export default class ResumeModel extends Model {
  @attr() basics;
  @attr() skills;
  @attr() education;
  @attr() work;
  @attr() projects;
}
