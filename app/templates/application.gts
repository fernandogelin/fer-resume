import { pageTitle } from 'ember-page-title';
import { LinkTo } from '@ember/routing';
import LocaleSwitcher from 'fer-resume/components/locale-switcher';
import Icon from 'fer-resume/components/icon';
import { FileDown } from 'lucide-static';
import { t } from 'ember-intl';
import { on } from '@ember/modifier';

<template>
  {{pageTitle 'Fernando Gelin'}}

  <header class='border-b border-border bg-card/50 backdrop-blur-sm sticky top-0 z-10 print:hidden'>
    <div class='flex items-center justify-between px-4 md:px-6 py-2 max-w-5xl mx-auto'>
      <nav class='flex items-center gap-4'>
        <LinkTo
          @route='index'
          class='text-sm font-medium text-muted-foreground transition-colors hover:text-foreground [&.active]:text-primary [&.active]:font-semibold'
        >
          {{t 'nav.resume'}}
        </LinkTo>
        <LinkTo
          @route='projects.seat-map'
          class='text-sm font-medium text-muted-foreground transition-colors hover:text-foreground [&.active]:text-primary [&.active]:font-semibold'
        >
          {{t 'nav.seatMap'}}
        </LinkTo>
      </nav>
      <div class='flex items-center gap-3'>
        {{#if @controller.isResumeRoute}}
          <button
            type='button'
            class='inline-flex items-center gap-2 text-sm font-medium text-primary hover:text-primary/80 transition-colors cursor-pointer'
            {{on 'click' @controller.downloadPdf}}
          >
            <Icon @svg={{FileDown}} @size={{16}} />
            {{t 'actions.download'}}
          </button>
        {{/if}}
        <LocaleSwitcher
          @currentLocale={{@controller.currentLocale}}
          @onSwitch={{@controller.switchLocale}}
        />
      </div>
    </div>
  </header>

  {{outlet}}
</template>
