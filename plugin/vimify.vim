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

def populate(track, albumName=None, albumIDNumber=None):
    name = track["name"].encode('ascii', 'ignore').replace("'", "")
    uri = track["uri"][14:]

    artist = track["artists"][0]["name"].encode('ascii', 'ignore').replace("'", "")
    artistID = track["artists"][0]["id"]

    album, albumID = albumName, albumIDNumber
    if album is None or albumID is None:
        album = track["album"]["name"].encode('ascii', 'ignore').replace("'", "")
        albumID = track["album"]["id"]

    info = {"track": name, "artist": artist, "album": album}
    ListedElements.append(info)

    info = {"uri": uri, "artistID": artistID, "albumID": albumID}
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
    IDs = []
    ListedElements = []
    for track in j[:min(20, len(j))]:
        populate(track)

    vim.command('call s:VimifySearchBuffer(a:query, "Search")')
else:
    vim.command("echo 'No tracks found'")
endpython
endfunction 

function s:PopulateAlbum(albumName, albumIDNumber)
python << endpython
import vim
resp = urllib.urlopen(
            "http://api.spotify.com/v1/albums/{}/tracks".format(
                    vim.eval("a:albumIDNumber"))
            )
j = json.loads(resp.read())["items"]
for track in j:
    populate(track, vim.eval("a:albumName"), vim.eval("a:albumIDNumber"))
endpython
endfunction

function s:SearchAlbum(albumName, albumIDNumber)
python << endpython
import vim
oldIDs = IDs
oldListedElements = ListedElements
IDs = []
ListedElements = []
vim.command('call s:PopulateAlbum(a:albumName, a:albumIDNumber)')

if len(IDs) is 0:
    IDs = oldIDs
    ListedElements = oldListedElements
    vim.command('echo "Invalid Album"')

else:
    vim.command('call s:VimifySearchBuffer(a:albumName, "Album")')
endpython
endfunction

function! s:SearchArtist(artistName, artistIDNumber)
python << endpython
import vim
oldIDs = IDs
oldListedElements = ListedElements
IDs = []
ListedElements = []
resp = urllib.urlopen(
            "http://api.spotify.com/v1/artists/{}/albums".format(
                    vim.eval("a:artistIDNumber"))
            )
j = json.loads(resp.read())["items"]
vim.command('echo "YOOOO"')
albums = set()
for album in j:
    albumName = album["name"]
    if albumName.lower() not in albums:
        albums.add(albumName.lower())
        vim.command('call s:PopulateAlbum("{}", "{}")'.format(albumName, album["id"]))

if len(IDs) is 0:
    IDs = oldIDs
    ListedElements = oldListedElements
    vim.command('echo "Problem fetching artist data"')

else:
    vim.command('call s:VimifySearchBuffer(a:artistName, "Artist")')
endpython
endfunction


" *************************************************************************** "
" ***************************      Interface       ************************** " 
" *************************************************************************** "

function! s:VimifySearchBuffer(query, type)
    if buflisted('Vimify')
        bd Vimify
    endif
    below new Vimify
    call append(0, a:type . ' Results For: ' . a:query)
    call append(line('$'), "Song                                           
                           \Artist                
                           \Album")
    call append(line('$'), "--------------------------------------------------
                           \------------------------------------------------")

python << endpython
import vim
for element in ListedElements:
    row = "{:<45}  {:<20}  {:<}".format(element["track"][:45], element["artist"][:20], element["album"])
    vim.command('call append(line("$"), \'{}\')'.format(row))
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
   let l:col = getpos('.')[2]
python << endpython
import vim
row = int(vim.eval("l:row"))
col = int(vim.eval("l:col"))
if row >= 0:
    if col < 48:
        uri = str(IDs[row]["uri"])
        vim.command('call s:LoadTrack("{}")'.format(uri))
    elif col < 70:
        artistID = str(IDs[row]["artistID"])
        artist = str(ListedElements[row]["artist"])
        vim.command('call s:SearchArtist("{}", "{}")'.format(artist, artistID))
    else:
        albumID = str(IDs[row]["albumID"])
        album = str(ListedElements[row]["album"])
        vim.command('call s:SearchAlbum("{}", "{}")'.format(album, albumID))
endpython
endfunction
" *************************************************************************** "
" ***************************   Command Bindngs   *************************** " 
" *************************************************************************** "
command!            Spotify     call s:Toggle()
command!            SpToggle    call s:Toggle()
command!            SpPause     call s:Pause()
command!            SpPlay      call s:Play()
command!            SpSelect    call s:SelectSong()
command! -nargs=1   SpSearch    call s:SearchTrack(<f-args>)


