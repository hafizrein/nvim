return {
  {
    "rauls-kjarners/omp.nvim",
    event = "VeryLazy",
    config = function()
      require("omp").setup()
    end,
  },
}
