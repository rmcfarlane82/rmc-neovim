return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts = opts or {}
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" },
        file_ignore_patterns = {
          "obj[\\/]",
          "bin[\\/]",
          "packages[\\/]",
          "node_modules[\\/]",
          "[\\/][Dd]ebug[\\/]",
          "[\\/][Rr]elease[\\/]",
        },
        path_display = { filename_first = { reverse_directories = true } },
      })

      local themes = require "telescope.themes"
      opts.extensions = vim.tbl_deep_extend("force", opts.extensions or {}, {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
        ["ui-select"] = themes.get_dropdown {},
      })

      return opts
    end,
    config = function(_, opts)
      local telescope = require "telescope"
      telescope.setup(opts)
      telescope.load_extension "fzf"
      telescope.load_extension "ui-select"
    end,
  },

  -- Build fzf-native with CMake (Windows-friendly)
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = function()
      local is_win = vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1
      if is_win then
        return [[cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DCMAKE_POLICY_VERSION_MINIMUM=3.5
               && cmake --build build --config Release
               && cmake --install build --prefix build]]
      else
        return "make"
      end
    end,
    cond = function()
      local is_win = vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1
      if is_win then
        return vim.fn.executable "cmake" == 1
      else
        return vim.fn.executable "make" == 1
      end
    end,
  },
  { "nvim-telescope/telescope-ui-select.nvim" },
}
