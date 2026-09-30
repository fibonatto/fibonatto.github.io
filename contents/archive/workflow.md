---
title: "My Worflow (2026)"
date: "2026-09-23"
description: "This is my workflow draft apresentation"
---

My workflow is completely based on the CLI. There are some apps that I use in graphical mode, but it's almost nothing. I just like the minimalist philosophy, as you can see on this blog.

My first configuration is the hardware. There is no second monitor, no pro-gamer-meta-trans-futuristic mouse, and no huge desk with a bunch of stuff scattered around my keyboard. It's just a MacBook Air, nothing else. Just a MacBook.

I also used to have an Arch Linux + i3wm setup. It's cool, but I don't have enough time or energy to configure everything over and over again. So, a MacBook is good enough for me.

Inside my Mac, all I need is a terminal and a web browser. That's it. What more could I possibly need to work??? It should be a distraction-free, keyboard-centered environment. That makes it easier to focus and do my best work.

Yeah, it could be worse if I tried to look cool lol.

I tested a lot of terminal emulators, from Alacritty to Ghostty. Everyone has their own pros and cons. The terminal I liked most is Kitty. It has a pretty simple config, and you can change almost everything, even the icon. Please, the default icon is the worst.

After changing the icon, I changed a few other things, like keybinds and colors. My Kitty config has less than 90 LOC, with comments explaining what each part of the config does. I basically enabled splits by default, changed the `Option` key to act like `Alt`, and enabled notifications.

Kitty is powerful, but it is not perfect, so we need tmux. It has a lot of configuration, but the most important things, I think, are clipboard synchronization, notifications, resurrect, and continuum. I feel like my terminal is much more powerful and better integrated with my system.

Another important layer of this system is the shell. I tried Bash, it's cool, and Fish, it's weird. I stayed with Zsh.

At first, my config had a lot of plugins. Some of them were really heavy, so I found Antidote. Goodbye, Oh My Zsh. It was eternal while it lasted.

I remember that during my last week with OMZ, I was waiting 2, even 3 seconds for my terminal to load all the configuration. Now, it's around 75 ms with basically the same functionality. I lost nothing.

Like an onion, there is another layer, how I actually interact with the filesystem. I replaced some of the usual unix tools with newer alternatives that fit better into my workflow. 

Not replaceing them completely, tbh. I still type the commands I'm used to. I just made aliases for them.

For example, ls is now eza. I have a few different aliases depending on what I want to see, but the important one is simply that I can type ls and get eza instead. I don't need to remember a new command just to get a better version of something I already use.

The same idea applies to cd. I use zoxide, so z handles directory navigation for me. After using it for a while, it becomes pretty hard to go back to manually typing long paths.




list of tools:

- Kitty (https://github.com/kovidgoyal/kitty) 
- tmux (https://github.com/tmux/tmux) 
- zsh 
- antidote (https://github.com/mattmc3/antidote)
- fd (https://github.com/sharkdp/fd)
- rg (https://github.com/burntsushi/ripgrep)
- eza (https://github.com/eza-community/eza)
- zoxide (https://github.com/ajeetdsouza/zoxide)
- bat (https://github.com/sharkdp/bat)
- dicordo (https://github.com/ayn2op/discordo)
- w3m (https://github.com/acg/w3m)
- tell-ai (https://github.com/naoeosavio/Tell-ai) 
- nvim 
- basal 
- man 
- scripts (https://github.com/fibonatto/Scripts):
    - dev 
    - feat 
    - tn 
    - tmux-kill 
    - ddg 
    - killp 
    - extract


