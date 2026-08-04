-- every spec file under the "plugins" directory will be loaded automatically by lazy.nvim
--
-- In your plugin files, you can:
-- * add extra plugins
-- * disable/enabled LazyVim plugins
-- * override the configuration of LazyVim plugins

local function parser_is_compatible_with_host(parser_info, host_machine)
  if not parser_info:find("Mach-O", 1, true) then
    return true
  end

  if host_machine:find("arm64", 1, true) then
    return parser_info:find("arm64", 1, true) or parser_info:find("arm64e", 1, true)
  end

  if host_machine:find("x86_64", 1, true) then
    return parser_info:find("x86_64", 1, true)
  end

  return true
end

local function repair_treesitter_parsers()
  local parser_dir = vim.fn.stdpath("data") .. "/site/parser"
  local host_machine = vim.loop.os_uname().machine
  local parsers_to_repair = {}

  for _, parser_name in ipairs({ "vim", "r" }) do
    local parser_path = parser_dir .. "/" .. parser_name .. ".so"
    if vim.fn.filereadable(parser_path) == 1 then
      local info = vim.fn.system({ "file", "-b", parser_path })
      if vim.v.shell_error == 0 and not parser_is_compatible_with_host(info, host_machine) then
        if vim.fn.delete(parser_path) == 0 then
          vim.notify("Removed incompatible tree-sitter parser: " .. parser_path, vim.log.levels.WARN)
          table.insert(parsers_to_repair, parser_name)
        end
      end
    end
  end

  if #parsers_to_repair == 0 then
    return
  end

  vim.schedule(function()
    vim.notify("Reinstalling parser(s) for current architecture: " .. table.concat(parsers_to_repair, ", "), vim.log.levels.INFO)
    for _, parser_name in ipairs(parsers_to_repair) do
      vim.cmd("silent! TSInstall " .. parser_name)
    end
  end)
end

return {
    -- add gruvbox
    { "ellisonleao/gruvbox.nvim" },

    -- Configure LazyVim to load gruvbox
    {
        "LazyVim/LazyVim",
        opts = {
            colorscheme = "gruvbox",
        },
    },

    -- change trouble config
    {
        "folke/trouble.nvim",
        -- opts will be merged with the parent spec
        opts = { use_diagnostic_signs = true },
    },

    -- disable trouble
    { "folke/trouble.nvim", enabled = false },

    -- override nvim-cmp and add cmp-emoji
    {
        "hrsh7th/nvim-cmp",
        opts = function(_, opts)
            opts.sources = opts.sources or {}
            opts.sources = vim.tbl_filter(function(source)
                return source.name ~= "cmp_r"
            end, opts.sources)
            table.insert(opts.sources, 1, { name = "cmp_tabnine", priority = 1000 })
            table.insert(opts.sources, 2, { name = "omni", keyword_length = 3 })
            table.insert(opts.sources, { name = "emoji" })
        end,
    },

    -- disable deprecated cmp-r source (R.nvim LSP completions are handled by cmp-omni / TabNine setup)
    {
        "R-nvim/cmp-r",
        enabled = false,
    },

    -- prioritize TabNine in nvim-cmp completions, then use omni completions (ALE-backed)
    {
        "tzachar/cmp-tabnine",
        build = "./install.sh",
        dependencies = { "hrsh7th/nvim-cmp" },
    },

    -- allow ALE omni completion to be used through cmp-omni source
    {
        "hrsh7th/cmp-omni",
        dependencies = { "hrsh7th/nvim-cmp" },
    },

    -- change some telescope options and a keymap to browse plugin files
    {
        "nvim-telescope/telescope.nvim",
        keys = {
            -- add a keymap to browse plugin files
            -- stylua: ignore
            {
                "<leader>fp",
                function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
                desc = "Find Plugin File",
            },
        },
        -- change some options
        opts = {
            defaults = {
                layout_strategy = "horizontal",
                layout_config = { prompt_position = "top" },
                sorting_strategy = "ascending",
                winblend = 0,
            },
        },
    },

    -- add pyright to lspconfig
    {
        "neovim/nvim-lspconfig",
        opts = {
            servers = {
                -- pyright will be automatically installed with mason and loaded with lspconfig
                pyright = {},
            },
        },
    },

    -- add more treesitter parsers
    {
        "nvim-treesitter/nvim-treesitter",
        init = repair_treesitter_parsers,
        opts = {
            ensure_installed = {
                "bash",
                "html",
                "javascript",
                "json",
                "lua",
                "markdown",
                "markdown_inline",
                "python",
                "query",
                "regex",
                "r",
                "tsx",
                "typescript",
                "vim",
                "yaml",
            },
        },
    },

    -- since `vim.tbl_deep_extend`, can only merge tables and not lists, the code above
    -- would overwrite `ensure_installed` with the new value.
    -- If you'd rather extend the default config, use the code below instead:
    {
        "nvim-treesitter/nvim-treesitter",
        opts = function(_, opts)
            -- add tsx and treesitter
            vim.list_extend(opts.ensure_installed, {
                "tsx",
                "typescript",
            })
        end,
    },

    -- the opts function can also be used to change the default opts:
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function(_, opts)
            table.insert(opts.sections.lualine_x, {
                function()
                    return "😄"
                end,
            })
        end,
    },

    -- or you can return new options to override all the defaults
    {
        "nvim-lualine/lualine.nvim",
        event = "VeryLazy",
        opts = function()
            return {
                --[[add your custom lualine config here]]
            }
        end,
    },

    -- add any tools you want to have installed below
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                "stylua",
                "shellcheck",
                "shfmt",
                "flake8",
            },
        },
    },

    { "vim-airline/vim-airline" },

    { "scrooloose/nerdtree", keys = {
        { "<F9>", "<cmd>NERDTreeToggle<cr>" },
    } },

    {
        "Chiel92/vim-autoformat",
        keys = {
            { "<F2>", "<cmd>Autoformat<cr>" },
        },
    },

    { "bling/vim-bufferline" },

    {
        "dense-analysis/ale",
        config = function()
            vim.g.ale_ruby_rubocop_auto_correct_all = 1

            vim.g.ale_linters = {
                make = { "checkmake" },
                python = { "ruff", "mypy" },
                sh = { "language_server" },
                r = { "lintr" },
                vim = { "vint" },
            }

            vim.g.ale_r_lintr_options =
                "linters = if (exists('with_defaults')) with_defaults(indentation_linter = NULL, line_length_linter = NULL) else linters_with_defaults(indentation_linter = NULL, line_length_linter = NULL)"
            vim.g.ale_python_ruff_options = "--select E,F,W,N --ignore E501"
            vim.g.ale_python_mypy_options = "--ignore-missing-imports --install-types --non-interactive"
            vim.g.ale_disable_lsp = 0
            vim.g.ale_completion_enabled = 1
            vim.g.ale_completion_delay = 250
        end,
    },

    {
        "Yggdroot/indentLine",
        config = function()
            vim.g.indentLine_char_list = { "|", "¦", "┆", "┊" }
        end,
    },

    { "majutsushi/tagbar", keys = {
        { "<F10>", "<cmd>TagbarToggle<cr>" },
    } },

    { "chrisbra/csv.vim", keys = {
        { "<C-d>", "<cmd>NewDelimiter" },
    } },
}
