{s}: rec
{
  ghcidScript = s "dev" "ghcid --command 'cabal new-repl lib:hannukahofdata' --allow-eval --warnings";
  allScripts = [ghcidScript];
}
