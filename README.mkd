Global Session Plugin
============================================
gsession.vim saves your session files into the same directory (`~/.vim/session/`)
by default.  and auto-detect your session file to load session file when you
are opening vim editor without arguments. you can also define your session dir
by `g:session_dir` option.

gsession.vim also save your session file when you are leaving vim editor.

gsession.vim also support making a local session file `<leader>sS`, which is
just like `:mksession!` command. but you can define your favorite session
filename.

gsession.vim create different sessions for git branches. so session won't conflict 
between different branches.

Options
=======

    let g:session_dir            = '~/.vim/my-session'

if you prefer to put sessions in other place.

    let g:local_session_filename = '.session.vim'

if you want a better session filename.

    let g:gsession_non_default_mapping = 1

if you dont like the default mapping.

Installation
============

    $ make install -f Makefile.pure

Usage
=======
( NOTE: `<leader>` is the slash key )

    <leader>ss    

create global session file (located in `~/.vim/session` by default)

    <leader>sS    

create local session file (Session.vim by default , same as you type
`:mksession!` )

    <leader>se

eliminate current session file (including local session file or global session
file)

    <leader>sE

eliminate all session file (eliminate global session only).

    <leader>sn

make a named global session (completion supported)

    <leader>sl

load a named global session (completion supported)


    <leader>sN

make a named session in current path space (completion supported)


    <leader>sL

load a named session from current path space (completion supported)


Author
======

    Author: Cornelius
    Mail:   cornelius.howl@gmail.com
    Web:    http://oulixe.us
