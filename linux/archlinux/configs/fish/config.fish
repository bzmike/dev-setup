if status is-interactive
    contains $HOME/.local/bin $PATH; or set -gx PATH $HOME/.local/bin $PATH
    contains $HOME/bin $PATH; or set -gx PATH $HOME/bin $PATH

    set -e POSH_SHELL

    if type -q oh-my-posh
        oh-my-posh init fish --config $HOME/.poshthemes/tokyo.omp.json | source
    end
end