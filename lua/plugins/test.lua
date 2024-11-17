return {
    {
        "nvim-neotest/neotest",
        dependencies = {
            { "Issafalcon/neotest-dotnet" },
        },
        config = function()
            require("neotest").setup({
                adapters = {
                    require("neotest-dotnet")
                }
            })
        end
    }
}
