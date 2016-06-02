" vimify.vim:  Spotify integration for vim!
" Maintainer:  Mustafa Ansari <http://github.com/MuAnsari96>


" *************************************************************************** "
" ***************************    Initialization    ************************** " 
" *************************************************************************** "

if exists('g:vimifyInited')
    finish
endif
let g:vimifyInited = 0

python << endpython
import subprocess
import os
import urllib
import json

IDs = []
ListedElements = []

def populate(track, albumName=None):
    name = track["name"].encode('ascii', 'ignore').replace("'", "")
    uri = track["uri"][14:]

    artist = track["artists"][0]["name"].encode('ascii', 'ignore').replace("'", "")
    artistID = track["artists"][0]["id"]

    album, albumID = albumName, None
    if album is None:
        album = track["album"]["name"].encode('ascii', 'ignore').replace("'", "")
        albumID = track["album"]["id"]

    info = {"track": name, "artist": artist, "album": album}
    ListedElements.append(info)

    info = {"uri": uri, "artistID": artistID, "albumID": album}
    IDs.append(info)
    
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
    IDs = []
    ListedElements = []
    for track in j[:min(20, len(j))]:
        populate(track)

    vim.command("call s:VimifySearchBuffer()")
else:
    vim.command("echo \'No tracks found\'")
endpython
endfunction 


function! s:SearchArtist(query)
python << endpython



endpython
endfunction

function s:SearchAlbum(query)
python << endpython



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
    call append(line('$'), "Song                                           
                           \Artist                
                           \Album")
    call append(line('$'), "--------------------------------------------------
                           \------------------------------------------------")

python << endpython
import vim
for element in ListedElements:
    row = "{:<45}  {:<20}  {:<}".format(element["track"][:45], element["artist"][:20], element["album"])
    vim.command('call append(line("$"), "{}")'.format(row))
endpython
    resize 14
    normal! gg
    5
    setlocal nonumber
    setlocal nowrap
    setlocal buftype=nofile
    map <buffer> <Enter> <esc>:SpSelect<CR>

endfunction

function! s:SelectSong()
   let l:row = getpos('.')[1]-5
python << endpython
import vim
row = int(vim.eval("l:row"))
if row >= 0:
    uri = str(IDs[row]["uri"])
    vim.command('call s:LoadTrack("{}")'.format(uri))
endpython
endfunction
" *************************************************************************** "
" ***************************   Command Bindngs   *************************** " 
" *************************************************************************** "
command!            Spotify     call s:Toggle()
command!            SpPause     call s:Pause()
command!            SpPlay      call s:Play()
command!            SpSelect    call s:SelectSong()
command! -nargs=1   SpSearch    call s:SearchTrack(<f-args>)


