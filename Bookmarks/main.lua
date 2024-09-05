
utf8_to_html = require("utf8_to_html")

DEFAULT_EXPORT_PATH = "/tmp/temp"

-- Register Toolbar
function initUi()

  app.registerUi({menu="Previous Bookmark", toolbarId="CUSTOM_PREVIOUS_BOOKMARK", callback="search_bookmark", mode=-1, iconName="go-previous"})
  app.registerUi({menu="New Bookmark", toolbarId="CUSTOM_NEW_BOOKMARK", callback="new_bookmark", iconName="bookmark-new-symbolic"})
  app.registerUi({menu="Next Bookmark", toolbarId="CUSTOM_NEXT_BOOKMARK", callback="search_bookmark", mode=1, iconName="go-next"})
  app.registerUi({menu="View Bookmarks", toolbarId="CUSTOM_VIEW_BOOKMARKS", callback = "view_bookmarks", iconName="user-bookmarks-symbolic"})
  app.registerUi({menu="Export to PDF with Bookmarks", toolbarId="CUSTOM_EXPORT_WITH_BOOKMARKS", callback="export", iconName="xopp-document-export-pdf"})

  sep = package.config:sub(1,1)
  sourcePath = debug.getinfo(1).source:match("@?(.*" .. sep .. ")")
  if sep == "\\" then
    DEFAULT_EXPORT_PATH = "%TEMP%\\temp"
  end
end

function new_bookmark(name)

  local structure = app.getDocumentStructure()
  
  local currentPage = structure.currentPage
  local currentLayerID = structure.pages[currentPage].currentLayer

  app.layerAction("ACTION_NEW_LAYER")
  if type(name) == "string" then
    app.setCurrentLayerName("Bookmark::" .. name)
  else
    app.setCurrentLayerName("Bookmark::")
  end
  app.setLayerVisibility(false)
  app.setCurrentLayer(currentLayerID)
end

function delete_layer(page, layerID)
  local structure = app.getDocumentStructure()

  app.setCurrentPage(page)
  local currentLayerID = structure.pages[page].currentLayer
  app.setCurrentLayer(layerID)
  app.layerAction("ACTION_DELETE_LAYER")
  if currentLayerID > layerID then
    app.setCurrentLayer(currentLayerID - 1)
  else
    app.setCurrentLayer(currentLayerID)
  end
end

-- mode = -1 for searching backwards, or 1 for searching forwards
function search_bookmark(mode)

  local structure = app.getDocumentStructure()
  local currentPage = structure.currentPage
  local numPages = #structure.pages
  local page = currentPage
  local nextBookmark

  repeat
    page = page + mode
    if page == numPages + 1 then page = 1 end
    if page == 0 then page = numPages end
    for u,v in pairs(structure.pages[page].layers) do
      if v.name:sub(1,10) == "Bookmark::" then
        nextBookmark = page
        break
      end
    end
    if nextBookmark ~= nil then break end
  until page == currentPage

  if nextBookmark == nil then
    app.msgbox("No bookmark found.", {[1] = "Ok"})
    return
  end

  app.setCurrentPage(nextBookmark)
  app.scrollToPage(nextBookmark)

end

