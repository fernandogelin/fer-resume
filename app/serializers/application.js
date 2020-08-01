import JSONSerializer from '@ember-data/serializer/json'
import { camelize } from '@ember/string'
import DS from 'ember-data'

export default class ApplicationSerializer extends JSONSerializer.extend(
  DS.EmbeddedRecordsMixin
) {
  keyForAttribute(key) {
    return camelize(key)
  }

  attrs = {
    resume: { embedded: 'always' }
  }

  normalizeResponse(store, primaryModelClass, payload, id, requestType) {
    const resume = payload.files['resume.json']
    if (payload.id === 'fbc7c5a8630ee55274ec7ee89f62dd5f') {
      payload.locale = 'en-se'
    }
    if (payload.id === 'da99c3da93c806d4d6319279c844ad72') {
      payload.locale = 'pt-br'
    }
    resume.id = payload.locale
    payload.resume = resume

    return super.normalizeResponse(
      store,
      primaryModelClass,
      payload,
      id,
      requestType
    )
  }
}
