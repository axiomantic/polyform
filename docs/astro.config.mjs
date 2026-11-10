// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import mermaid from 'astro-mermaid';
import starlightImageZoom from 'starlight-image-zoom';

export default defineConfig({
  site: 'https://axiomantic.github.io',
  base: '/polyform',
  integrations: [
    mermaid(),
    starlight({
      title: 'Polyform',
      social: [
        {
          icon: 'github',
          label: 'GitHub',
          href: 'https://github.com/axiomantic/polyform',
        },
      ],
      plugins: [starlightImageZoom()],
      sidebar: [
        {
          label: 'Guides',
          items: [
            { label: 'Getting Started', slug: 'guide/getting-started' },
            { label: 'Flavors & Composable Facets', slug: 'guide/flavors-and-facets' },
          ],
        },
        {
          label: 'Reference',
          items: [
            { label: 'Copier Options Reference', slug: 'reference/copier-options' },
            { label: 'Downstream Documentation Architecture', slug: 'reference/downstream-docs' },
          ],
        },
      ],
    }),
  ],
});
