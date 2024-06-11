-- Q-Sys plugin for Kramer Protocol 3000
-- <https://github.com/rod-driscoll/q-sys-plugin-kramer-protocol-3000>
-- 20240110 v1.1.0.4 Rod Driscoll<rod@theavitgroup.com.au>
-- 20240319 v1.1.0.5 Rod Driscoll<rod@theavitgroup.com.au>
  -- inverted AFV command byte
-- 20240415 v1.1.1.0 Rod Driscoll<rod@theavitgroup.com.au>
  -- added Udp control
-- 20240611 v1.1.2.0 Rod Driscoll<rod@theavitgroup.com.au>
  -- toggling an output to no source updates the output source combo box
  -- analog audio route toggle off now works

PluginInfo = {
  Name = "Kramer~Protocol 3000", -- The tilde here indicates folder structure in the Shematic Elements pane
  Version = "1.1.2.0",
  BuildVersion = "1.1.2.0",
  Id = "kramer-protocol-3000.plugin.1.0.0", -- this must be unique per plugin, but don't add version number because the compiler will update it.
  Description = "Plugin implementing Kramer Protocol 3000",
  ShowDebug = true,
  Author = "Rod Driscoll"
}