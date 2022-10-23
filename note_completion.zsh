#compdef note
zmodload zsh/mapfile

_note() {
    local curcontext="$curcontext" state line
    typeset -A opt_args
 
    _arguments \
        '1: :->action'\
        '*: :->target'

    notes=( "${(f)mapfile[/tmp/note/completion]}" )
 
    case $state in
    action)
        _arguments '1:Actions:(list drop read)'
        _arguments "1:Notes:($notes)"
    ;;
    *)
        case $words[2] in
        list)
            compadd "$@" paris lyon marseille
        ;;
        drop)
            compadd "$@" $notes
        ;;
        read)
            _files
        esac
    esac
}

_note "$@"
