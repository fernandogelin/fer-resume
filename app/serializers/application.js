import JSONSerializer from "@ember-data/serializer/json";
import { camelize } from "@ember/string";
import DS from "ember-data";

export default class ApplicationSerializer extends JSONSerializer.extend(
  DS.EmbeddedRecordsMixin
) {
  keyForAttribute(key) {
    return camelize(key);
  }

  attrs = {
    resume: { embedded: "always" }
  };

  normalizeResponse(store, primaryModelClass, payload, id, requestType) {
    const resume = payload.files["resume.json"];
    resume.id = "1";
    payload.resume = resume;

    return super.normalizeResponse(
      store,
      primaryModelClass,
      payload,
      id,
      requestType
    );
  }
}
