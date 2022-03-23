#!/usr/bin/env bash

git config --global user.name "xenontheinertg"
git config --global user.email "xenontheinertg@qmail.id"
git config --global core.editor "nano"

function gitalias() {
    git config --global alias.s 'status'
    git config --global alias.p 'push'
    git config --global alias.pl 'pull'
    git config --global alias.pf 'push --force'
    git config --global alias.l 'log'
    git config --global alias.f 'fetch'
    git config --global alias.r 'remote'
    git config --global alias.rv 'remote --verbose'
    git config --global alias.ru 'remote update'
    git config --global alias.rrm 'remote remove'
    git config --global alias.rsu 'remote set-url'
    git config --global alias.ra 'remote add'
    git config --global alias.rev 'revert'
    git config --global alias.re 'reset'
    git config --global alias.cp 'cherry-pick'
    git config --global alias.cpc 'cherry-pick --continue'
    git config --global alias.cpa 'cherry-pick --abort'
    git config --global alias.rh 'reset --hard'
    git config --global alias.rs 'reset --soft'
    git config --global alias.rb 'rebase'
    git config --global alias.rbi 'rebase --interactive'
    git config --global alias.rbc 'rebase --continue'
    git config --global alias.rba 'rebase --abort'
    git config --global alias.rbs 'rebase --skip'
    git config --global alias.d 'diff'
    git config --global alias.dc 'diff --cached'
    git config --global alias.b 'bisect'
    git config --global alias.c 'commit'
    git config --global alias.cs 'commit --signoff'
    git config --global alias.ca 'commit --amend'
    git config --global alias.cn 'commit --no-edit'
    git config --global alias.casm 'commit -asm'
    git config --global alias.gerrit 'push gerrit HEAD:refs/for/pie'
    git config --global alias.add-change-id "!EDITOR='sed -i -re s/^pick/e/' sh -c 'git rebase -i \$1 && while test -f .git/rebase-merge/interactive; do git commit --amend --no-edit && git rebase --continue; done' -"
}

gitalias
