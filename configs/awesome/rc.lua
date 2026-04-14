-- MinimalOS – AwesomeWM Configuration
-- By: gibranlp <thisdoesnotwork@gibranlp.dev>
-- Minimal X11 tiling WM, no bar, rofi-driven panels.
-- ─────────────────────────────────────────────────────────────────────────────

local awful     = require("awful")
local gears     = require("gears")
local beautiful = require("beautiful")
local naughty   = require("naughty")
require("awful.autofocus")

-- ── Error Handling ────────────────────────────────────────────────────────
if awesome.startup_errors then
    naughty.notify({
        preset = naughty.config.presets.critical,
        title  = "Startup Error",
        text   = awesome.startup_errors
    })
end

do
    local in_error = false
    awesome.connect_signal("debug::error", function(err)
        if in_error then return end
        in_error = true
        naughty.notify({ preset = naughty.config.presets.critical,
                         title  = "Runtime Error",
                         text   = tostring(err) })
        in_error = false
    end)
end

-- ── Load cwal Colors ──────────────────────────────────────────────────────
-- Reads ~/.cache/cwal/colors.sh and returns a color table.
local function load_cwal_colors()
    local c = {}
    local f = io.open(os.getenv("HOME") .. "/.cache/cwal/colors.sh", "r")
    if f then
        for line in f:lines() do
            local name, val = line:match("export%s+([%w_]+)='(#[%x]+)'")
            if name and val then c[name] = val end
        end
        f:close()
    end
    -- Fallbacks if cwal hasn't run yet
    return {
        bg      = c["color0"]  or "#1a1a2e",
        bg_alt  = c["color8"]  or "#24283b",
        fg      = c["color7"]  or "#c0caf5",
        fg_dim  = c["color15"] or "#a9b1d6",
        accent  = c["color4"]  or "#7aa2f7",
        accent2 = c["color6"]  or "#73daca",
        urgent  = c["color1"]  or "#f7768e",
        warn    = c["color3"]  or "#e0af68",
    }
end

local col = load_cwal_colors()

-- ── Theme ─────────────────────────────────────────────────────────────────
beautiful.init(gears.filesystem.get_themes_dir() .. "default/theme.lua")
beautiful.font           = "Courier Prime Medium 11"
beautiful.bg_normal      = col.bg
beautiful.fg_normal      = col.fg
beautiful.bg_focus       = col.accent
beautiful.fg_focus       = col.bg
beautiful.bg_urgent      = col.urgent
beautiful.fg_urgent      = col.bg
beautiful.bg_minimize    = col.bg_alt
beautiful.fg_minimize    = col.fg_dim
beautiful.border_width   = 2
beautiful.border_normal  = col.bg_alt
beautiful.border_focus   = col.accent
beautiful.border_marked  = col.urgent
beautiful.useless_gap    = 6
beautiful.notification_font        = "Courier Prime Medium 11"
beautiful.notification_bg          = col.bg
beautiful.notification_fg          = col.fg
beautiful.notification_border_color = col.accent

-- ── Variables ─────────────────────────────────────────────────────────────
local modkey   = "Mod4"
local terminal = "alacritty"
local BIN      = os.getenv("HOME") .. "/.local/bin"

-- ── Layouts ───────────────────────────────────────────────────────────────
awful.layout.layouts = {
    awful.layout.suit.tile,
    awful.layout.suit.tile.left,
    awful.layout.suit.tile.bottom,
    awful.layout.suit.tile.top,
    awful.layout.suit.fair,
    awful.layout.suit.floating,
    awful.layout.suit.max,
}

-- ── Tags ──────────────────────────────────────────────────────────────────
awful.screen.connect_for_each_screen(function(s)
    awful.tag({ "1", "2", "3", "4", "5", "6", "7", "8", "9" },
              s, awful.layout.layouts[1])
end)

