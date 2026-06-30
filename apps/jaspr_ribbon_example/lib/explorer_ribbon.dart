import 'package:jaspr_ribbon_toolbar/model.dart';

/// The Windows-Explorer-style ribbon used by the demo — a Dart mirror of
/// `examples/explorer.ribbon` (Home + View + a contextual Format tab).
RibbonDefinition get explorerRibbon => RibbonDefinition(
  version: '2.0',
  projectType: 'web',
  tabs: [
    RibbonTab(
      caption: 'Home',
      groups: [
        RibbonGroup(
          caption: 'Clipboard',
          items: [
            RibbonItem.large(
              caption: 'Paste',
              tag: 'clipboard.paste',
              iconKey: 'paste',
              tooltipText: 'Paste from clipboard',
            ),
            RibbonItem.small(
              caption: 'Cut',
              tag: 'clipboard.cut',
              iconKey: 'cut',
            ),
            RibbonItem.small(
              caption: 'Copy',
              tag: 'clipboard.copy',
              iconKey: 'copy',
            ),
            RibbonItem.small(
              caption: 'Copy path',
              tag: 'clipboard.copy_path',
              iconKey: 'copy-path',
            ),
          ],
        ),
        RibbonGroup(
          caption: 'Organize',
          items: [
            RibbonItem.splitButton(
              caption: 'Delete',
              tag: 'organize.delete',
              iconKey: 'delete',
              menuItems: const [
                RibbonMenuItem(
                  caption: 'Recycle',
                  tag: 'organize.delete.recycle',
                ),
                RibbonMenuItem(
                  caption: 'Permanently delete',
                  tag: 'organize.delete.permanent',
                ),
              ],
            ),
            RibbonItem.small(
              caption: 'Rename',
              tag: 'organize.rename',
              iconKey: 'rename',
            ),
          ],
        ),
      ],
    ),
    RibbonTab(
      caption: 'View',
      groups: [
        RibbonGroup(
          caption: 'Panes',
          items: [
            RibbonItem.splitButton(
              caption: 'Navigation pane',
              tag: 'view.nav',
              iconKey: 'nav-pane',
              menuItems: const [
                RibbonMenuItem(
                  caption: 'Navigation pane',
                  tag: 'view.nav.toggle',
                ),
                RibbonMenuItem(
                  caption: 'Expand to open folder',
                  tag: 'view.nav.expand',
                ),
              ],
            ),
            RibbonItem.toggle(
              caption: 'Preview pane',
              tag: 'view.preview',
              iconKey: 'preview-pane',
              isActive: false,
            ),
            RibbonItem.toggle(
              caption: 'Details pane',
              tag: 'view.details',
              iconKey: 'details-pane',
              isActive: false,
            ),
          ],
        ),
        RibbonGroup(
          caption: 'Show/hide',
          items: [
            RibbonItem.checkBox(
              caption: 'File name extensions',
              tag: 'view.ext',
              isChecked: false,
            ),
            RibbonItem.checkBox(
              caption: 'Hidden items',
              tag: 'view.hidden',
              isChecked: true,
            ),
            const RibbonItem.separator(),
            RibbonItem.small(
              caption: 'Hide selected',
              tag: 'view.hide',
              iconKey: 'hide',
            ),
          ],
        ),
      ],
    ),
    RibbonTab.contextual(
      caption: 'Format',
      contextGroup: 'Picture Tools',
      accentColor: 0xFF2E7D32,
      groups: [
        RibbonGroup(
          caption: 'Picture Styles',
          items: [
            RibbonItem.large(caption: 'Crop', tag: 'pic.crop', iconKey: 'crop'),
          ],
        ),
      ],
    ),
  ],
);
