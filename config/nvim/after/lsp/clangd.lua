-- A Nix devShell puts the unwrapped clangd from `clang` ahead of the wrapped
-- one from `clang-tools`, and the unwrapped one cannot find the libc headers
-- (`'stdio.h' file not found`). --query-driver lets clangd ask the Nix clang
-- wrapper named in compile_commands.json for its system include paths.
return {
  cmd = { "clangd", "--query-driver=/nix/store/*/bin/clang*" },
}
