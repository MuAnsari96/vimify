" vimify.vim:  Spotify integration for vim!
" Maintainer:  Mustafa Ansari <http://github.com/MuAnsari96>


" *************************************************************************** "
" ***************************    Initialization    ************************** " 
" *************************************************************************** "

if exists('g:vimifyInited')
    finish
endif
let g:vimifyInited = 0
let g:trackIDs = ['','','','','','','','','','']
let g:tracks =  ['','','','','','','','','','']

python << endpython
import subprocess
import os
import urllib
import json
endpython

" *************************************************************************** "
" ***********************     Spotfy dbus wrappers     ********************** " 
" *************************************************************************** "

function! s:Play()
python << endpython
subprocess.call(['dbus-send',
                 '--print-reply', 
                 '--dest=org.mpris.MediaPlayer2.spotify', 
                 '/org/mpris/MediaPlayer2', 
                 'org.mpris.MediaPlayer2.Player.Play'], 
                 stdout=open(os.devnull, 'wb'))
endpython
endfunction

function! s:Pause()
python << endpython
subprocess.call(['dbus-send',
                 '--print-reply', 
                 '--dest=org.mpris.MediaPlayer2.spotify', 
                 '/org/mpris/MediaPlayer2', 
                 'org.mpris.MediaPlayer2.Player.Pause'], 
                 stdout=open(os.devnull, 'wb'))
endpython
endfunction

function! s:Toggle()
python << endpython
subprocess.call(['dbus-send',
                 '--print-reply', 
                 '--dest=org.mpris.MediaPlayer2.spotify', 
                 '/org/mpris/MediaPlayer2', 
                 'org.mpris.MediaPlayer2.Player.PlayPause'], 
                 stdout=open(os.devnull, 'wb'))
endpython
endfunction

function! s:LoadTrack(track)
call s:Pause()
python << endpython
import vim
subprocess.call(['dbus-send',
                 '--print-reply', 
                 '--dest=org.mpris.MediaPlayer2.spotify', 
                 '/org/mpris/MediaPlayer2', 
                 'org.mpris.MediaPlayer2.Player.OpenUri',
                 'string:spotify:track:'+vim.eval("a:track")], 
                 stdout=open(os.devnull, 'wb'))
endpython
endfunction

" *************************************************************************** "
" ***********************      SpotfyAPI wrappers      ********************** " 
" *************************************************************************** "

function! s:SearchTrack(query)
python << endpython
import vim
resp = urllib.urlopen(
            "http://api.spotify.com/v1/search?q={}&type=track".format(
                    vim.eval("a:query"))
             )
j = json.loads(resp.read())["tracks"]["items"]
if len(j) is not 0:
    tracks = ""
    for i in range(min(10, len(j))):
        curr = j[i]
        name = curr["name"]
        artist = curr["artists"][0]["name"]
        album = curr["album"]["name"]
        uri = curr["uri"][14:]
        vim.command("let g:trackIDs[{}] = \'{}\'".format(i, uri))
        t = "{:<45}  {:<20}  {:<}".format(name[:45], artist[:20], album)
        vim.command("let g:tracks[{}] = \'{}\'".format(i, t))

    vim.command("call s:VimifySearchBuffer()")
else:
    vim.command("echo \'No tracks found\'")
endpython
endfunction 

" *************************************************************************** "
" ***************************      Interface       ************************** " 
" *************************************************************************** "

function! s:VimifySearchBuffer()
    if buflisted('Vimify')
        bd Vimify
    endif
    below new Vimify
    call append(0, 'Spotify Search Results:')
    for track in g:tracks
        call append(line('$'), track)
    endfor
    resize 14
    setlocal nonumber
    setlocal nowrap
    setlocal buftype=nofile
    map <buffer> <Enter> <esc>:SpSelect<CR>
endfunction

function! s:SelectSong()
   let l:row = getpos('.')[1]-3
   let l:track = g:trackIDs[l:row]
   echo l:row
   call s:LoadTrack(l:track)
   setpos(1,1)
endfunction
" *************************************************************************** "
" ***************************   Command Bindngs   *************************** " 
" *************************************************************************** "
command!            Spotify     call s:Toggle()
command!            SpPause     call s:Pause()
command!            SpPlay      call s:Play()
command!            SpSelect    call s:SelectSong()
command! -nargs=1   SpSearch    call s:SearchTrack(<f-args>)


