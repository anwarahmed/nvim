return {
  "sphamba/smear-cursor.nvim",

  --[[ -- Default options
  opts = {
    -- Smear cursor when switching buffers or windows.
    smear_between_buffers = true,

    -- Smear cursor when moving within line or to neighbor lines.
    -- Use `min_horizontal_distance_smear` and `min_vertical_distance_smear` for finer control
    smear_between_neighbor_lines = true,

    -- Draw the smear in buffer space instead of screen space when scrolling
    scroll_buffer_space = true,

    -- Set to `true` if your font supports legacy computing symbols (block unicode symbols).
    -- Smears will blend better on all backgrounds.
    legacy_computing_symbols_support = false,

    -- Smear cursor in insert mode.
    -- See also `vertical_bar_cursor_insert_mode` and `distance_stop_animating_vertical_bar`.
    smear_insert_mode = true,
  }, ]]

  --[[ -- Faster smear
  opts = { -- Default  Range
    stiffness = 0.8, -- 0.6      [0, 1]
    trailing_stiffness = 0.6, -- 0.45     [0, 1]
    stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
    trailing_stiffness_insert_mode = 0.7, -- 0.5      [0, 1]
    damping = 0.95, -- 0.85     [0, 1]
    damping_insert_mode = 0.95, -- 0.9      [0, 1]
    distance_stop_animating = 0.5, -- 0.1      > 0
  }, ]]

  --[[ -- Fire hazard
  opts = {
    cursor_color = "#ff8800",
    stiffness = 0.3,
    trailing_stiffness = 0.1,
    damping = 0.5,
    trailing_exponent = 5,
    never_draw_over_target = true,
    hide_target_hack = true,
    gamma = 1,
  }, ]]

  -- Smooth cursor without smear
  opts = {
    stiffness = 0.5,
    trailing_stiffness = 0.5,
    matrix_pixel_threshold = 0.5,
  },
}
