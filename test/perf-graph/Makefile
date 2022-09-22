FILE=/home/lervag/.cache/wiki.vim/links-out%home%lervag%.local%wiki.json
default:
	@if [ -e "$(FILE)" ]; then \
		cp "$(FILE)" /tmp/data.json; \
	else \
		cp data.json "$(FILE)"; \
	fi
	nvim --headless --clean -u test-issue.vim
