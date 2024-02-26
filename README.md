# telescope-smart-goto.nvim

**Update:** I'm currently not working on this project. I've found [prochri/telescope-all-recent.nvim](https://github.com/prochri/telescope-all-recent.nvim) and [smart-open.nvim](https://github.com/danielfalk/smart-open.nvim) make for a great combination for getting to files efficiently.

A smart goto Telescope extension

**ALPHA WARNING:** This is alpha software right now. There are no tests and it is not ready for daily use. Please feel free to try it out and report any issues you find. I also recommend watching releases for updates.

## What it does

This is a "smart" telescope extension which is meant to be a replacement for harpoon, buffer, git stuatus, and find files by merging all of these different lists into one. So you can bind it to one shortcut and it will show you the most relevant files for the project you are working on.

Here's what it currently displayed and what I plan to intgrate next:

- [x] Show Harpoon marks
- [x] Show open file buffers
- [ ] Git diffs
- [ ] All other files from project (by most recent?)

## How to install

Using [lazy.nvim 💤](https://github.com/folke/lazy.nvim) add this repository as a dependency and load the extension using Telescopes `load_extension` function. In order for [harpoon](https://github.com/ThePrimeagen/harpoon) to work it needs to be inlcuded as a dependency as well.

```lua
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "ThePrimeagen/harpoon",
    "joshmedeski/telescope-smart-goto.nvim",
  },
  config = function(_, opts)
    local telescope = require("telescope")
    telescope.setup(opts)
    telescope.load_extension("smart_goto")
  end,
}
```
