import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import type { TOC } from '@ember/component/template-only';
import Icon from 'fer-resume/components/icon';
import type ApplicationController from 'fer-resume/controllers/application';
import { FileDown } from 'lucide-static';
import { t } from 'ember-intl';
import {
  ContextMenu,
  ContextMenuTrigger,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuLabel,
  ContextMenuSeparator,
  ContextMenuRadioGroup,
  ContextMenuRadioItem,
} from 'fer-resume/components/ui/context-menu';

interface ApplicationTemplateSignature {
  Args: {
    controller: ApplicationController;
  };
}

const ApplicationTemplate: TOC<ApplicationTemplateSignature> = <template>
  {{pageTitle 'Fernando Gelin'}}

  <header class='border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-10 print:hidden'>
    <div class='flex items-center px-4 md:px-6 py-2 max-w-5xl mx-auto'>
      <ContextMenu>
        <ContextMenuTrigger
          class='text-sm font-medium text-muted-foreground transition-colors hover:text-foreground [&.active]:text-primary [&.active]:font-semibold'
        >
          Fernando Gelin
        </ContextMenuTrigger>
        <ContextMenuContent class='min-w-56'>
          <ContextMenuLabel>Fernando Gelin</ContextMenuLabel>
          <ContextMenuItem @asChild={{true}} as |item|>
            <LinkTo @route='index' class={{item.classes}}>
              {{t 'nav.resume'}}
            </LinkTo>
          </ContextMenuItem>

          <ContextMenuSeparator />
          <ContextMenuLabel>{{t 'nav.projects'}}</ContextMenuLabel>

          <ContextMenuItem @asChild={{true}} as |item|>
            <LinkTo @route='projects.seat-map' class={{item.classes}}>
              {{t 'nav.seatMap'}}
            </LinkTo>
          </ContextMenuItem>

          <ContextMenuItem @asChild={{true}} as |item|>
            <LinkTo @route='projects.earthquake-visualizer' class={{item.classes}}>
              {{t 'nav.earthquakeVisualizer'}}
            </LinkTo>
          </ContextMenuItem>

          <ContextMenuSeparator />
          <ContextMenuLabel>{{t 'actions.choose_language'}}</ContextMenuLabel>
          <ContextMenuRadioGroup
            @value={{@controller.currentLocale}}
            @onValueChange={{@controller.setLocale}}
            as |currentLocale setLocale|
          >
            <ContextMenuRadioItem
              @value='en-se'
              @currentValue={{currentLocale}}
              @setValue={{setLocale}}
            >
              {{t 'locales.en-se'}}
            </ContextMenuRadioItem>
            <ContextMenuRadioItem
              @value='pt-br'
              @currentValue={{currentLocale}}
              @setValue={{setLocale}}
            >
              {{t 'locales.pt-br'}}
            </ContextMenuRadioItem>
            <ContextMenuRadioItem
              @value='es'
              @currentValue={{currentLocale}}
              @setValue={{setLocale}}
            >
              {{t 'locales.es'}}
            </ContextMenuRadioItem>
            <ContextMenuRadioItem
              @value='fr'
              @currentValue={{currentLocale}}
              @setValue={{setLocale}}
            >
              {{t 'locales.fr'}}
            </ContextMenuRadioItem>
          </ContextMenuRadioGroup>

          <ContextMenuSeparator />
          <ContextMenuLabel>{{t 'actions.download'}}</ContextMenuLabel>
          <ContextMenuItem @onSelect={{@controller.downloadPdf}}>
            <Icon @svg={{FileDown}} @size={{16}} />
            {{t 'actions.download'}}
          </ContextMenuItem>
        </ContextMenuContent>
      </ContextMenu>
    </div>
  </header>

  {{outlet}}
</template>;

export default ApplicationTemplate;
