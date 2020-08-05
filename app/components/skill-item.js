import Component from '@glimmer/component';

export default class SkillItemComponent extends Component {
  get keywords() {
    return this.args.item.keywords.join(', ')
  }
}
