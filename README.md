# goat-cache
WIP: An S3-backed Nix cache with OIDC in mind. 

## Ideas and inspiration
I really like what `attic` can do for Nix but I find it impractical for dotfile-esque system setups.
What I really want is the ability to use GitHub Actions and OIDC to upload to my cache.
This is built with fly.io in mind wherein every setting for the cache server should be configurable via
environment variables.
