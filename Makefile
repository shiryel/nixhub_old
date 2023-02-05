run:
	docker build . -t nixhub:latest
	docker run -it \
		-e SECRET_KEY_BASE=Lw5zSbIJmCnGpbHXToGZokE49q38Q/eeA12b3XTCr1PdisXA7b7YpS2WAuUXY4D0 \
		-e MEILISEARCH_URL=http://localhost:7700 \
		-e ADMIN_USERNAME=admin \
		-e ADMIN_PASSWORD=admin \
		-e PHX_HOST=localhost \
		--network host \
		nixhub:latest

ci:
	mix compile --warnings-as-errors
	mix credo --strict
	mix format
	mix test
	mix dialyzer

nixpkgs_options:
	mkdir -p tmp/
	git clone git@github.com:NixOS/nixpkgs.git --branch nixos-unstable --single-branch --depth 1 tmp/nixpkgs
	nix-build tmp/nixpkgs/nixos/release.nix -A options -o tmp/result
	cp tmp/result/share/doc/nixos/options.json tmp/nixos_options.json
	rm tmp/result
	rm -rf tmp/nixpkgs

nix_builtins:
	nix __dump-builtins

meilisearch_tasks:
	curl -X GET 'http://localhost:7700/tasks'
