# Zenlab public assets source

Files under this directory are safe to publish to `zenlab-dev/public-assets`.

GitHub Actions copies this directory to the public repository on pushes to
`main`, then generates any derived files such as checksums. Do not place
secrets, private SSH keys, tokens, decrypted YAML, or generated runtime env
files here.
