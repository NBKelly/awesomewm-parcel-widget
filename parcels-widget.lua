local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

local HOME = os.getenv('HOME')
local ICON_DIR = HOME .. '/.config/awesome/parcelWidget/flags/'
local TRACKER_DIR = HOME .. '/.config/awesome/parcelWidget/config.py'
local PYTHON_DIR = HOME .. '/.config/awesome/parcelWidget/parcel.py'

local MINUTES_PER_UPDATE=5


local function parcelUrl(item)
   -- todo: make language modular
   return 'https://parcelsapp.com/en/tracking/' .. item.tracking
end

local function setupRows(menu_items, popup)
   local rows = { layout = wibox.layout.fixed.vertical }

   -- special row for adding/editing trackers
   local additemrow = wibox.widget {
      {
	 {
	    text = " [ Edit trackers ] ",
	    widget = wibox.widget.textbox
	 },
	 margins = 4,
	 widget = wibox.container.margin
      },
      bg = beautiful.bg_normal,
      widget = wibox.container.background
   }

   -- set mouse enter and mouse leave events to go to highlight the hovered row
   additemrow:connect_signal("mouse::enter", function(c)
				c:set_bg(beautiful.bg_focus)
   end)
   additemrow:connect_signal("mouse::leave", function(c)
				c:set_bg(beautiful.bg_normal)
   end)

   -- set click event to go to edit the tracker list
    additemrow:buttons(
       awful.util.table.join(
	  awful.button({}, 1, function()
		popup.visible = not popup.visible
		awful.spawn.with_shell('x-terminal-emulator -e nano ' .. TRACKER_DIR)
	  end)
       )
    )

   -- add special row at the top?
   table.insert(rows, additemrow)

   --traverse menu items and create each row
   for _, item in ipairs(menu_items) do
      local row = wibox.widget {
	 {
	    {
	       {
		  image = ICON_DIR .. item.from .. '.gif',
		  forced_width = 16,
		  forced_height = 12,
		  widget = wibox.widget.imagebox,
		  valign="top"
	       },
	       {
		  text = " -> ",
		  widget = wibox.widget.textbox,
		  valign="top"
	       },
	       {
		  image = ICON_DIR .. item.to .. '.gif',
		  forced_width = 16,
		  forced_height = 12,
		  valign="top",
		  widget = wibox.widget.imagebox
	       },
	       {
		  text = "  "..item.name.."  ",
		  widget = wibox.widget.textbox,
		  valign="top"
	       },
	       {
		  text = "("..item.days.." days, "..item.status..", "..item.lastupdate..")",
		  widget = wibox.widget.textbox,
		  valign="top"
	       },
	       spacing = 2,
	       layout = wibox.layout.fixed.horizontal
	    },
	    margins = 4,
	    widget = wibox.container.margin
	 },
	 bg = beautiful.bg_normal,
	 widget = wibox.container.background
      }
      table.insert(rows, row)

      -- set mouse enter and mouse leave events to go to highlight the hovered row
      row:connect_signal("mouse::enter", function(c)
			    c:set_bg(beautiful.bg_focus)
      end)
      row:connect_signal("mouse::leave", function(c)
			    c:set_bg(beautiful.bg_normal)
      end)

      -- set click event to go to the tracking page for the selected parcel
      row:buttons(
	 awful.util.table.join(
	    awful.button({}, 1, function()
		  popup.visible = not popup.visible
		  awful.spawn.with_shell('xdg-open ' .. parcelUrl(item))
	    end)
	 )
      )
   end

   popup:setup(rows)
end

local function updateWidget(mywidget, title, popup)
   --widget[0]
   -- fetch the menu items from the python script
   local cmdstr = 'bash -c "python3 '..PYTHON_DIR..'"'

   -- lines per parcel: 7
   mywidget = awful.widget.watch(cmdstr, 60*5,
				 function(widget, stdout)
				    local lines = {}
				    for s in stdout:gmatch("[^\r\n]+") do
				         table.insert(lines, s)
				    end

				    local itemCount = #lines//7
				    local menu_items = {}

				    for i=0,itemCount-1 do
				       menu_items[i+1] = {from=lines[7*i + 1],
							  to=lines[7*i + 2],
							  name=lines[7*i + 3],
							  lastupdate=lines[7*i + 4],
							  days=lines[7*i + 5],
							  tracking=lines[7*i + 6],
							  status=lines[7*i + 7]}
				    end

				    -- use the menu items to make the rows
				    setupRows(menu_items, popup)

				  -- also setup the header
				    title:set_text(" ["..math.floor(itemCount).." packages] ")

				 end,
				 mywidget)

   return mywidget
end

function parcelsWidget()
   local titlewidget = wibox.widget {
      markup = "[0 packages]",
      resize = true,
      widget = wibox.widget.textbox
   }

   local mywidget = wibox.widget {
      titlewidget,
      margins = 2,
      widget = wibox.container.margin
   }

  local menu_items = {}

  local popup = awful.popup {
     ontop = true,
     visible = false,
     shape = function(cr, width, height)
	gears.shape.rounded_rect(cr, width, height, 4)
     end,
     border_width = 1,
     border_color = beautiful.bg_focus,
     maximum_width = 400,
     offset = { y = 5 },
     widget = {}
  }

  setupRows(menu_items, popup)

  --toggle popup visibility on mouse click
  mywidget:buttons(
     awful.util.table.join(
	awful.button({}, 1, function()
	      if popup.visible then
		 popup.visible = not popup.visible
	      else
		 popup:move_next_to(mouse.current_widget_geometry)
	      end
     end))
  )

  -- set up the listener to the python script
  mywidget = updateWidget(mywidget, titlewidget, popup)

  return mywidget
end
