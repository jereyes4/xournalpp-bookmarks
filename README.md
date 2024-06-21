# xournalpp-bookmarks
A plugin for Xournalpp that allows bookmarks.

It does so by creating invisible layers that act as bookmarks. It comes with toolbar icons, and it can also export to pdf with the bookmarks included.

This plugin should work at least on version 1.2.3.

# Instalation
Copy the folder Bookmarks into the plugin folder of Xournalpp.

In order to export to pdf with bookmarks, [pdftk](https://www.pdflabs.com/tools/pdftk-server/) is required. On some Linux distributions, it seems to be available as `pdftk-java`.

In order to use the GUI to manage bookmarks, lua-lgi is required. On Windows one can follow [these instructions](https://github.com/xournalpp/xournalpp/discussions/4522#discussioncomment-8789465) (see below).

# lgi on Windows
I had some trouble following the above instructions. Here's my fix:

- After installing the mingw packages, one should quit the MSYS2 terminal and use the MSYS2 MINGW64 instead.
- `mingw-w64-x86_64-luarocks` is actually called `mingw-w64-x86_64-lua-luarocks`
- `mingw-w64-x86_64-gobject-introspection` installs the dependancy `mingw-w64-x86_64-gobject-introspection-runtime`, which in its version 1.80.1 breaks something called `g_once_init_enter_pointer` in `libgirepository-1.0-1.dll`, whatever that is. If this is a problem, a dirty way to fix this, is to install everything following the steps as before, and then search in the [MSYS2 repo](https://repo.msys2.org/mingw/mingw64/) for the previous version of the problematic package, namely,

      mingw-w64-x86_64-gobject-introspection-runtime-1.78.1-1-any.pkg.tar

  Find the file `\mingw64\bin\libgirepository-1.0-1.dll` inside that archive and replace `C:\msys64\mingw64\bin\libgirepository-1.0-1.dll` with it. (You might want to rename the old one just in case, say `libgirepository-1.0-1.dll.old`).

And voilà.
