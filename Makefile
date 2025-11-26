.PHONY: all examples theme-examples

all: examples theme-examples

examples:
	@for file in $$(ls examples/*.tape); do \
		name=$$(basename $${file%.*}); \
		output_path="examples/$${name}.mp4"; \
		gif_output_path="examples/$${name}.gif"; \
		if [ ! -f "$${output_path}" ] && [ ! -f "$${gif_output_path}" ]; then \
			exe/demotape run $$file --screenshot; \
		fi; \
	done; \
	optipng -quiet -o2 examples/*.png

theme-examples:
	@rm -rf .sw*

	@for file in $$(ls lib/demo_tape/themes/*.json); do \
		name=$$(basename $${file%.*}); \
		output_base_path="examples/themes/$${name}"; \
		if [ ! -f "$${output_base_path}.png" ]; then \
			export THEME=$${name}; \
			exe/demotape run \
				examples/themes/theme.tape \
				--theme $${name} \
				--output-path $${output_base_path}.mp4 \
				--screenshot_only; \
			optipng -quiet -o2 examples/themes/$${name}.png; \
		fi; \
	done;

zed:
	@cd editors/zed/tree-sitter && \
			npm install && \
			node_modules/.bin/tree-sitter generate && \
			node_modules/.bin/tree-sitter build-wasm && \
			mv tree-sitter-demotape.wasm ../grammars/demotape.wasm
