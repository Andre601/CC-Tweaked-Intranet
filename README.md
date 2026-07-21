# CC: Tweaked Intranet

This project aims to create the base of Internet in Minecraft by using CC: Tweaked.

This repository contains various files that are utilized to achieve this goal.

## How it Works

Using the Rednet system, a Computer running the server program (referred to as "server" throughout this document) will register itself as a host on the `intranet` protocol using its label as the "domain".  
Using a second Computer, a Player can use the [`IE.lua`](IE.lua) programm (or any other Lua programm that can work with this system) to connect to the server using the domain. This does require both computers to have a wireless modem and for the Server to be loaded.  
When connecting, the server will send the computer the content of the page the Player connects to (By default `home.lua` if no subpage was defined) or an error, should there not be any page to serve.

### Pages

Pages are saved as `.lua` files in a `pages` directory on the Server. Creating a page called `home.lua` will result in it being used as the root page of the site (i.e. connecting to `example.com` will be the same as loading `example.com/home`).  
The pages use MTML (MineText Markup Language), a HTML-inspired format that is used to style the page and add features like textboxes and buttons. The MTML format is explained in detail on the [Julsen MC Server Wiki](https://julsenmcserver.miraheze.org/wiki/MTML).

### Addons

The Server supports the creation of "addons". Addons are additional Lua files stored in the `addons` directory, that are used whenever the player enters text in a textbox or presses a button.

Creating an addon is relatively easy. Simply create a lua file in the `addons` folder with the following base-structure:  
```lua
local addon = {}

function addon.input()
    return {}
end

function addon.receive_input(sender_id, input_id, input_value)
    return ""
end

return addon
```

`addon.input()` is used by the Server to determine the IDs to associate with this addon, so that it can call the `addon.receive_input` function for it.  
The returned value needs to be a table where the keys match the IDs you want to support. The values don't matter and are discarded by the Server during the loading (Example: `{search = true}`).

`addon.receive_input(sender_id, input_id, input_value)` is called by the Server whenever the Player presses a button, or presses Enter in a textbox whos ID matches one provided in `addon.input`.  
The `sender_id` will be the ID of the computer from where the request came, `input_id` will be the ID of the input and `input_value` the actual value sent. For a button press will the value always be `true`.

The returned value needs to be a String containing optional MTML formatted text to display.
