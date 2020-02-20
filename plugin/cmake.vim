func! g:CompileLinkFlag(escape_blank)
    let s:compile_Flags=''
    let s:link_Flags=''
    if search('.*include\&.*gtk\.h')
    "   let s:compile_Flags .='--export-dynamic `pkg-config --cflags gtk+-3.0`'
        let s:compile_Flags .=' `pkg-config --cflags gtk+-3.0`'
        let s:link_Flags    .=' `pkg-config --libs gtk+-3.0 gmodule-export-2.0`'
        "let s:link_Flags    .=' `pkg-config --libs gtk+-3.0`'
    endif
    if search('.*include\&.*math\.h')||search('.*include\&.*cmath')
        let  s:link_Flags .= ' -lm'
    endif
    if search('.*include\&.*time\.h')||search('.*include\&.*ctime')
        let  s:link_Flags.= ' -lrt'
    endif
    if search("glut\.h")
      let s:link_Flags .= " -lglut -lGLU -lGL"
    endif
    if search("cv\.h")
      let s:link_Flags .= " -lcv -lhighgui -lcvaux"
    endif
    if search("pthread\.h")
      let s:link_Flags .= " -lpthread"
    endif
    if search("X11\/XKBlib\.h") || search("X11\/X\.h")
      let s:link_Flags .= " -lX11"
    endif
    if search("curses\.h")
        let s:link_Flags .= " -lcurses"
      endif
    if  search("omp\.h")
      let s:link_Flags .= " -fopenmp"
    endif
    if a:escape_blank ==# '\ '"每次必须单引号,单引号中的特殊符号不会转义
        return [escape(s:compile_Flags,'\ '),escape(s:link_Flags,'\ ')]
    endif
    return [s:compile_Flags,s:link_Flags]
endfunc


let s:LastShellReturn_C = 0
let s:LastShellReturn_L = 0
let s:ShowWarning = 1
let s:Obj_Extension = '.o'
let s:Exe_Extension = '.exe'
let s:Sou_Error = 0
func! g:Compile(...)
    call Test_filename()
"let s:windows_CFlags = 'gcc\ -fexec-charset=gbk\ -std=c11\ -Wall\ -g\ -O0\ -c\ %\ -o\ %<.o'
let s:windows_CFlags = 'gcc\ -fexec-charset=gbk'
let s:linux_CFlags = 'gcc\ -g'
let s:windows_CPPFlags = 'g++\ -fexec-charset=gbk'
let s:linux_CPPFlags = 'g++\ -g'
let s:makeflag=''
  for var in a:000
        if strpart(var,0,1) ==# "-"
            s:makeflag .='\ '.var
        endif
  endfor

    exe ":ccl"
    exe ":update"
    if expand("%:e") ==? "c" || expand("%:e") ==? "cpp" || expand("%:e") ==? "cxx"
        let s:Sou_Error = 0
        let s:LastShellReturn_C = 0
        let Sou = expand("%:p")
        let Obj = expand("%:p:r").s:Obj_Extension
        let Obj_Name = expand("%:p:t:r").s:Obj_Extension
        let v:statusmsg = ''
        if !filereadable(Obj) || (filereadable(Obj) && (getftime(Obj) < getftime(Sou)))
            " redraw!
            if expand("%:e") ==? "c"
                if WINDOWS()
                    exe ":setlocal makeprg=".s:windows_CFlags.s:makeflag.'\ -c\ %\ -o\ %<.o'.CompileLinkFlag('\ ')[1]
                else
                    exe ":setlocal makeprg=".s:linux_CFlags.s:makeflag.'\ -c\ %\ -o\ %<.o'.CompileLinkFlag('\ ')[1]
                endif
                echohl WarningMsg | echo " compiling..."
            elseif expand("%:e") ==? "cpp" || expand("%:e") ==? "cxx"
                if WINDOWS()
                    exe ":setlocal makeprg=".s:windows_CPPFlags.s:makeflag.'\ -c\ %\ -o\ %<.o'.CompileLinkFlag('\ ')[1]
                else
                    exe ":setlocal makeprg=".s:linux_CPPFlags.s:makeflag.'\ -c\ %\ -o\ %<.o'.CompileLinkFlag('\ ')[1]
                endif
                echohl WarningMsg | echo " compiling..."
            endif
            silent make
            redraw!
            if v:shell_error != 0
                let s:LastShellReturn_L = v:shell_error
            endif
           if WINDOWS()
                if v:shell_error != 0
                    exe ":bo cope"
                else
                    if s:ShowWarning
                        exe ":bo cw"
                    endif
                    echohl WarningMsg | echo " compilation successful"
                endif
            else
                if empty(v:statusmsg)
                    echohl WarningMsg | echo " compilation successful"
                else
                    exe ":bo cope"
                endif
            endif
        else
            echohl WarningMsg | echo ""Obj_Name"is up to date"
        endif
    else
        let s:Sou_Error = 1
        echohl WarningMsg | echo " please choose the correct source file"
    endif
    exe ":setlocal makeprg=make"
