FS=.
GAME=dr80.tic
CODE=dr80.lua

run:
	padsp tic80 --fs $(FS) --skip --cmd "load $(CODE) & run"

save:
	padsp tic80 --fs $(FS) --skip --cmd "load $(GAME) & save dr80.lua & exit"

tmux:
	tmux -f .tmux attach

kill:
	killall tic80
