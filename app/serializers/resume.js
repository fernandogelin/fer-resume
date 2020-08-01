import ApplicationSerializer from './application'

export default class ResumeSerializer extends ApplicationSerializer {
  attrs = {
    education: { embedded: 'always' },
    work: { embedded: 'always' },
    skills: { embedded: 'always' },
    interests: { embedded: 'always' },
    languages: { embedded: 'always' },
    person: { embedded: 'always' }
  }

  normalize(type, hash) {
    const content = JSON.parse(hash.content)

    const education = content.education
    const work = content.work
    const interests = content.interests
    const skills = content.skills
    const languages = content.languages

    ;[work, interests, education, skills, languages].map(attr =>
      attr.map((item, i) => (item.id = i))
    )
    content.basics.id = content.basics.name.toLowerCase().replace(' ', '_')
    hash.person = content.basics
    hash.education = education
    hash.work = work
    hash.interests = interests
    hash.skills = skills
    hash.languages = languages
    return super.normalize(...arguments)
  }
}
