import Model, { attr, belongsTo } from '@ember-data/model'

export default class EducationModel extends Model {
  @attr('string') area
  @attr('string') institution
  @attr('string') studyType
  @attr('date') startDate
  @attr('date') endDate
  @attr('string') thesis
  @belongsTo('resume') resume
}