endfunc

func! g:Link()
    call Compile()
    if s:Sou_Error || s:LastShellReturn_C != 0
        return
    endif
    let s:LastShellReturn_L = 0
    let Sou = expand("%:p")
    let Obj = expand("%:p:r").s:Obj_Extension
    if WINDOWS()
        let Exe = expand("%:p:r").s:Exe_Extension
        let Exe_Name = expand("%:p:t:r").s:Exe_Extension
    else
        let Exe = expand("%:p:r")
        let Exe_Name = expand("%:p:t:r")
    endif
    let v:statusmsg = ''
    if filereadable(Obj) && (getftime(Obj) >= getftime(Sou))
        redraw!
        if !executable(Exe) || (executable(Exe) && getftime(Exe) < getftime(Obj))
            if expand("%:e") == "c"
                setlocal makeprg=gcc\ -o\ %<\ %<.o
                echohl WarningMsg | echo " linking..."
            elseif expand("%:e") == "cpp" || expand("%:e") == "cxx"
                setlocal makeprg=g++\ -o\ %<\ %<.o
                echohl WarningMsg | echo " linking..."
            endif
            silent make
            redraw!
            if v:shell_error != 0
                let s:LastShellReturn_L = v:shell_error
            endif
            if WINDOWS()
                if s:LastShellReturn_L != 0
                    exe ":bo cope"
                else
                    if s:ShowWarning
                        exe ":bo cw"
                    endif
                    echohl WarningMsg | echo " linking successful"
                endif
            else
                if empty(v:statusmsg)
                    echohl WarningMsg | echo " linking successful"
                else
                    exe ":bo cope"
                endif
            endif
        else
            echohl WarningMsg | echo ""Exe_Name"is up to date"
        endif
    endif
    setlocal makeprg=make
endfunc

func! g:Run()
    let s:ShowWarning = 0
    call Link()
    let s:ShowWarning = 1
    if s:Sou_Error || s:LastShellReturn_C != 0 || s:LastShellReturn_L != 0
        return
    endif
    let Sou = expand("%:p")
    let Obj = expand("%:p:r").s:Obj_Extension
    if WINDOWS()
        let Exe = expand("%:p:r").s:Exe_Extension
    else
        let Exe = expand("%:p:r")
    endif
    if executable(Exe) && getftime(Exe) >= getftime(Obj) && getftime(Obj) >= getftime(Sou)
        redraw!
        echohl WarningMsg | echo " running..."
        if WINDOWS()
            exe ":!%<.exe"
        else
            if has("gui_running")
                exe ":!gnome-terminal -e ./%<"
            else
                exe ":!./%<"
            endif
        endif
        redraw!
        echohl WarningMsg | echo " running finish"
    endif
endfunc

func! g:CompileLinkRun(...)
    if LINUX()
        let s:Output_path="/tmp"
        "let s:Output_path=expand("%:p:h")
    else
        let  s:Output_path=$TEMP
        " let s:Output_path=expand("%:p:h")
    endif
        "let s:cgi_bin="/var/www/cgi-bin/"
        let s:cgi_bin="/usr/lib/cgi-bin/"
    if LINUX()
        let s:Exe=s:Output_path."/".expand("%:t:r")
    elseif WINDOWS()
        let s:Exe=s:Output_path."\\".expand("%:t:r").".exe"
    endif
    let v:statusmsg = ''
    exe ":ccl"
    exe ":update"
    if (filereadable(s:Exe) && match(a:000,'^asm$') != -1) && LINUX()
        silent!  exec "! rm ".shellescape(s:Exe)
    endif
    if (filereadable(s:Exe) && match(a:000,'^cgi$') !=-1 && WINDOWS())
        silent!  exec "! del ".shellescape(s:Exe)
    endif
if (filereadable(s:Exe.".s") && match(a:000,'^asm$') != -1)
    silent! exec "!rm ".shellescape(s:Exe.".s")
endif
if (filereadable(s:cgi_bin.expand("%:r").".cgi") && match(a:000,'^cgi$') !=-1)
    silent! exec "!rm ".shellescape(s:cgi_bin.expand("%:r").".cgi")
endif
if match(a:000,'^gdb$') !=-1
    let  s:compile_Flags .= ' -gstabs+ '
