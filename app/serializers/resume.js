import RESTSerializer from '@ember-data/serializer/rest';

export default class ResumeSerializer extends RESTSerializer {
    normalizeResponse(store, primaryModelClass, payload, id, requestType) {
        const newPayload = { resume: JSON.parse(payload.files['resume.json'].content) };
        return super.normalizeResponse(store, primaryModelClass, newPayload, id, requestType);
    }
}
