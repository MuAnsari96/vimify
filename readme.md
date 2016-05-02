## About
[vimify](https://github.com/MuAnsari96/vimify) is a plugin for [Vim](https://github.com/vim/vim) that provides simple Spotify integration. Since it uses the MPRIS2 dbus interface to control Spotify, it works out of the box with all Linux systems, provided that the Vim installation was compiled with python. Currently, basic spotify controls are implemented, and more is expected to come!

## Features
vimify is designed to interface with a running desktop instance of Spotify. Currently, the following features are supported:

* `:SpPlay` will play the current track
* `:SpPause` will pause the current track
* `:Spotify` will toggle play/pause
* `:SpSearch <query>` will search spotify for 'query' and return the results in a new buffer. <Enter> will select the result to begin playback.

## Installation 
The preferred way to install vimify is to use [pathogen](https://github.com/tpope/vim-pathogen). With pathogen installed, simply run
```bash
cd ~/.vim/bundle
git clone https://github.com/MuAnsari96/vimify
```
and you'll be good to go! Once help tags are generated, you can just run `:help vimify` in vim to see the manual.