endif
   if expand("%:e") == "c"
        if !executable('gcc')
            echom "Please install gcc "
            return
        endif
         if WINDOWS()
                if &fileencoding ==? 'utf-8'  ||( &fenc =='' && &enc ==? 'utf-8') 
                    let &makeprg ="gcc -fexec-charset=GBK -finput-charset=UTF-8 "
                else
                    let &makeprg ="gcc -fexec-charset=GBK -finput-charset=GBK "
                endif
         else
                let &makeprg ="gcc "
         endif
    elseif expand("%:e") == "cpp" || expand("%:e") == "cxx"
        if !executable('g++')
            echom "Please install g++ "
            return
        endif
        if WINDOWS()
            if &fileencoding ==? 'utf-8'||( &fenc =='' && &enc ==? 'utf-8')
                let &makeprg ="g++ -fexec-charset=GBK -finput-charset=utf-8"
            else
                let &makeprg ="g++ -fexec-charset=GBK -finput-charset=GBK "
            endif
        else
            let &makeprg ="g++ "
        endif
    endif
  for var in a:000
            if strpart(var,0,1) == "-"
                let &makeprg .=" ".var
            endif
  endfor
    if match(a:000,'^cgi$') != -1
let &makeprg .=s:compile_Flags.shellescape(expand("%:p:t")).CompileLinkFlag("")[0].' -o '.shellescape(s:cgi_bin.expand("%:r").".cgi").CompileLinkFlag("")[1]
    elseif match(a:000,'^asm$') != -1
        let &makeprg .=CompileLinkFlag("")[0].shellescape(expand("%:p:t")).' -o '.shellescape(s:Exe.".s").CompileLinkFlag("")[1]
    else
        let &makeprg .=CompileLinkFlag("")[0].shellescape(expand("%:p:t")).' -o '.shellescape(s:Exe).CompileLinkFlag("")[1]
    endif

    echohl WarningMsg | echo " compiling..." | echom &makeprg
    let v:statusmsg=''
    silent make
    redraw!
    if WINDOWS()
        if v:shell_error != 0
            exe ":bo cope"
        else
            exe ":bo cw"
            echohl WarningMsg | echo " compilation successful"
        endif
    else
       if empty(v:statusmsg)
            echohl WarningMsg | echo " compilation successful"
        else
            exe ":bo cope"
        endif
    endif
    exe ":setlocal makeprg=make"
    if v:shell_error || !empty(v:statusmsg)
        return
    endif
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
    if search("mpi\.h")
      let compilecmd = " !mpicc"
      let s:Exe ="mpiun -np 4 ".s:Exe
    endif
    if search("mpi\.h")
      let compilecmd = "!mpic++ "
      let s:Exe="mpiun -np 4 ".s:Exe
    endif

    if match(a:000,'^cgi$') != -1
        call Test_chmod(s:cgi_bin)
        silent!   exec "!chmod 755 ".shellescape(s:cgi_bin.expand('%:r').".cgi")
        exec "!chromium-browser 127.0.0.1/cgi-bin/".expand('%:r').".cgi"
        redraw!
        return
    endif
    if match(a:000,'^asm$') != -1
        "silent! exec "tabnew /tmp/%<.s"
        exec ":tabnew ".s:Exe.".s"
        return
    endif
    if match(a:000,'^gdb$') != -1
        exec "! gdb " .shellescape(s:Exe)
        return
    endif
"""Run""""""""
    echohl WarningMsg | echo " running..."
    if  filereadable(s:Exe)
        if WINDOWS()
            if has("gui_running")
                exec "!start cmd /c ".shellescape(s:Exe)." & pause"
                " if filereadable(expand('%<').'.in')
                "     exec '!start cmd /c _run %< < %<.in & pause'
                " else
                "     exec '!start cmd /c _run %< & pause'
                " endif
            else
                exec "!".shellescape(s:Exe)
            endif
        else
            if has("gui_running")
                "exe "!".shellescape(s:Exe)
                "
                if executable('gnome-terminal')
                    "gnome-terminal -t "title-name" -x bash -c "sh ./run.sh;exec bash;"
                    " exe ":!gnome-terminal -x bash -c '".shellescape(s:Exe).";exec bash'"
                    " exe ":!gnome-terminal -x bash -c '".shellescape(s:Exe).";echo '请按回车键结束';read'"
                    exe ":!gnome-terminal -t '".expand("%")."' -x bash -c '".shellescape(s:Exe).";echo '请按回车键结束';read'"
                elseif executable('qterminal')  ""有一个缺点就是执行完一闪而过,目前不知如何暂停
                  "  let exe1= ":!qterminal set-title ".shellescape(s:Exe)
                    let exe1= ":!qterminal -e".shellescape(s:Exe)
                    echom exe1
                    exe exe1
                else
                    exe "!time ".shellescape(s:Exe)
                    "return
                    "break
                endif
            else
                exec   ':!time '.shellescape(s:Exe)
            endif
        endif
        "redraw!
        "echohl WarningMsg | echo " running finish"
    else
        echohl WarningMsg | echo "Not find the exe file!"
        return
    endif

    if v:shell_error
            echohl WarningMsg | echo ' Shell Error! '.v:shell_error
    endif
endfunc

