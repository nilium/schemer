Schemer
==============================================================================

Schemer is a simple color scheme editor for TextMate themes. It's intended for use by Sublime Text and possibly TextMate 2 users who don't really like editing property lists by hand. It's not fun. Really.

At the moment, it's a work in progress and some features may not work or may be broken. It's not advised that you just throw builds of it at your favorite un-backed-up color scheme because I can't guarantee its safety.


Contributing
------------------------------------------------------------------------------

Want to contribute? That's easy. Fork this repo, make some changes, and submit a pull request. Be sure to reference any relevant issues if you can, but not all contributions need issues or even solve issues. The only requirement is that you agree that your contributions are licensed under the same license as the rest of the project.

General rules for style can be picked up from the source code, but a quick rundown for anyone making large changes / additions:

- Two-space indentations.
- `switch` and `case` go on the same column
- Opening brace for functions on a new line, everything else on the same line. Blocks don't count as functions.
- Prefer camelCase. Though the project started with snake_case for non-ObjC identifiers, so there's some cleanup left to do and you'll see those littered around, don't do that.
- And the weirdest one you'll have trouble with: the qualifier and attributes, return type, and function signature for C functions all go on separate lines. For example:

    static
    void *
    returnNull()
    {
        return NULL;
    }

There might be other things, but that covers the important stuff. Try to avoid Xcode's auto-formatting because it will drive you insane when trying to maintain the code style.


License
------------------------------------------------------------------------------

Schemer is licensed under a simple two-clause BSD license:

> Copyright (c) 2014, Noel Cower.
> All rights reserved.
> 
> Redistribution and use in source and binary forms, with or without
> modification, are permitted provided that the following conditions are
> met:
> 
> 1. Redistributions of source code must retain the above copyright
>     notice, this list of conditions and the following disclaimer.
> 
> 2. Redistributions in binary form must reproduce the above copyright
>     notice, this list of conditions and the following disclaimer in the
>     documentation and/or other materials provided with the distribution.
> 
> THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
> IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
> TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
> PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
> HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
> SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
> LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
> DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
> THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
> (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
> OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