function view_bookmarks()

  local hasLgi, lgi = pcall(require, "lgi")
  if not hasLgi then
    app.msgbox("You need to have the Lua lgi-module installed and included in your Lua package path in order view bookmarks\n", {[1]="OK"})
    return
  end


  local Gtk = lgi.require("Gtk", "3.0")
  local Gdk = lgi.Gdk
  local assert = lgi.assert
  local builder = Gtk.Builder()
  assert(builder:add_from_file(sourcePath .. "dlgBookmarks.glade"))
  local ui = builder.objects
  local dialog = ui.dlgBookmarks

  local column = {
    PAGE = 1,
    DISPLAY_NAME = 2,
    NAME = 3,
    LAYER_ID = 4,
  }

  local store = Gtk.ListStore.new {
    [column.PAGE] = lgi.GObject.Type.UINT,
    [column.DISPLAY_NAME] = lgi.GObject.Type.STRING,
    [column.NAME] = lgi.GObject.Type.STRING,
    [column.LAYER_ID] = lgi.GObject.Type.UINT,
  }

  -- they're going to be set immediately after
  local structure
  local numPages

  local function updateTable()
    structure = app.getDocumentStructure()
    numPages = #structure.pages
    store:clear()
    for page=1, numPages do
      for u,v in pairs(structure.pages[page].layers) do
        if v.name:sub(1,10) == "Bookmark::" then
          if v.name:sub(11) == "" then
            store:append({page, "(No name)", "", u})
          else
            store:append({page, v.name:sub(11), v.name:sub(11), u})
          end
        end
      end
    end
  end

  updateTable()

  local treeView = Gtk.TreeView {
    model = store,
    Gtk.TreeViewColumn {
      title = "Page",
      sizing = "FIXED",
      fixed_width = 70,
      {
        Gtk.CellRendererText {},
        {text = column.PAGE},
      },
    },
    Gtk.TreeViewColumn {
      title = "Name",
      {
        Gtk.CellRendererText { id = "nameColumn"},
        {text = column.DISPLAY_NAME},
      },
    },
  }

  ui.scrolledWindow:add(treeView)

  function ui.btnNew.on_clicked()
    local newPage, newName = edit_bookmark("New Bookmark", 1, "")
    if newPage == nil then return end
    app.setCurrentPage(newPage)
    new_bookmark(newName)
    updateTable()
  end

  function ui.btnEdit.on_clicked()
    local model, data = treeView:get_selection():get_selected()
    if data == nil then return end
    local oldPage, oldName, oldLayerID = model[data][column.PAGE], model[data][column.NAME], model[data][column.LAYER_ID]
    local newPage, newName = edit_bookmark("Edit Bookmark", oldPage, oldName)

    if newPage == nil then return end
    if oldPage == newPage then
      app.setCurrentPage(oldPage)
      local currentLayerID = structure.pages[oldPage].currentLayer
      app.setCurrentLayer(oldLayerID)
      app.setCurrentLayerName("Bookmark::" .. newName)
      app.setCurrentLayer(currentLayerID)
    else
      delete_layer(oldPage, oldLayerID)
      app.setCurrentPage(newPage)
      new_bookmark(newName)
    end
    updateTable()
  end

  function ui.btnDelete.on_clicked()
    local model, data = treeView:get_selection():get_selected()
    if data == nil then return end
    local page, layerID = model[data][column.PAGE], model[data][column.LAYER_ID]
    delete_layer(page, layerID)
    updateTable()
  end

  function ui.btnJumpTo.on_clicked()
    local model, data = treeView:get_selection():get_selected()
    if data == nil then return end
    local page = model[data][column.PAGE]
    app.setCurrentPage(page)
    app.scrollToPage(page)
  end

  function ui.btnDone.on_clicked()
    dialog:destroy()
  end
  
  function edit_bookmark(title, defaultPage, defaultName)
    local builder = Gtk.Builder()
    assert(builder:add_from_file(sourcePath .. "dlgEdit.glade"))
    local ui = builder.objects
    local dialog = ui.dlgEdit

    returnData = {}

    dialog:set_title(title)
    ui.spbtPageNumber:set_range(1,numPages)
    ui.spbtPageNumber:set_increments(1,10)
    ui.spbtPageNumber:set_value(defaultPage)
    ui.entryName:set_text(defaultName)

    function ui.btnEditOk.on_clicked()
      returnData[1] = math.floor(ui.spbtPageNumber:get_value() + 0.1)
      returnData[2] = ui.entryName:get_text()
      dialog:destroy()
    end

    function ui.btnEditCancel.on_clicked()
      dialog:destroy()
    end

    dialog:run()
    dialog:destroy()
    return table.unpack(returnData)
  end

  dialog:show_all()
end

function export()

  if not os.execute("pdftk") then
    app.msgbox("pdftk is missing.", {[1] = "OK"})
    return
  end
  local structure = app.getDocumentStructure()

  local defaultName = DEFAULT_EXPORT_PATH
  local xopp_name = structure.xoppFilename
  if xopp_name ~= nil and xopp_name ~= "" then
    defaultName = xopp_name:match("(.+)%..+$")
  end
  defaultName = defaultName .. "_export.pdf"
  local path = app.saveAs(defaultName)
  if path == nil then return end
  
  local tempData = os.tmpname()
  if sep == "\\" then tempData = tempData:sub(2) end --on windows, the first character breaks tmpname for some reason
  local tempPdf = tempData .. "_1337__.pdf" -- if this breaks something, it'd be very impressive
  
  app.export({outputFile = tempPdf})

  os.execute("pdftk \"" .. tempPdf .. "\" dump_data output \"" .. tempData .. "\"")
  
  local file = io.open(tempData,"a+")
  local bookmarkTable = {}
  local numPages = #structure.pages
  for page=1, numPages do
    for u,v in pairs(structure.pages[page].layers) do
      if v.name:sub(1,10) == "Bookmark::" then
        table.insert(bookmarkTable,{page = page, name = utf8_to_html(v.name:sub(11))})
      end
    end
  end
  for u, bookmark in pairs(bookmarkTable) do
    file:write("BookmarkBegin\n")
    file:write("BookmarkTitle: " .. bookmark.name .. "\n")
    file:write("BookmarkLevel: 1\n")
    file:write("BookmarkPageNumber: " .. bookmark.page .. "\n")
  end
  file:close()

  os.execute("pdftk \"" .. tempPdf .. "\" update_info \"" .. tempData .. "\" output \"" .. path .."\"")

  os.remove(tempData)
  os.remove(tempPdf)
end
