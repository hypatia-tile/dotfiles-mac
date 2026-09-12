local root_dir = vim.fs.root(0, { { "gradlew", "mvnw" }, ".git" })
if not root_dir then
  return
end

local jdtls_base = vim.fn.glob("/nix/store/*-jdt-language-server-*/share/java/jdtls", false, true)[1]
if not jdtls_base then
  vim.notify("jdtls: Nix jdt-language-server not found", vim.log.levels.ERROR)
  return
end

local launcher = vim.fn.glob(jdtls_base .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, true)[1]
if not launcher then
  vim.notify("jdtls: Equinox launcher jar not found", vim.log.levels.ERROR)
  return
end

local java_home = vim.env.JAVA_HOME
local java = (java_home and vim.fs.joinpath(java_home, "bin", "java")) or "java"
local gradle = vim.fn.exepath "gradle"
local gradle_home = gradle ~= "" and vim.fs.dirname(vim.fs.dirname(gradle)) or nil
local workspace = vim.fs.joinpath(vim.fn.stdpath "cache", "jdtls", vim.fn.sha256(root_dir))
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.diagnostic = nil
capabilities.workspace.diagnostics = nil

local config = {
  name = "jdtls",
  capabilities = capabilities,
  cmd = {
    java,
    "-Declipse.application=org.eclipse.jdt.ls.core.id1",
    "-Dosgi.bundles.defaultStartLevel=4",
    "-Declipse.product=org.eclipse.jdt.ls.core.product",
    "-Dosgi.checkConfiguration=true",
    "-Dosgi.sharedConfiguration.area=" .. vim.fs.joinpath(jdtls_base, "config_mac"),
    "-Dosgi.sharedConfiguration.area.readOnly=true",
    "-Dosgi.configuration.cascaded=true",
    "-Xms1G",
    "-Xmx2G",
    "--add-modules=ALL-SYSTEM",
    "--add-opens",
    "java.base/java.util=ALL-UNNAMED",
    "--add-opens",
    "java.base/java.lang=ALL-UNNAMED",
    "-jar",
    launcher,
    "-data",
    workspace,
  },
  root_dir = root_dir,
  settings = {
    java = {
      home = java_home,
      configuration = {
        runtimes = {
          {
            name = "JavaSE-25",
            path = java_home,
            default = true,
          },
        },
      },
      import = {
        gradle = {
          home = gradle_home and vim.fs.joinpath(gradle_home, "libexec", "gradle") or nil,
          java = {
            home = java_home,
          },
        },
      },
    },
  },
  init_options = {
    bundles = {},
  },
}

vim.lsp.start(config, {
  reuse_client = function(client, candidate)
    return client.name == candidate.name and client.config.root_dir == candidate.root_dir
  end,
})
