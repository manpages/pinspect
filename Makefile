src := $(wildcard lib/*ex) \
	$(wildcard lib/**/*.ex) \
	mix.exs
deps := $(wildcard deps/*)

.PHONY: all test iex clean

all: ebin sys.config

ebin: $(src)
	@MIX_ENV=dev mix do deps.get, compile

iex: ebin
	@ERL_LIBS=.:deps iex -e "lc x inlist :filelib.wildcard('ebin/*.beam'), do: :code.ensure_loaded(list_to_atom( Path.basename(Path.basename(x, '.beam')) ))"

clean:
	@mix clean
