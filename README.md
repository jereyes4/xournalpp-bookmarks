# xournalpp-bookmarks
A plugin for Xournalpp that allows bookmarks.

It does so by creating invisible layers that act as bookmarks. It comes with toolbar icons, and it can also export to pdf with the bookmarks included.

This plugin should work at least on version 1.2.3.

# Instalation
Copy the folder Bookmarks into the plugin folder of Xournalpp.

In order to use the GUI to manage bookmarks, lua-lgi is required. On Windows one can follow [these instructions](https://github.com/xournalpp/xournalpp/discussions/4522#discussioncomment-8789465).

In order to export to pdf with bookmarks, [pdftk](https://www.pdflabs.com/tools/pdftk-server/) is required. On some Linux distributions, it seems to be available as `pdftk-java`.