-- ── Global Key Bindings ───────────────────────────────────────────────────
local globalkeys = gears.table.join(

    -- WM
    awful.key({ modkey, "Control" }, "r", awesome.restart,
              { description = "reload awesome" }),
    awful.key({ modkey, "Shift"   }, "q", awesome.quit,
              { description = "quit awesome" }),

    -- Window focus
    awful.key({ modkey }, "j",
        function() awful.client.focus.byidx(1) end,
        { description = "focus next" }),
    awful.key({ modkey }, "k",
        function() awful.client.focus.byidx(-1) end,
        { description = "focus prev" }),
    awful.key({ modkey }, "Tab", function()
        awful.client.focus.history.previous()
        if client.focus then client.focus:raise() end
    end, { description = "focus history" }),

    -- Window swap
    awful.key({ modkey, "Shift" }, "j",
        function() awful.client.swap.byidx(1)  end),
    awful.key({ modkey, "Shift" }, "k",
        function() awful.client.swap.byidx(-1) end),

    -- Multi-screen
    awful.key({ modkey }, "o",
        function() awful.screen.focus_relative(1) end,
        { description = "focus next screen" }),

    -- Layout
    awful.key({ modkey }, "space",
        function() awful.layout.inc(1)  end,
        { description = "next layout" }),
    awful.key({ modkey, "Shift" }, "space",
        function() awful.layout.inc(-1) end,
        { description = "prev layout" }),
    awful.key({ modkey }, "l",
        function() awful.tag.incmwfact(0.05) end),
    awful.key({ modkey }, "h",
        function() awful.tag.incmwfact(-0.05) end),
    awful.key({ modkey, "Shift" }, "l",
        function() awful.tag.incnmaster(1, nil, true) end),
    awful.key({ modkey, "Shift" }, "h",
        function() awful.tag.incnmaster(-1, nil, true) end),

    -- Terminal
    awful.key({ modkey }, "Return",
        function() awful.spawn(terminal) end,
        { description = "terminal" }),

    -- Broot file manager
    awful.key({ modkey, "Shift" }, "Return",
        function() awful.spawn(terminal .. " -e broot") end,
        { description = "file manager" }),

    -- ── Rofi / SOS Scripts ────────────────────────────────────────────────
    awful.key({ modkey }, "d", function()
        awful.spawn("rofi -show drun -show-icons -theme ~/.config/rofi/SOS_Left.rasi")
    end, { description = "app launcher" }),

    awful.key({ modkey }, "p", function()
        awful.spawn(BIN .. "/SOS_Panel.sh")
    end, { description = "control panel" }),

    awful.key({ modkey }, "x", function()
        awful.spawn(BIN .. "/SOS_Session.sh")
    end, { description = "session menu" }),

    awful.key({ modkey }, "r", function()
        awful.spawn(BIN .. "/SOS_Randomize_Wallpaper.sh")
    end, { description = "random wallpaper" }),

    awful.key({ modkey }, "w", function()
        awful.spawn(BIN .. "/SOS_Select_Wallpaper.sh")
    end, { description = "select wallpaper" }),

    awful.key({ modkey }, "s", function()
        awful.spawn(BIN .. "/SOS_Search.sh")
    end, { description = "search files" }),

    awful.key({ modkey }, "c", function()
        awful.spawn(BIN .. "/SOS_Calculator.sh")
    end, { description = "calculator" }),

    awful.key({ modkey }, "b", function()
        awful.spawn(BIN .. "/SOS_Wifi.sh")
    end, { description = "wifi" }),

    awful.key({ modkey, "Shift" }, "b", function()
        awful.spawn(BIN .. "/SOS_Bluetooth.sh")
    end, { description = "bluetooth" }),

    awful.key({ modkey }, "g", function()
        awful.spawn(BIN .. "/SOS_Pass_Generator.sh")
    end, { description = "password generator" }),

    awful.key({ modkey }, "e", function()
        awful.spawn(BIN .. "/SOS_Power.sh")
    end, { description = "power profile" }),

    -- Screenshot
    awful.key({}, "Print", function()
        awful.spawn(BIN .. "/SOS_Screenshot.sh")
    end, { description = "screenshot" }),

    -- Volume
    awful.key({}, "XF86AudioRaiseVolume", function()
        awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ +5%")
        awful.spawn.with_shell("VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '[0-9]+(?=%)' | head -1); notify-send -a '' 'Volume' \"$VOL%\" -t 1000")
    end),
    awful.key({}, "XF86AudioLowerVolume", function()
        awful.spawn("pactl set-sink-volume @DEFAULT_SINK@ -5%")
        awful.spawn.with_shell("VOL=$(pactl get-sink-volume @DEFAULT_SINK@ | grep -oP '[0-9]+(?=%)' | head -1); notify-send -a '' 'Volume' \"$VOL%\" -t 1000")
    end),
    awful.key({}, "XF86AudioMute", function()
        awful.spawn("pactl set-sink-mute @DEFAULT_SINK@ toggle")
        awful.spawn("notify-send -a '' 'Volume' 'Muted' -t 1000")
    end),

    -- Brightness
    awful.key({}, "XF86MonBrightnessUp", function()
        awful.spawn("brightnessctl set +10%")
        awful.spawn.with_shell("B=$(brightnessctl get); M=$(brightnessctl max); notify-send -a '' 'Brightness' \"$((B*100/M))%\" -t 1000")
    end),
    awful.key({}, "XF86MonBrightnessDown", function()
        awful.spawn("brightnessctl set 10%-")
        awful.spawn.with_shell("B=$(brightnessctl get); M=$(brightnessctl max); notify-send -a '' 'Brightness' \"$((B*100/M))%\" -t 1000")
    end)
)

