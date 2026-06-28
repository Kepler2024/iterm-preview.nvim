.PHONY: test fmt check clean

test:
	nvim --headless -u tests/minimal_init.lua \
		-c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }" \
		-c "q!"

fmt:
	stylua .

check:
	stylua --check .
	luacheck lua plugin --no-unused-args --globals vim

clean:
	rm -f /tmp/iterm-preview.html
