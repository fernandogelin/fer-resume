import Model, { attr, belongsTo, hasMany } from '@ember-data/model'

export default class PersonModel extends Model {
  @attr('string') name
  @attr('string') label
  @attr('string') email
  @attr('string') picture
  @attr('string') phone
  @attr('string') website
  @attr('string') summary
  @attr('string') phonetic_name
  @hasMany('profile') profiles
  @belongsTo('location') location
  @belongsTo('resume') resume
}
