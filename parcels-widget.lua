local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local naughty = require("naughty")
local beautiful = require("beautiful")

local HOME = os.getenv('HOME')
local ICON_DIR = HOME .. '/.config/awesome/parcelWidget/flags/'
local TRACKER_DIR = HOME .. '/.config/awesome/parcelWidget/trackers.csv'
local PYTHON_DIR = HOME .. '/.config/awesome/parcelWidget/parcel.py'
--local STATUS_ICON_DIR = HOME .. '/.config/awesome/parcelWidget/icons/'
--local MINUTES_PER_UPDATE=5
local NOTIFY_TIMEOUT_DURATION=30



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
      local innertext = "("..item.days.." days, "..item.status..", "..item.lastupdate..")"
      if item.status == "NOT YET SCANNED" then
	 innertext = "("..item.status..")"
      end

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
	       --{
	       --  image = STATUS_ICON_DIR .. item.status .. '.png',
	       --  forced_width = 16,
	       --  forced_height = 12,
	       --  valign = "top",
	       --  widget = wibox.widget.imagebox
	       --},
	       {
		  text = "  "..item.name.."  ",
		  widget = wibox.widget.textbox,
		  valign="top"
	       },
	       {
		  text = innertext,
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

local function notify(title, text, item)
   naughty.notify{
      --icon = HOME_DIR ..'/.config/awesome/awesome-wm-widgets/gerrit-widget/gerrit_icon.svg',
      title = title .. " - " .. item.status,
      text = text,
      timeout = NOTIFY_TIMEOUT_DURATION,
      icon = ICON_DIR .. item.to .. '.gif'
   }
end

local tracked_delivered = 0
local last_menu_items = {}

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

				    local delivered = 0
				    local pickup = 0

				    for i=0,itemCount-1 do
				       menu_items[i+1] = {from=lines[7*i + 1],
							  to=lines[7*i + 2],
							  name=lines[7*i + 3],
							  lastupdate=lines[7*i + 4],
							  days=lines[7*i + 5],
							  tracking=lines[7*i + 6],
							  status=lines[7*i + 7]}

				       -- make a note of how many are delivered or to be picked up
				       if lines[7*i + 7] == 'delivered' then
					  delivered = delivered + 1
				       end
				       if lines[7*i + 7] == 'pickup' then
					  pickup = pickup + 1
				       end
				    end

				    -- use the menu items to make the rows
				    setupRows(menu_items, popup)

				    -- provide notifications when an item is updated
				    -- this could get annoying, so maybe I'll change it
				    -- to only notify if it changes country?
				    -- maybe I'll have a notification mode attached to the item
				    -- in python? that sounds pretty viable, and easy to configure
				    if #menu_items == #last_menu_items then
				       for i=1,#menu_items do
					  if (menu_items[i].name == last_menu_items[i]) and
					     (menu_items[i].lastupdate ~= last_menu_items[i].lastupdate) then
					     notify(menu_items[i].name,
						    menu_items[i].status..": "..menu_items[i].lastupdate,
						    menu_items[i])
					  end
				       end
				    end

				    last_menu_items = menu_items
				    tracked_delivered = delivered

				    -- this can probably be done cleaner
				    local extra_text = ""
				    if delivered > 0 then
				       extra_text = ", " ..math.floor(delivered).." delivered"
				    end
				    if pickup > 0 then
				       extra_text = extra_text ..", "
					  ..math.floor(pickup).." to pickup"
				    end
				  -- also setup the header
				    title:set_text(" ["..math.floor(itemCount).." packages"
						   ..extra_text.."] ")

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
