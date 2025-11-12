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
		fi; \
	done; \
	optipng -quiet -o2 examples/themes/*.png
