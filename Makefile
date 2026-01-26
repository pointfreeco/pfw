format:
	swift format . --recursive --in-place
	find README.md Sources -name '*.md' -exec sed -i '' -e 's/ *$$//g' {} \;

.PHONY: format