-- Tag switching: Mod+1..9 / Mod+Shift+1..9 / Mod+Ctrl+1..9
for i = 1, 9 do
    globalkeys = gears.table.join(globalkeys,
        awful.key({ modkey }, "#" .. i + 9, function()
            local s   = awful.screen.focused()
            local tag = s.tags[i]
            if tag then tag:view_only() end
        end),
        awful.key({ modkey, "Control" }, "#" .. i + 9, function()
            local s   = awful.screen.focused()
            local tag = s.tags[i]
            if tag then awful.tag.viewtoggle(tag) end
        end),
        awful.key({ modkey, "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:move_to_tag(tag) end
            end
        end),
        awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9, function()
            if client.focus then
                local tag = client.focus.screen.tags[i]
                if tag then client.focus:toggle_tag(tag) end
            end
        end)
    )
end

root.keys(globalkeys)

-- ── Client Key Bindings ───────────────────────────────────────────────────
local clientkeys = gears.table.join(
    awful.key({ modkey }, "q",
        function(c) c:kill() end,
        { description = "close window" }),
    awful.key({ modkey }, "f", function(c)
        c.fullscreen = not c.fullscreen
        c:raise()
    end, { description = "fullscreen" }),
    awful.key({ modkey, "Shift" }, "f",
        awful.client.floating.toggle,
        { description = "toggle floating" }),
    awful.key({ modkey }, "m", function(c)
        c.maximized = not c.maximized
        c:raise()
    end, { description = "maximize" }),
    awful.key({ modkey }, "t", function(c)
        c.ontop = not c.ontop
    end, { description = "toggle on top" }),
    awful.key({ modkey }, "n", function(c)
        c.minimized = true
    end, { description = "minimize" }),
    awful.key({ modkey, "Control" }, "Return", function(c)
        c:swap(awful.client.getmaster())
    end, { description = "move to master" })
)

-- ── Client Mouse Bindings ─────────────────────────────────────────────────
local clientbuttons = gears.table.join(
    awful.button({}, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
    end),
    awful.button({ modkey }, 1, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.move(c)
    end),
    awful.button({ modkey }, 3, function(c)
        c:emit_signal("request::activate", "mouse_click", { raise = true })
        awful.mouse.client.resize(c)
    end)
)

-- ── Rules ─────────────────────────────────────────────────────────────────
awful.rules.rules = {
    -- Default: apply to all windows
    {
        rule       = {},
        properties = {
            border_width = beautiful.border_width,
            border_color = beautiful.border_normal,
            focus        = awful.client.focus.filter,
            raise        = true,
            keys         = clientkeys,
            buttons      = clientbuttons,
            screen       = awful.screen.preferred,
            placement    = awful.placement.no_overlap + awful.placement.no_offscreen,
        }
    },
    -- Float specific apps
    {
        rule_any = {
            class = {
                "Pavucontrol",
                "Blueman-manager",
                "Nm-connection-editor",
                "Arandr",
                "Gpick",
            },
            name = {
                "Friends List",
                "Steam - News",
                "Event Tester",
            },
            role = { "pop-up" },
        },
        properties = { floating = true, placement = awful.placement.centered }
    },
    -- Gaming tag (tag 5)
    {
        rule_any = { class = { "Steam", "Lutris", "heroic" } },
        properties = { tag = "5", floating = true }
    },
    -- Browsers on tag 2
    {
        rule_any = { class = { "Brave-browser", "Google-chrome", "firefox" } },
        properties = { tag = "2" }
    },
}

-- ── Signals ───────────────────────────────────────────────────────────────
client.connect_signal("manage", function(c)
    if awesome.startup
        and not c.size_hints.user_position
        and not c.size_hints.program_position then
        awful.placement.no_offscreen(c)
    end
end)

client.connect_signal("focus",   function(c) c.border_color = beautiful.border_focus  end)
client.connect_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)

-- Resize floating window with keyboard
client.connect_signal("request::geometry", awful.ewmh.geometry)

-- ── Autostart ─────────────────────────────────────────────────────────────
local function run_once(cmd)
    local find = cmd:match("([^%s]+)")
    awful.spawn.with_shell(string.format(
        "pgrep -u $USER -x '%s' > /dev/null || (%s)", find, cmd))
end

run_once("picom --config ~/.config/picom/picom.conf -b")
run_once("dunst")
run_once("nm-applet --indicator")
run_once("xsettingsd")

-- Restore wallpaper
awful.spawn.with_shell(
    "WALL=$(cat /var/lib/minimalos/current_wallpaper 2>/dev/null); " ..
    "[ -f \"$WALL\" ] && feh --bg-scale \"$WALL\" || " ..
    "feh --bg-scale $(find ~/Pictures/Wallpapers -type f \\( -iname '*.png' -o -iname '*.jpg' \\) | shuf -n1 2>/dev/null)"
)
