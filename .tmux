new-session -d -s dr80 -c ~/code/dr80 "nvim"

new-window -t dr80:1 -c ~/code/dr80
rename-window -t dr80:1 terminal

new-window -t dr80:2 -c ~/code/dr80 "make run"
rename-window -t dr80:2 run

