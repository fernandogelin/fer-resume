import Model, { attr, belongsTo } from '@ember-data/model'

export default class WorkModel extends Model {
  @attr('string') company
  @attr('string') position
  @attr('string') website
  @attr('string') summary
  @attr('string') highlights
  @attr('date') startDate
  @attr('date') endDate
  @belongsTo('resume') resume
}
