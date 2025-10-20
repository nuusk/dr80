FS=.
GAME=dr80.tic

run:
	tic80 --fs $(FS) --skip --cmd "load $(GAME) & import src/main.lua code & run"

save:
	tic80 --fs $(FS) --skip --cmd "load $(GAME) & export src/main.lua code & exit"
