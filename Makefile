FS=.
GAME=dr80.tic

run:
	padsp tic80 --fs $(FS) --skip --cmd "load $(GAME) & run"

save:
	padsp tic80 --fs $(FS) --skip --cmd "load $(GAME) & save dr80.lua & exit"

kill:
	killall tic80
